# AGENTS.md — User Service Scaffold Specification

## 1. Stack

| Technology | Role |
|---|---|
| **Node.js 20 LTS + Fastify 4** | Primary runtime and HTTP framework (preferred); Java 21 + Spring Boot 3 is the alternate |
| **TypeScript 5** | Type-safe language layer over Node.js |
| **PostgreSQL 15 (AWS RDS)** | Relational identity store — users, credentials, profile data |
| **PgBouncer** | Connection pooling sidecar between service and RDS |
| **Prisma ORM** | Schema management, migrations, and type-safe queries (Node path); Hibernate/Flyway for Spring path |
| **bcrypt / Argon2** | Password hashing — Argon2id preferred; bcrypt as fallback |
| **AES-256-GCM** | Application-layer PII field-level encryption (email, mobile number) |
| **Apache Kafka / AWS SQS** | Domain event publishing — `UserRegistered` events |
| **Redis / AWS ElastiCache** | Session metadata caching (TTL-bound keys) |
| **class-transformer + class-validator** | DTO-to-domain mapping and input validation (Node path) |
| **Jest + Supertest** | Unit and integration testing (Node path); JUnit 5 + Mockito for Spring path |
| **Docker + AWS ECS / Kubernetes** | Containerized runtime and orchestration |
| **ESLint + Prettier** | Linting and formatting |
| **Helmet + rate-limiter-flexible** | HTTP security headers and request rate limiting |

---

## 2. Project Structure

Use the following exact layout. Do not deviate from this structure.

```
user-service/
├── .github/
│   └── workflows/
│       ├── ci.yml                  # PR validation: lint, test, build
│       └── deploy.yml              # Image build and push to ECR/registry
├── docker/
│   ├── Dockerfile                  # Multi-stage production image
│   ├── Dockerfile.dev              # Dev image with hot-reload
│   └── docker-compose.yml          # Local stack: app, postgres, pgbouncer, redis, kafka
├── prisma/
│   ├── schema.prisma               # Data model definitions
│   └── migrations/                 # Auto-generated migration files
├── src/
│   ├── main.ts                     # Entry point — builds and starts Fastify app
│   ├── app.ts                      # Fastify instance factory, plugin registration
│   ├── config/
│   │   ├── index.ts                # Aggregated config export
│   │   ├── app.config.ts           # Port, environment, service name
│   │   ├── database.config.ts      # Postgres/PgBouncer DSN, pool settings
│   │   ├── redis.config.ts         # Redis connection config
│   │   ├── kafka.config.ts         # Broker URLs, topic names, producer settings
│   │   └── crypto.config.ts        # AES key reference (loaded from AWS Secrets Manager)
│   ├── modules/
│   │   └── user/
│   │       ├── user.module.ts      # Wires routes, controllers, services, repos
│   │       ├── controllers/
│   │       │   └── user.controller.ts   # Fastify route handlers — registration, profile CRUD
│   │       ├── services/
│   │       │   ├── user.service.ts      # Orchestration — registration flow, profile ops
│   │       │   ├── auth.service.ts      # External IdP integration, JWT token relay
│   │       │   └── session.service.ts   # Redis session metadata read/write
│   │       ├── repositories/
│   │       │   └── user.repository.ts   # Prisma queries — all DB access isolated here
│   │       ├── domain/
│   │       │   ├── user.entity.ts       # Core domain object (plain class, no ORM decorators)
│   │       │   ├── user.factory.ts      # Factory/Builder — constructs User from registration path
│   │       │   └── events/
│   │       │       └── user-registered.event.ts  # Domain event value object
│   │       ├── dto/
│   │       │   ├── register-user.dto.ts     # Inbound registration payload + validation rules
│   │       │   ├── update-profile.dto.ts    # Inbound profile update payload
│   │       │   └── user-response.dto.ts     # Outbound safe user representation (no PII raw)
│   │       ├── mappers/
│   │       │   └── user.mapper.ts       # DTO ↔ domain ↔ persistence model transformations
│   │       └── validators/
│   │           └── user.validator.ts    # Custom validation logic (uniqueness checks, etc.)
│   ├── infrastructure/
│   │   ├── database/
│   │   │   └── prisma.client.ts     # Singleton Prisma client with lifecycle hooks
│   │   ├── messaging/
│   │   │   ├── kafka.producer.ts    # Kafka producer wrapper with retry logic
│   │   │   └── sqs.publisher.ts     # SQS publisher (swap-in if Kafka unavailable)
│   │   ├── cache/
│   │   │   └── redis.client.ts      # ioredis client wrapper
│   │   └── crypto/
│   │       ├── encryption.service.ts  # AES-256-GCM encrypt/decrypt for PII fields
│   │       └── hashing.service.ts     # Argon2id hash and verify wrappers
│   ├── plugins/
│   │   ├── auth.plugin.ts           # JWT verification plugin (fastify-jwt or custom)
│   │   ├── rate-limit.plugin.ts     # rate-limiter-flexible integration
│   │   └── error-handler.plugin.ts  # Centralised error mapping to RFC 7807 responses
│   ├── shared/
│   │   ├── constants/
│   │   │   └── error-codes.ts       # Application error code enum
│   │   ├── errors/
│   │   │   ├── app.error.ts         # Base application error class
│   │   │   ├── validation.error.ts
│   │   │   ├── conflict.error.ts    # Duplicate identifier
│   │   │   └── not-found.error.ts
│   │   ├── types/
│   │   │   └── index.ts             # Shared TypeScript interfaces and type aliases
│   │   └── utils/
│   │       └── logger.ts            # Pino logger instance (structured JSON)
│   └── health/
│       └── health.controller.ts     # /health and /ready endpoints
├── test/
│   ├── unit/
│   │   ├── user.service.spec.ts
│   │   ├── user.factory.spec.ts
│   │   ├── user.mapper.spec.ts
│   │   ├── encryption.service.spec.ts
│   │   └── hashing.service.spec.ts
│   ├── integration/
│   │   ├── user.registration.spec.ts   # Full HTTP → DB round-trip using test DB
│   │   ├── user.profile.spec.ts
│   │   └── messaging.spec.ts           # Event publishing assertions
│   ├── fixtures/
│   │   └── user.fixtures.ts            # Reusable test data builders
│   └── setup/
│       ├── jest.setup.ts               # Global beforeAll/afterAll hooks
│       └── test-db.helper.ts           # Test DB seeding and teardown utilities
├── tasks.md                            # Agent-generated task breakdown (created before coding)
├── .env.example                        # All required env vars with placeholder values
├── .eslintrc.json
├── .prettierrc
├── jest.config.ts
├── tsconfig.json
├── tsconfig.build.json
└── package.json
```

