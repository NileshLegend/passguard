# 🔥 PassGuard

A full-stack password security platform — check password strength instantly and store your credentials in an encrypted personal vault, accessible from both web and mobile.

**Live App:** [passguard-delta.vercel.app](https://passguard-delta.vercel.app)
**API:** [passguard-production-2c0c.up.railway.app](https://passguard-production-2c0c.up.railway.app)

---

## ✨ Features

- 🔍 **Password Strength Checker** — instant visual feedback (length, casing, numbers, symbols) with improvement tips
- 🔐 **Encrypted Vault** — save site credentials (site name, username, password), reveal or delete them anytime
- 👤 **Authentication** — secure register/login with hashed passwords and JWT-based sessions
- 📱 **Cross-Platform** — same backend powers both the React web app and the Flutter Android app, so your vault stays in sync everywhere
- ☁️ **Live Deployment** — frontend on Vercel, backend + database on Railway, with a CI pipeline on every push

---

## 🏗️ Architecture

```
React (Web)  ─┐
Flutter (App)─┼──▶  Node.js + Express API  ──▶  PostgreSQL
              ┘
```

One shared backend, one shared database — both clients are just interfaces on top of the same data and logic.

---

## 🛠️ Tech Stack

| Layer | Tech |
|---|---|
| Frontend | React (Vite), React Router, Axios |
| Mobile | Flutter, Dart, `http`, `shared_preferences` |
| Backend | Node.js, Express |
| Database | PostgreSQL (raw SQL via `pg`, no ORM) |
| Auth | JWT + bcrypt |
| Vault Encryption | AES (`crypto-js`) |
| Hosting | Vercel (frontend) · Railway (backend + DB) |
| CI/CD | GitHub Actions |

---

## 📁 Project Structure

```
PassGuard/
├── Backend/
│   ├── routes/        # auth.js, checks.js, vault.js
│   ├── db.js           # PostgreSQL connection
│   └── server.js        # entry point, CORS, table setup
├── Frontend/
│   └── src/pages/      # Login, Register, Dashboard
├── Mobile/
│   └── passguard_mobile/lib/main.dart
└── .github/workflows/   # CI pipeline
```

---

## 🚀 Getting Started Locally

### Prerequisites
- Node.js
- PostgreSQL
- Flutter SDK (for mobile)

### Backend
```bash
cd Backend
npm install
# create a .env file — see Environment Variables below
npm start
```

### Frontend
```bash
cd Frontend
npm install
npm run dev
```

### Mobile
```bash
cd Mobile/passguard_mobile
flutter pub get
flutter run
```

---

## 🔑 Environment Variables

Create a `.env` file inside `Backend/`:

```
PORT=5000
DB_HOST=
DB_NAME=
DB_USER=
DB_PASSWORD=
DB_PORT=5432
JWT_SECRET=
ENCRYPTION_KEY=
```

---

## 📡 API Reference

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| POST | `/auth/register` | No | Create a new account |
| POST | `/auth/login` | No | Log in, returns a JWT |
| GET | `/vault` | Yes | Get all saved vault entries |
| POST | `/vault` | Yes | Save a new vault entry |
| DELETE | `/vault/:id` | Yes | Delete a vault entry |

Protected routes require an `Authorization: Bearer <token>` header.

---

## 🔒 Security Notes

- Login passwords are hashed with **bcrypt** — never stored in plain text
- Vault passwords are **AES-encrypted** at rest, decrypted only server-side for an authenticated user
- All SQL queries are parameterized to prevent SQL injection
- Known limitations (no JWT expiry, single shared encryption key, no rate limiting) are documented in the full project documentation

---

## 📄 Full Documentation

For complete architecture details, database schema, security model, and an end-user guide, see [`PassGuard_Documentation.txt`](./PassGuard_Documentation.txt).

---

## 👤 Author

**Nilesh Khawas**
