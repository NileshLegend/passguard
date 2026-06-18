const express = require('express');
const cors = require('cors');
require('dotenv').config();
const pool = require('./db');

const authRoutes = require('./routes/auth');
const checkRoutes = require('./routes/checks');

const app = express();

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', 'https://passguard-delta.vercel.app');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.json());
app.use('/auth', authRoutes);
app.use('/checks', checkRoutes);

app.get('/', (req, res) => res.json({ message: 'PassGuard API running' }));

pool.query(`
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
  );
  CREATE TABLE IF NOT EXISTS password_checks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    score INTEGER,
    crack_time VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
  );
`).then(() => console.log('Tables ready'));

app.listen(process.env.PORT || 5000, () => {
  console.log(`Server running on port ${process.env.PORT || 5000}`);
});