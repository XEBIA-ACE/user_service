## SVC-01

# Functional Specification: New User Registration Form Submission (Happy Path)

**Story ID**: US-001
**Service**: User Service (SVC-01)
**Feature**: User Registration & Account Management
**Version**: 1.0

---

### Purpose

This specification defines the behaviour of the User Service when a new user completes and submits the account registration form along the happy path. It exists to ensure the service correctly captures user identity data, enforces consent requirements, creates a valid account record, and establishes an authenticated session upon success.

---

### Scope

This specification covers registration form rendering, client-side field-level validation, consent capture, account creation on valid submission, and post-registration session establishment within the User Service. It applies exclusively to first-time users with no existing account.

---

### Non-Goals

- Server-side input sanitisation and validation logic internals
- Password hashing and credential storage mechanisms
- Duplicate email detection and conflict error handling (covered in US-02)
- Submission failure and server error recovery paths (covered in US-03)
- Wishlist provisioning triggered at account creation
- Email verification or post-registration email dispatch
- Social or third-party authentication flows
- Account profile editing after registration

---

### Key Entities

**User Account**
- full_name: text
- email_address: text
- password_credential: opaque credential value
- consent_accepted: boolean
- consent_timestamp: datetime
- account_status: enumerated state (active, pending, suspended)
- created_at: datetime
- session_token: opaque token value

Relationships:
- User Account is associated with exactly one Session at the point of successful registration (cardinality: 1-to-1 at creation)
- User Account MAY be associated with a Wishlist record provisioned by a downstream service (cardinality: 1-to-0..1; out of scope for this story)

---

### Assumptions

**A-001**: The registration form requires exactly three data-entry fields — full name, email address, and password — plus one ToS/privacy consent checkbox, as stated in REC-01. Affects: FR-001, FR-002, FR-003.
*(Referenced from user story assumption REC-01)*

**A-002**: Post-registration session behaviour is defined by REC-05 and results in the user being placed into an authenticated session immediately upon successful account creation, without a separate login step. Affects: FR-010, FR-011.
*(Referenced from user story assumption REC-05)*

**A-003**: Password complexity rules are pre-defined system policy and are available to the client-side validation layer at the time of form rendering. Affects: FR-006.

**A-004**: WCAG 2.1 AA compliance is enforced at the presentation layer; the User Service is responsible for supplying correctly labelled field metadata and logical field ordering to the rendering layer. Affects: FR-004, FR-005.

[NEEDS CLARIFICATION: Does REC-05 specify a session duration or token type that must be reflected in the functional behaviour (e.g. persistent vs. ephemeral session)?] (Assumed: session is ephemeral and scoped to the browser/app session until explicit logout or expiry.)

---

### Functional Requirements

**Form Rendering**

FR-001 [P1]: The User Service SHALL present a registration form containing input fields for full name, email address, and password, and a ToS/privacy consent checkbox when a new user navigates to the registration page. *(Ref: A-001)*

FR-002 [P1]: The User Service SHALL designate all four form inputs — full name, email address, password, and consent checkbox — as mandatory before submission is permitted.

FR-003 [P3]: The User Service SHALL render each form field with a descriptive, programmatically associated label so that the field's purpose is unambiguous to both sighted and assistive-technology users. *(Ref: A-001, A-004)*

FR-004 [P3]: The User Service SHALL present form fields in a logical focus order that follows the visual reading sequence of the form. *(Ref: A-004)*

FR-005 [P3]: The User Service SHALL ensure the registration form meets WCAG 2.1 AA accessibility requirements with zero critical violations at the point of rendering. *(Ref: A-004)*

---

**Client-Side Validation**

FR-006 [P2]: The User Service SHALL validate the password field against the defined complexity rules on the client side and SHALL display field-level feedback indicating which rule is unmet before the user attempts submission. *(Ref: A-003)*

FR-007 [P2]: The User Service SHALL validate that the email address field contains a correctly formatted email address on the client side and SHALL surface a field-level error message when the format is invalid.

FR-008 [P2]: The User Service SHALL validate that the full name field is non-empty and SHALL surface a field-level error message adjacent to the field when the value is absent or consists solely of whitespace.

FR-009 [P2]: The User Service SHALL prevent form submission and SHALL indicate to the user that the ToS/privacy consent checkbox must be checked when the checkbox remains unchecked at submission time.

---

**