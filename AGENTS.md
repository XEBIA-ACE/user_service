# AGENTS.md — User and Product Management Service

## Overview

This document is the authoritative scaffold specification for the **User and Product Management Service**. Every AI agent working on this repository must read and follow this guide before writing a single line of code.

---

## 1. Stack

| Technology | Role |
|---|---|
| **Node.js 20 LTS** | Runtime environment |
| **Express 4.x** | HTTP server and routing framework |
| **Elasticsearch 8.x** | Primary data store for users and product indexing/search |
| **`@elastic/elasticsearch`** | Official Elasticsearch Node.js client |
| **Redis 7.x** | Result caching layer for product search queries |
| **`ioredis`** | Redis client with promise support |
| **`bcryptjs`** | Password hashing for user credentials |
| **`jsonwebtoken`** | JWT generation and verification for authentication |
| **`joi`** | Request payload validation schemas |
| **`helmet`** | HTTP security headers middleware |
| **`morgan`** | HTTP request logging |
| **`winston`** | Structured application logging |
| **`dotenv`** | Environment variable loading |
| **`uuid`** | Deterministic document ID generation |
| **Jest** | Unit and integration test runner |
| **`supertest`** | HTTP integration testing against Express app |
| **`@jest/coverage`** | Coverage reporting (Istanbul under the hood) |
| **ESLint + Prettier** | Code style enforcement |
| **Docker / docker-compose** | Containerised local development and CI |
| **GitHub Actions** | CI pipeline |

---

## 2. Project Structure

```
user-product-service/
├── src/
│   ├── app.js                  # Express app factory (no listen call)
│   ├── server.js               # Entry point — binds port, starts server
│   ├── config/
│   │   ├── index.js            # Centralised config object built from env vars
│   │   ├── elasticsearch.js    # Elasticsearch client singleton
│   │   └── redis.js            # ioredis client singleton
│   ├── constants/
│   │   ├── indices.js          # Elasticsearch index name constants
│   │   └── errors.js           # Shared error code/message constants
│   ├── middleware/
│   │   ├── authenticate.js     # JWT verification middleware
│   │   ├── validate.js         # Joi schema validation middleware factory
│   │   ├── errorHandler.js     # Global Express error handler
│   │   └── rateLimiter.js      # express-rate-limit configuration
│   ├── modules/
│   │   ├── users/
│   │   │   ├── user.routes.js       # Express Router for /users
│   │   │   ├── user.controller.js   # Route handlers (thin, delegates to service)
│   │   │   ├── user.service.js      # Business logic for user operations
│   │   │   ├── user.repository.js   # All Elasticsearch calls for users index
│   │   │   ├── user.schema.js       # Joi validation schemas for user payloads
│   │   │   └── user.index.js        # ES index mapping definition for users
│   │   └── products/
│   │       ├── product.routes.js    # Express Router for /products
│   │       ├── product.controller.js
│   │       ├── product.service.js   # Business logic + cache coordination
│   │       ├── product.repository.js# All Elasticsearch calls for products index
│   │       ├── product.cache.js     # Redis get/set/invalidate helpers
│   │       ├── product.schema.js    # Joi validation schemas for product payloads
│   │       └── product.index.js     # ES index mapping definition for products
│   └── utils/
│       ├── logger.js           # Winston logger instance
│       ├── asyncHandler.js     # Wraps async route handlers, forwards errors
│       ├── hashPassword.js     # bcryptjs helpers
│       └── tokenHelper.js      # JWT sign/verify helpers
├── tests/
│   ├── unit/
│   │   ├── users/
│   │   │   ├── user.service.test.js
│   │   │   └── user.repository.test.js
│   │   └── products/
│   │       ├── product.service.test.js
│   │       ├── product.repository.test.js
│   │       └── product.cache.test.js
│   ├── integration/
│   │   ├── users.routes.test.js
│   │   └── products.routes.test.js
│   └── helpers/
│       ├── esClientMock.js     # Reusable Elasticsearch client mock
│       └── redisClientMock.js  # Reusable Redis client mock
├── scripts/
│   ├── createIndices.js        # One-time script to create ES indices with mappings
│   └── seedData.js             # Optional dev seed script
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI pipeline
├── .eslintrc.js                # ESLint rules
├── .prettierrc                 # Prettier formatting config
├── .env.example                # Template of required environment variables
├── .gitignore
├── docker-compose.yml          # Local dev stack (app + ES + Redis)
├── Dockerfile                  # Production image
├── jest.config.js              # Jest configuration
├── package.json
├── tasks.md                    # Agent-generated task tracker (see §3)
└── AGENTS.md                   # This file
```

