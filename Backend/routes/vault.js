const express = require('express');
const CryptoJS = require('crypto-js');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const router = express.Router();

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;

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

// Encrypt helper
const encrypt = (text) => CryptoJS.AES.encrypt(text, ENCRYPTION_KEY).toString();

// Decrypt helper
const decrypt = (text) => {
  const bytes = CryptoJS.AES.decrypt(text, ENCRYPTION_KEY);
  return bytes.toString(CryptoJS.enc.Utf8);
};

// Save a password
router.post('/', auth, async (req, res) => {
  const { site_name, username, password } = req.body;
  if (!site_name || !username || !password) {
    return res.status(400).json({ error: 'All fields required' });
  }
  const encrypted = encrypt(password);
  const result = await pool.query(
    'INSERT INTO vault (user_id, site_name, username, password_encrypted) VALUES ($1, $2, $3, $4) RETURNING id, site_name, username, created_at',
    [req.user.id, site_name, username, encrypted]
  );
  res.json(result.rows[0]);
});

// Get all saved passwords
router.get('/', auth, async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM vault WHERE user_id = $1 ORDER BY created_at DESC',
    [req.user.id]
  );
  const decrypted = result.rows.map(row => ({
    ...row,
    password: decrypt(row.password_encrypted)
  }));
  res.json(decrypted);
});

// Delete a password
router.delete('/:id', auth, async (req, res) => {
  await pool.query(
    'DELETE FROM vault WHERE id = $1 AND user_id = $2',
    [req.params.id, req.user.id]
  );
  res.json({ message: 'Deleted' });
});

module.exports = router;