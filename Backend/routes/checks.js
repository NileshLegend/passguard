const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const router = express.Router();

// Middleware to verify token
const auth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Save a check
router.post('/', auth, async (req, res) => {
  const { score, crack_time } = req.body;
  const result = await pool.query(
    'INSERT INTO password_checks (user_id, score, crack_time) VALUES ($1, $2, $3) RETURNING *',
    [req.user.id, score, crack_time]
  );
  res.json(result.rows[0]);
});

// Get history
router.get('/', auth, async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM password_checks WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10',
    [req.user.id]
  );
  res.json(result.rows);
});

module.exports = router;