---

## 3. Required Workflow

The agent **must** execute steps in this exact order. Do not skip or reorder steps.

### Step 1 — Read All Specifications
- Read `AGENTS.md` fully before touching any file.
- Read any story-level spec files present in the repository.
- Identify every functional requirement before writing code.

### Step 2 — Create `tasks.md`
- Create `tasks.md` at the repository root.
- Break all work into discrete, checkable tasks using this format:

```markdown
# Tasks

## Setup
- [ ] Initialise package.json with correct metadata
- [ ] Install all dependencies listed in §1

## Users Module
- [ ] Scaffold user.routes.js
- [ ] Implement registration endpoint
...

## Validation
- [ ] All unit tests pass
- [ ] Coverage ≥ 90%
- [ ] ESLint reports zero errors
- [ ] docker-compose up runs without errors
```

- Check off each task (`[x]`) as it is completed.
- Never mark a task complete without verifying it works.

### Step 3 — Environment and Infrastructure Setup
1. Run `npm init -y` and update `package.json` with correct name, version, and scripts.
2. Install production dependencies:
   ```bash
   npm install express @elastic/elasticsearch ioredis bcryptjs jsonwebtoken \
     joi helmet morgan winston dotenv uuid express-rate-limit
   ```
3. Install development dependencies:
   ```bash
   npm install -D jest supertest @types/jest eslint prettier \
     eslint-config-prettier eslint-plugin-jest
   ```
4. Copy `.env.example` and populate `.env` for local development.
5. Run `docker-compose up -d` to start Elasticsearch and Redis.
6. Run `node scripts/createIndices.js` to create indices with mappings.

### Step 4 — Implement in Module Order
Implement in this sequence to respect dependency layers:

1. `src/config/` — clients and config object
2. `src/utils/` — shared utilities
3. `src/middleware/` — reusable middleware
4. `src/modules/users/` — full user module (repository → service → controller → routes)
5. `src/modules/products/` — full product module (repository → cache → service → controller → routes)
6. `src/app.js` — wire routes into Express app
7. `src/server.js` — start server

### Step 5 — Write Tests Alongside Implementation
- Write unit tests for every service and repository file **before** moving to the next module.
- Write integration tests for every route group after the module is complete.
- Run `npm test` after each module. All tests must pass before proceeding.

### Step 6 — Validate
Run all of the following; every check must pass:

```bash
npm run lint          # Zero ESLint errors
npm test              # All tests pass, coverage ≥ 90%
npm run build         # No syntax/compile errors
docker build -t user-product-service .   # Image builds cleanly
docker-compose up     # Full stack starts, /health returns 200
```

---

## 4. Coding Conventions

### General
- Use **ES Modules** (`"type": "module"` in `package.json`) with `.js` extensions on all imports.
- Use `async/await` exclusively — no raw Promise chains or callbacks.
- Wrap all async route handlers with `asyncHandler` utility to forward errors to the global error handler.
- Never `throw` plain strings — always throw `Error` instances with a `statusCode` property.

### Naming
| Artefact | Convention | Example |
|---|---|---|
| Files | `kebab-case` or `camelCase.type.js` | `user.service.js` |
| Variables / functions | `camelCase` | `getUserById` |
| Classes | `PascalCase` | `UserRepository` |
| Constants | `SCREAMING_SNAKE_CASE` | `USERS_INDEX` |
| ES index names | `snake_case` | `users`, `products` |
| Environment variables | `SCREAMING_SNAKE_CASE` | `JWT_SECRET` |
| Route paths | `kebab-case`, plural nouns | `/api/v1/users`, `/api/v1/products` |

### Architecture Rules
- **Controller** — validates input (via middleware), calls service, sends HTTP response. No business logic.
- **Service** — orchestrates business logic, calls repository and cache. No direct ES/Redis client calls.
- **Repository** — only Elasticsearch calls. Returns plain objects, never Express response objects.
- **Cache** — only Redis calls. Encapsulated in `product.cache.js`.
- No module may import from a sibling module (e.g., `users` must not import from `products`).
- All Elasticsearch and Redis clients are imported from `src/config/` — never instantiated inline.

