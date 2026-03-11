CREATE TABLE products (product_id SERIAL PRIMARY KEY, product_description TEXT NOT NULL, product_price NUMERIC(10,2) NOT NULL);
GRANT ALL PRIVILEGES ON TABLE products TO webadmin;
GRANT USAGE, SELECT ON SEQUENCE products_product_id_seq TO webadmin;
