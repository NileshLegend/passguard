const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  try {
    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email',
      [email, hash]
    );
    const token = jwt.sign({ id: result.rows[0].id }, process.env.JWT_SECRET);
    res.json({ token, user: result.rows[0] });
  } catch (err) {
    res.status(400).json({ error: 'Email already exists' });
  }
});

// Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (!result.rows.length) return res.status(400).json({ error: 'User not found' });
    const valid = await bcrypt.compare(password, result.rows[0].password_hash);
    if (!valid) return res.status(400).json({ error: 'Wrong password' });
    const token = jwt.sign({ id: result.rows[0].id }, process.env.JWT_SECRET);
    res.json({ token, user: { id: result.rows[0].id, email: result.rows[0].email } });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;