---

## 3. Required Workflow

The agent **must** follow these steps in order. Do not skip or reorder steps.

### Step 1 — Read Specifications
- Read all story-level spec documents provided in the task context before writing any code.
- Identify all user registration paths (email, mobile), validation rules, PII fields, event contracts, and IdP integration points.
- Note which message broker is active (Kafka or SQS) for this environment.

### Step 2 — Create `tasks.md`
- Create `tasks.md` in the project root **before writing any implementation code**.
- Break the work into numbered, atomic tasks. Each task must state: what to build, which file(s) to create or modify, and the acceptance criterion.
- Example task format:
  ```
  ## Task 4 — Implement AES-256-GCM encryption service
  - File: src/infrastructure/crypto/encryption.service.ts
  - Implement encrypt(plaintext: string): EncryptedPayload and decrypt(payload: EncryptedPayload): string
  - Use a 256-bit key loaded from config/crypto.config.ts (sourced from AWS Secrets Manager)
  - Acceptance: unit test passes with round-trip encrypt → decrypt producing original value
  ```
- Do not begin implementation until `tasks.md` is complete and all tasks are listed.

### Step 3 — Scaffold Project
- Run `npm init -y`, install all dependencies, generate `tsconfig.json`, `.eslintrc.json`, `.prettierrc`, and `jest.config.ts`.
- Initialise Prisma: `npx prisma init`.
- Create the full directory tree from Section 2 with empty placeholder files before filling in logic.

### Step 4 — Implement in Task Order
- Work through `tasks.md` sequentially.
- Mark each task `[x]` in `tasks.md` when its implementation and tests are complete.
- For each task: write the implementation file, then immediately write its unit test before moving to the next task.

### Step 5 — Integration Tests
- After all unit-level tasks are complete, implement integration tests under `test/integration/`.
- Integration tests must use a real PostgreSQL instance (via Docker Compose test profile) and mock only external services (Kafka/SQS, IdP, Redis where appropriate).

### Step 6 — Validate
- Run `npm run lint` — zero errors permitted.
- Run `npm run test:unit` — 90% line and branch coverage required.
- Run `npm run test:integration` — all tests green.
- Run `npm run build` — TypeScript compilation must succeed with zero errors.
- Run `docker build -f docker/Dockerfile .` — image must build successfully.
- Do not mark the service complete until all six checks pass.

---

## 4. Coding Conventions

