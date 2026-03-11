const express = require('express');
const { Pool } = require('pg');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// PostgreSQL connection
const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
  database: process.env.PGDATABASE || 'webapp',
  user: process.env.PGUSER || 'webadmin',
  password: process.env.PGPASSWORD || 'webadmin123'
});

// Middleware
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// List all products
app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products ORDER BY product_id');
    res.render('index', { products: result.rows });
  } catch (err) {
    console.error('Error fetching products:', err);
    res.render('index', { products: [], error: 'Failed to load products' });
  }
});

// Show create form
app.get('/create', (req, res) => {
  res.render('create');
});

// Create product
app.post('/products', async (req, res) => {
  const { product_description, product_price } = req.body;
  try {
    await pool.query(
      'INSERT INTO products (product_description, product_price) VALUES ($1, $2)',
      [product_description, product_price]
    );
    res.redirect('/');
  } catch (err) {
    console.error('Error creating product:', err);
    res.render('create', { error: 'Failed to create product', product_description, product_price });
  }
});

// Show edit form
app.get('/edit/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products WHERE product_id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.redirect('/');
    }
    res.render('edit', { product: result.rows[0] });
  } catch (err) {
    console.error('Error fetching product:', err);
    res.redirect('/');
  }
});

// Update product
app.post('/products/:id', async (req, res) => {
  const { product_description, product_price } = req.body;
  try {
    await pool.query(
      'UPDATE products SET product_description = $1, product_price = $2 WHERE product_id = $3',
      [product_description, product_price, req.params.id]
    );
    res.redirect('/');
  } catch (err) {
    console.error('Error updating product:', err);
    res.render('edit', { 
      error: 'Failed to update product', 
      product: { product_id: req.params.id, product_description, product_price } 
    });
  }
});

// Delete product
app.post('/products/:id/delete', async (req, res) => {
  try {
    await pool.query('DELETE FROM products WHERE product_id = $1', [req.params.id]);
  } catch (err) {
    console.error('Error deleting product:', err);
  }
  res.redirect('/');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Products CRUD app running at http://localhost:${port}`);
});
