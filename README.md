# User Service

A production-ready RESTful API service for user management built with **Ruby on Rails 7** and **Redis**.

## Features

- **JWT authentication** with access + refresh token rotation
- **Role-based access control** — `user`, `moderator`, `admin`
- **Account security** — exponential-backoff login locking, password strength enforcement
- **Redis caching** — connection-pooled Redis client with a CacheService abstraction
- **Token denylist** — revoked JWTs tracked in Redis for immediate invalidation
- **Structured logging** — JSON logs via Lograge, with request ID and user ID tagging
- **Health & metrics** endpoints for Kubernetes probes and monitoring
- **OpenAPI/Swagger** documentation generated from RSpec integration tests
- **Paginated** list endpoints via Pagy
- **Soft-delete with PII anonymisation** on user removal
- Multi-environment configuration (development / test / staging / production)

---

## Tech Stack

| Layer         | Technology                          |
|---------------|-------------------------------------|
| Framework     | Ruby on Rails 7.1 (API mode)        |
| Language      | Ruby 3.2                            |
| Database      | PostgreSQL 16                       |
| Cache / Queue | Redis 7                             |
| Auth          | JWT (HS256) + bcrypt passwords      |
| Background    | Sidekiq                             |
| Docs          | rswag (OpenAPI 3.0)                 |
| Tests         | RSpec + FactoryBot + Shoulda        |
| Server        | Puma                                |
| Container     | Docker (multi-stage build)          |

---

## Project Structure

```
user_service/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb    # Auth helpers, error handling, pagination
│   │   └── api/v1/
│   │       ├── health_controller.rb     # /health  /readiness  /metrics
│   │       ├── auth_controller.rb       # login, refresh, logout
│   │       └── users_controller.rb      # CRUD + activate/deactivate/change_password
│   ├── models/
│   │   ├── user.rb                      # Core entity — validations, enums, callbacks
│   │   └── user_session.rb             # JWT session tracking
│   ├── serializers/
│   │   └── user_serializer.rb          # JSONAPI:Serializer — safe field whitelist
│   └── services/
│       ├── base_service.rb             # Abstract base with success/failure helpers
│       ├── service_result.rb           # Immutable result value object
│       ├── jwt_service.rb              # Encode / decode JWT tokens
│       ├── cache_service.rb            # Redis caching abstraction
│       └── users/
│           ├── auth_service.rb         # Login + token issuance
│           ├── create_service.rb
│           ├── update_service.rb
│           ├── delete_service.rb       # Anonymises PII, revokes sessions
│           ├── change_password_service.rb
│           ├── logout_service.rb       # Revokes token in Redis denylist
│           └── refresh_token_service.rb
├── config/
│   ├── initializers/
│   │   ├── redis.rb                    # ConnectionPool setup, RedisClient module
│   │   ├── cors.rb                     # Rack::Cors configuration
│   │   ├── lograge.rb                  # Structured JSON logging
│   │   └── pagy.rb                     # Pagination defaults
│   ├── environments/                   # Per-environment Rails config
│   ├── database.yml
│   ├── redis.yml
│   ├── routes.rb
│   └── sidekiq.yml
├── db/
│   └── migrate/
│       ├── 20240101000001_create_users.rb
│       └── 20240101000002_create_user_sessions.rb
├── spec/
│   ├── factories/
│   ├── models/
│   ├── requests/api/v1/                # Request (integration) specs
│   ├── services/users/                 # Unit specs for service objects
│   ├── integration/api/v1/             # Swagger-generating specs
│   └── support/                        # Helpers, shared contexts
├── Dockerfile                          # Multi-stage production build
├── docker-compose.yml                  # Local dev: Rails + Postgres + Redis + Sidekiq
└── .env.example
```

---

## Getting Started

### Prerequisites

- Ruby 3.2.x
- PostgreSQL 16
- Redis 7
- Bundler 2.x

### Local setup (without Docker)

```bash
# 1. Clone and install dependencies
git clone <repo-url> user_service && cd user_service
bundle install

# 2. Configure environment
cp .env.example .env
# Edit .env and fill in DB_USERNAME, DB_PASSWORD, JWT_SECRET, etc.

# 3. Bootstrap the database
bin/rails db:create db:migrate db:seed

# 4. Start the server
bin/rails server
```

### Local setup (with Docker Compose)

```bash
# Start all services (Rails API, Postgres, Redis, Sidekiq)
docker compose up

# In a separate terminal — run migrations on first boot
docker compose exec api bin/rails db:migrate db:seed
```

The API will be available at `http://localhost:3000`.

---

## Environment Variables

See `.env.example` for a complete, annotated list. Key variables:

| Variable               | Description                                  | Default                |
|------------------------|----------------------------------------------|------------------------|
| `DATABASE_URL`         | PostgreSQL connection string                 | Assembled from DB_*    |
| `REDIS_URL`            | Redis connection string                      | `redis://localhost:6379/0` |
| `JWT_SECRET`           | **Required.** 64-char random hex secret      | —                      |
| `JWT_ACCESS_TTL_SECONDS` | Access token lifetime                      | `900` (15 min)         |
| `JWT_REFRESH_TTL_SECONDS` | Refresh token lifetime                    | `604800` (7 days)      |
| `ALLOWED_ORIGINS`      | Comma-separated CORS origins                 | `*`                    |
| `RAILS_MAX_THREADS`    | Puma thread count                            | `5`                    |
| `SIDEKIQ_CONCURRENCY`  | Sidekiq worker threads                       | `5`                    |