### Naming
| Artifact | Convention | Example |
|---|---|---|
| Files | `kebab-case` | `user.service.ts` |
| Classes | `PascalCase` | `UserService` |
| Interfaces | `PascalCase` prefixed `I` | `IUserRepository` |
| Methods / variables | `camelCase` | `registerUser()` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_EMAIL_LENGTH` |
| Database tables | `snake_case` | `user_accounts` |
| Kafka topics / SQS queues | `kebab-case` | `user-registered` |
| Env vars | `SCREAMING_SNAKE_CASE` | `DATABASE_URL` |
| DTOs | Suffix `Dto` | `RegisterUserDto` |
| Domain events | Suffix `Event` | `UserRegisteredEvent` |

### Architecture Patterns
- **Strict layering**: Routes → Controllers → Services → Repositories. No layer may skip another. Controllers never touch repositories directly.
- **Factory/Builder Pattern**: All `User` domain object construction must go through `user.factory.ts`. Never instantiate `UserEntity` directly outside the factory.
- **Repository Pattern**: All database access is isolated in `user.repository.ts`. Services never import Prisma client directly.
- **Dependency Injection**: Use constructor injection throughout. Services and repositories receive their dependencies via constructor parameters. No service-locator pattern.
- **Domain events are value objects**: `UserRegisteredEvent` must be immutable (use `readonly` on all fields).
- **No business logic in controllers**: Controllers only parse/validate HTTP input, delegate to services, and map responses.
- **DTO mapping**: All transformations between layers go through `user.mapper.ts`. Never spread raw database records into response objects.

### Validation
- Use `class-validator` decorators on all DTOs.
- Register a Fastify `preHandler` hook that runs `class-validator` before any route handler executes.
- Uniqueness validation (duplicate email/mobile) is a service-layer concern — query repository, throw `ConflictError` if duplicate found.
- All string inputs must be trimmed and length-capped before persistence.

### Security
- Never log raw PII (email, mobile number) — log only masked or hashed references.
- AES-256-GCM keys must be loaded exclusively from `crypto.config.ts`, which reads from AWS Secrets Manager or environment variable `ENCRYPTION_KEY`. Never hardcode keys.
- Argon2id parameters: `memoryCost: 65536`, `timeCost: 3`, `parallelism: 4` — do not relax these defaults.
- All Fastify routes under `/users` (except `/register` and `/login`) must require a valid JWT via `auth.plugin.ts`.
- Apply `helmet()` and rate limiting globally.

### Error Handling
- All errors extend `AppError` which includes `statusCode`, `errorCode` (from `error-codes.ts`), and `message`.
- The `error-handler.plugin.ts` catches all thrown errors and formats them as RFC 7807 Problem Detail JSON.
- Never expose stack traces or internal error details in production responses.

### Code Style
- `strict: true` in `tsconfig.json` — no implicit `any`.
- Maximum function length: 40 lines. Extract helpers if exceeded.
- Maximum file length: 250 lines. Split into sub-modules if exceeded.
- All async functions must use `async/await` — no raw Promise chains.
- All public methods on services and repositories must have JSDoc comments.

---

## 5. Testing

### Framework Setup
```jsonc
// jest.config.ts
{
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/test"],
  collectCoverageFrom: ["src/**/*.ts", "!src/main.ts", "!src/**/*.d.ts"],
  coverageThreshold: {
    global: { lines: 90, branches: 90, functions: 90, statements: 90 }
  },
  setupFilesAfterFramework: ["<rootDir>/test/setup/jest.setup.ts"]
}
```

### Unit Tests (`test/unit/`)
- Every service method, factory method, mapper, and crypto utility must have a dedicated unit test.
- Mock all external dependencies (repository, Prisma, Redis, Kafka/SQS, IdP HTTP calls) using `jest.mock()` or manual mocks.
- Test both happy-path and all error branches (duplicate user, invalid format, hashing failure, encryption failure, event publish failure).
- Use `test/fixtures/user.fixtures.ts` builders for all test data — no inline object literals in test files.
- Required unit test files (minimum):
  - `user.service.spec.ts` — registration flow, profile read/update, conflict handling
  - `user.factory.spec.ts` — email path, mobile path, missing identifier rejection
  - `user.mapper.spec.ts` — DTO → domain, domain → response, PII field exclusion
  - `encryption.service.spec.ts` — round-trip, key rotation handling, invalid ciphertext
  - `hashing.service.spec.ts` — hash uniqueness, verify correct/incorrect password

### Integration Tests (`test/integration/`)
- Use a dedicated test PostgreSQL database spun up via `docker-compose --profile test`.
- Run Prisma migrations against the test DB in `beforeAll`.
- Truncate all tables in `beforeEach` using `test-db.helper.ts`.
- Use `Supertest` to make real HTTP requests against a bound Fastify instance.
- Mock only: Kafka/SQS publisher, external IdP HTTP calls, AWS