### Express Patterns
```js
// Route registration in app.js
import usersRouter from './modules/users/user.routes.js';
import productsRouter from './modules/products/product.routes.js';

app.use('/api/v1/users', usersRouter);
app.use('/api/v1/products', productsRouter);
```

```js
// asyncHandler utility
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
```

### Elasticsearch Conventions
- Define explicit index mappings in `*.index.js` files — never rely on dynamic mapping.
- Use `uuid` for document `_id` generation.
- Always specify `refresh: 'wait_for'` on index/update/delete operations in tests.
- Search queries must use `bool` queries with `must`, `should`, and `filter` clauses as appropriate.

### Caching Conventions
- Cache key format: `product:search:<base64(queryString)>`
- Default TTL: `300` seconds (configurable via `CACHE_TTL_SECONDS` env var).
- Cache miss → fetch from ES → store in Redis → return result.
- Cache hit → return cached result without hitting ES.
- Invalidate relevant cache keys on product index/update/delete.

### Environment Variables (`.env.example`)
```
NODE_ENV=development
PORT=3000

# Elasticsearch
ES_NODE=http://localhost:9200
ES_USERNAME=elastic
ES_PASSWORD=changeme

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=replace_with_strong_secret
JWT_EXPIRES_IN=1h

# Cache
CACHE_TTL_SECONDS=300
```

---

## 5. Testing

### Framework and Setup
- **Jest** is the sole test runner.
- **supertest** is used for integration tests against the Express app instance (not the live server).
- All external dependencies (Elasticsearch client, Redis client) are **mocked** in unit tests using Jest manual mocks or `jest.mock()`.

### `jest.config.js`
```js
export default {
  testEnvironment: 'node',
  transform: {},                          // ESM — no Babel
  extensionsToTreatAsEsm: ['.js'],
  testMatch: [
    '**/tests/unit/**/*.test.js',
    '**/tests/integration/**/*.test.js',
  ],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',                     // Entry point excluded
    '!src/config/*.js',                   // Config singletons excluded
  ],
  coverageThreshold: {
    global: {
      lines: 90,
      functions: 90,
      branches: 90,
      statements: 90,
    },
  },
  coverageReporters: ['text', 'lcov'],
};
```

### `package.json` Scripts
```json
{
  "scripts": {
    "start": "node src/server.js",
    "dev": "node --watch src/server.js",
    "test": "node --experimental-vm-modules node_modules/.bin/jest",
    "test:unit": "jest --testPathPattern=tests/unit",
    "test:integration": "jest --testPathPattern=tests/integration",
    "test:coverage": "jest --coverage",
    "lint": "eslint src tests --ext .js",
    "lint:fix": "eslint src tests --ext .js --fix",
    "format": "prettier --write src tests",
    "create-indices": "node scripts/createIndices.js"
  }
}
```

### Unit Test Requirements
- Every `*.service.js` file must have a corresponding `*.service.test.js`.
- Every `*.repository.js` file must have a corresponding `*.repository.test.js`.
- `product.cache.js` must have `product.cache.test.js`.
- Mock the ES client using `tests/helpers/esClientMock.js` — do not call a real cluster.
- Mock the Redis client using `tests/helpers/redisClientMock.js`.
- Test all happy paths, validation failures, ES error propagation, and cache hit/miss scenarios.

### Integration Test Requirements
- Use `supertest` with the Express app from `src/app.js`.
- Mock ES and Redis clients at the module level with `jest.mock()`.
- Test every route: correct status codes, response body shapes, and error responses.
- Required route coverage:

| Route | Tests Required |
|---|---|
| `POST /api/v1/users/register` | success, duplicate email, duplicate mobile, invalid payload |
| `POST /api/v1/users/login` | success, wrong password, user not found |
| `GET /api/v1/users/profile` | authenticated success, missing token, expired token |
| `PUT /api/v1/users/profile` | success, invalid payload, unauthenticated |
| `POST /api/v1/products` | success, invalid payload, unauthenticated |
| `GET /api/v1/products/search` | cache hit, cache miss, empty results, missing query |
| `PUT /api/v1/products/:id` | success, not found, unauthenticated |
| `DELETE /api/v1/products/:id` | success, not found, unauthenticated |

---

## 6. Docker & CI

### `Dockerfile`
```dockerfile
# ---- Build stage ----
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ---- Production stage ----
FROM node:20-alpine AS production
ENV NODE_ENV=production
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./
EXPOSE 3000
USER node
CMD ["node", "src/server.js"]
```

### `docker-compose.yml`
```yaml
version: '3.9'