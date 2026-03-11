#!/bin/bash
set -e

# Configure PostgreSQL for remote connections
PG_CONF=$(find /etc/postgresql -name postgresql.conf | head -1)
PG_HBA=$(find /etc/postgresql -name pg_hba.conf | head -1)

# Allow listening on all interfaces (only if not already set)
if ! grep -q "^listen_addresses = '\*'" "$PG_CONF"; then
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
    sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
fi

# Allow remote connections with password auth (only if not already added)
if ! grep -q "host.*all.*all.*0.0.0.0/0.*md5" "$PG_HBA"; then
    echo "host    all    all    0.0.0.0/0    md5" >> "$PG_HBA"
fi

# Restart PostgreSQL to apply config changes
systemctl restart postgresql

# Wait for PostgreSQL cluster to be fully ready (with timeout)
echo "Waiting for PostgreSQL to be ready..."
TIMEOUT=60
COUNT=0
until pg_isready -q; do
    sleep 1
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $TIMEOUT ]; then
        echo "ERROR: PostgreSQL did not start within ${TIMEOUT} seconds"
        exit 1
    fi
done
echo "PostgreSQL is ready after ${COUNT} seconds"

# Open firewall for PostgreSQL
ufw allow 5432/tcp 2>/dev/null || true

# Create user and database (idempotent - ignore errors if already exist)
sudo -u postgres psql -c "CREATE USER webadmin WITH PASSWORD 'webadmin123';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE webapp OWNER webadmin;" 2>/dev/null || true

# Create table and grants (idempotent)
sudo -u postgres psql -d webapp -c "CREATE TABLE IF NOT EXISTS products (product_id SERIAL PRIMARY KEY, product_description TEXT NOT NULL, product_price NUMERIC(10,2) NOT NULL);"
sudo -u postgres psql -d webapp -c "GRANT ALL PRIVILEGES ON TABLE products TO webadmin;"
sudo -u postgres psql -d webapp -c "GRANT USAGE, SELECT ON SEQUENCE products_product_id_seq TO webadmin;"

# Set ownership and install npm dependencies
chown -R ubuntu:ubuntu /opt/webapp
cd /opt/webapp
sudo -u ubuntu npm install

# Create systemd service for the webapp (simpler than PM2)
cat > /etc/systemd/system/products-crud.service << 'EOF'
[Unit]
Description=Products CRUD webapp
After=network.target postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/webapp
ExecStart=/usr/bin/node /opt/webapp/app.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the webapp service
systemctl daemon-reload
systemctl enable products-crud.service
systemctl start products-crud.service

# Disable this setup service so it only runs once
systemctl disable webapp-setup.service
