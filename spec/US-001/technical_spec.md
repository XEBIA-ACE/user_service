## SVC-01

# Technical Design Specification

**Story ID**: US-001
**Service**: User Service (SVC-01)
**Spec Version**: 1.0

---

## Section 1: Contracts & Interfaces

### 1.1 API Contract — POST /api/v1/users/register

This endpoint is an existing route that SHALL be fully implemented per this story. The request body SHALL carry four fields: `full_name` (string, required), `email_address` (string, required, RFC 5322 format), `password` (string, required, opaque), and `consent_accepted` (boolean, required, MUST be `true`). The endpoint SHALL return HTTP 201 on success. The response body SHALL include `user_id` (UUID), `account_status` (string enum: `active`), `created_at` (ISO-8601 datetime), and `session_token` (opaque string). The `session_token` SHALL be set as an `HttpOnly`, `Secure`, `SameSite=Strict` cookie in addition to appearing in the response body to support both browser and mobile API clients.

[NEEDS CLARIFICATION: Should session_token in the response body be omitted for browser clients to enforce cookie-only delivery?] (Assumed: token is returned in both cookie and body to satisfy mobile API clients per service context.)

### 1.2 Data Model

**Table: `user_accounts`**

The table SHALL contain the following columns: `user_id` UUID PRIMARY KEY DEFAULT gen_random_uuid(), `full_name` VARCHAR(255) NOT NULL, `email_address` VARCHAR(320) NOT NULL, `password_hash` TEXT NOT NULL, `consent_accepted` BOOLEAN NOT NULL DEFAULT FALSE, `consent_timestamp` TIMESTAMPTZ, `account_status` VARCHAR(20) NOT NULL DEFAULT 'active', `created_at` TIMESTAMPTZ NOT NULL DEFAULT NOW(), `updated_at` TIMESTAMPTZ NOT NULL DEFAULT NOW(). A UNIQUE index SHALL be created on `email_address`. A non-unique index SHOULD be created on `created_at` to support audit queries.

**Table: `user_sessions`**

Columns: `session_id` UUID PRIMARY KEY DEFAULT gen_random_uuid(), `user_id` UUID NOT NULL REFERENCES user_accounts(user_id) ON DELETE CASCADE, `session_token_hash` TEXT NOT NULL, `created_at` TIMESTAMPTZ NOT NULL DEFAULT NOW(), `expires_at` TIMESTAMPTZ NOT NULL. A UNIQUE index SHALL be created on `session_token_hash`. An index SHALL be created on `user_id`.

[NEEDS CLARIFICATION: What is the required session TTL?] (Assumed: 24-hour ephemeral session aligned with A-002.)

### 1.3 Password Policy Schema

The `GET /api/v1/users/register` form-render endpoint SHALL return a `password_policy` object in its response describing minimum length, required character classes, and maximum length so the client-side validation layer (FR-006, A-003) can enforce rules without hardcoding them.

---

## Section 2: Test Strategy

Tests SHALL be written before implementation is merged. Each test case references the contract property it validates.

**Unit Tests — `RegistrationService`**

- `test_create_account_persists_user_record`: Validates `user_accounts` insert, `account_status = active`, `consent_timestamp` populated. Covers FR-002, FR-009.
- `test_consent_false_raises_validation_error`: Passes `consent_accepted = false`; asserts `ConsentNotAcceptedException` is raised before DB write. Covers FR-009.
- `test_session_token_generated_and_stored`: Asserts `user_sessions` row created with correct `user_id` and non-null `expires_at`. Covers FR-010, FR-011 (A-002).
- `test_password_policy_payload_shape`: Asserts policy endpoint response contains `min_length`, `max_length`, `required_classes`. Covers FR-006, A-003.

**Integration Tests — `POST /api/v1/users/register`**

- `test_register_happy_path_returns_201`: Full valid payload; asserts HTTP 201, `session_token` in body, `Set-Cookie` header present with `HttpOnly` and `Secure` flags. Covers API contract §1.1.
- `test_register_missing_full_name_returns_422`: Omits `full_name`; asserts HTTP 422 with field-level error referencing `full_name`. Covers FR-008.
- `test_register_invalid_email_format_returns_422`: Malformed email; asserts HTTP 422. Covers FR-007.
- `test_register_consent_false_returns_422`: `consent_accepted = false`; asserts HTTP 422. Covers FR-009.
- `test_register_response_body_schema`: Asserts presence and types of `user_id`, `account_status`, `created_at`, `session_token`. Covers §1.1 response contract.

**Client-Side