---

## API Reference

Base URL: `/api/v1`

Interactive docs are available at `http://localhost:3000/api-docs` once the server is running.

### Authentication

#### `POST /auth/login`

```json
// Request
{
  "auth": {
    "email": "user@example.com",
    "password": "Password1234!"
  }
}

// Response 200
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

#### `POST /auth/refresh`

```json
// Request
{ "refresh_token": "eyJ..." }

// Response 200
{ "access_token": "eyJ...", "refresh_token": "eyJ...", "token_type": "Bearer", "expires_in": 900 }
```

#### `DELETE /auth/logout`

Requires `Authorization: Bearer <token>`. Returns `204 No Content`.

---

### Users

All user endpoints require `Authorization: Bearer <access_token>`.

| Method | Path                              | Auth required | Description            |
|--------|-----------------------------------|---------------|------------------------|
| GET    | `/users`                          | Any           | List/search users      |
| GET    | `/users/me`                       | Any           | Current user profile   |
| GET    | `/users/search?q=`                | Any           | Search active users    |
| GET    | `/users/:id`                      | Any           | Get user by ID         |
| POST   | `/users`                          | Admin         | Create user            |
| PATCH  | `/users/:id`                      | Self / Admin  | Update user            |
| DELETE | `/users/:id`                      | Admin         | Soft-delete user       |
| PATCH  | `/users/:id/activate`             | Admin         | Set status → active    |
| PATCH  | `/users/:id/deactivate`           | Admin         | Set status → inactive  |
| PATCH  | `/users/:id/change_password`      | Self / Admin  | Change password        |

#### List users (`GET /users`)

Query parameters:

| Param       | Type    | Description                                       |
|-------------|---------|---------------------------------------------------|
| `q`         | string  | Full-text search on email, username, name         |
| `page`      | integer | Page number (default: 1)                          |
| `per_page`  | integer | Items per page, max 100 (default: 20)             |
| `sort`      | string  | `created_at`, `email`, `username`, etc.           |
| `direction` | string  | `asc` or `desc` (default: `desc`)                 |

#### User response shape

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "user",
    "attributes": {
      "email": "user@example.com",
      "username": "johndoe",
      "first_name": "John",
      "last_name": "Doe",
      "full_name": "John Doe",
      "phone": null,
      "avatar_url": null,
      "bio": null,
      "role": "user",
      "status": "active",
      "email_verified": true,
      "locked": false,
      "last_login_at": "2024-01-15T10:30:00Z",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

---

### Health Endpoints

These endpoints are public (no auth required).

| Endpoint     | Description                            |
|--------------|----------------------------------------|
| `GET /health`    | Liveness probe — always returns 200 if process is up |
| `GET /readiness` | Readiness probe — checks DB + Redis connectivity     |
| `GET /metrics`   | Basic user counts for monitoring dashboards          |

---

## Running Tests

```bash
# Run all specs
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run a specific file
bundle exec rspec spec/models/user_spec.rb

# Generate Swagger docs
bundle exec rspec spec/integration --format Rswag::Specs::SwaggerFormatter --order defined
```

---

## Architecture

### Service Object Pattern

Business logic lives in `app/services/users/`. Each service:

1. Inherits from `BaseService`
2. Initialises with explicit keyword arguments (dependency injection friendly)
3. Implements a single `#call` method
4. Returns a `ServiceResult` (never raises for business-logic errors)

```ruby
result = Users::CreateService.new(params).call

if result.success?
  render json: result.payload
else
  render json: { error: result.error }, status: :unprocessable_entity
end
```

### Redis Usage

| Purpose              | Key pattern                         | TTL                  |
|----------------------|-------------------------------------|----------------------|
| Token denylist       | `revoked_token:<jti>`               | Remaining token TTL  |
| User cache           | `user_service:user:<id>`            | Configurable         |
| Rails cache store    | `user_service:cache:*`              | Varies               |
| Sidekiq queues       | Managed by Sidekiq                  | N/A                  |

### Security Considerations

- Passwords hashed with bcrypt (cost factor 12)
- JWT tokens signed with HMAC-SHA256
- Account locking with exponential backoff on failed logins
- PII anonymised on user deletion (GDPR-friendly)
- Sensitive params filtered from logs
- CORS restricted to configured origins in production
- HTTPS enforced in production (`FORCE_SSL=true`)

---

## Deployment

### Docker

```bash
# Build production image
docker build --target final -t user_service:latest .

# Run
docker run -p 3000:3000 \
  -e RAILS_ENV=production \
  -e DATABASE_URL=postgres://... \
  -e REDIS_URL=redis://... \
  -e JWT_SECRET=... \
  user_service:latest
```

### Kubernetes readiness

Configure liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 15
readinessProbe:
  httpGet:
    path: /readiness
    port: 3000
  initialDelaySeconds: 10
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Run the test suite (`bundle exec rspec`)
4. Run the linter (`bundle exec rubocop`)
5. Open a pull request

---

## License

MIT
