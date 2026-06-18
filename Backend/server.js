const express = require('express');
const cors = require('cors');
require('dotenv').config();
const pool = require('./db');

const authRoutes = require('./routes/auth');
const checkRoutes = require('./routes/checks');

const app = express();
app.use(cors({
  origin: 'https://passguard-delta.vercel.app',
  credentials: true
}));
app.use(express.json());

// Create tables on startup
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

app.use('/auth', authRoutes);
app.use('/checks', checkRoutes);

app.get('/', (req, res) => res.json({ message: 'PassGuard API running' }));

app.listen(process.env.PORT, () => {
  console.log(`Server running on port ${process.env.PORT}`);
});