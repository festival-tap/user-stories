# festival-tap/user-stories

Executable behavioral specifications and black-box acceptance suites for the **[festival-tap](https://github.com)** platform.

This repository is the **single source of truth for system behavior**. Every story is completely implementation-agnostic and executes strictly against external **HTTPS / REST API** and **Web UI** boundaries—with zero knowledge of internal application code, storage engines, or hosting infrastructure.

---

## Table of Contents

<details open>
<summary><strong>Contents</strong></summary>

* [Functional User Stories](#functional-user-stories)
* [Repository Structure](#repository-structure)
* [Downstream Consumers](#downstream-consumers)
* [Authoring & Running Acceptance Suites](#authoring--running-acceptance-suites)
  * [Authoring Workflow (No Polyrepo Clone Required)](#authoring-workflow-no-polyrepo-clone-required)
* [Packaging & Release Governance](#packaging--release-governance)
</details>

---

## Functional User Stories

| Story ID | File | Capability & Core Invariant | Primary Actor |
| :--- | :--- | :--- | :--- |
| **`us-01`** | `specs/us-01-create-dispenser.txt` | Register a new beer dispenser with name, price per liter, and flow rate. | Admin |
| **`us-02`** | `specs/us-02-list-dispensers.txt` | Retrieve all active dispensers and live pricing. | Visitor / Admin |
| **`us-03`** | `specs/us-03-open-tap.txt` | Open a tap to start a pour session and trigger the **0.15 L** safety shut-off timer. | Visitor |
| **`us-04`** | `specs/us-04-close-tap.txt` | Close an active tap and finalize dispensed volume and total cost. | Visitor |
| **`us-05`** | `specs/us-05-spending-report.txt` | Compute real-time volume and revenue totals from recorded pour events. | Admin |
| **`us-06`** | `specs/us-06-admin-login.txt` | Authenticate operator credentials and issue admin session access. | Admin |
| **`us-07`** | `specs/us-07-public-access.txt` | Enforce `X-Festival-Pass` invite pass validation on public bar endpoints. | Visitor |
| **`us-08`** | `specs/us-08-event-sourcing.txt` | Guarantee append-only event ordering, optimistic concurrency, and deterministic state replay. | System |

---

## Repository Structure

```text
user-stories/
├── specs/
│   └── us-*.txt                      # Behavioral specifications & acceptance criteria
├── acceptance-back/
│   ├── run-all.sh                    # REST API acceptance suite runner
│   └── test-us-*.sh                  # Black-box REST API acceptance tests (HTTPS / JSON)
└── acceptance-front/
    └── run-frontend-tests.sh         # Black-box Web UI acceptance runner (Browser / DOM)
```

---

## Downstream Consumers

Downstream repositories validate their behavior against a pinned release tag (`v1.0.0`, etc.):

* **`api-contract` & `ui`:** Derives REST API endpoints, JSON schemas, and browser workflows (`/public`, `/login`) directly from the functional stories.
* **`core`:** Maps each story's invariants to domain-level behavioral tests.
* **`cloud-deploy`:** Fetches a pinned release archive and executes `acceptance-back/` and `acceptance-front/` as an automated black-box quality gate against any deployed HTTPS endpoint.

---

## Authoring & Running Acceptance Suites

This repository contains **no application server and no mocks**. All acceptance suites verify a real, running System Under Test (SUT) over **HTTP/HTTPS** and are configured exclusively via environment variables:

```bash
export BASE_URL="http://localhost:8080"
export UI_URL="http://localhost:8080"
export FESTIVAL_PASS="your-invite-pass"
export ADMIN_USER="admin"
export ADMIN_PASS="your-admin-password"

# Run REST API black-box acceptance suite
bash acceptance-back/run-all.sh

# Run Web UI black-box acceptance suite
bash acceptance-front/run-frontend-tests.sh
```

### Authoring Workflow (No Polyrepo Clone Required)
1. **Target a Running Instance:** Point `BASE_URL` at either the shared HTTPS sandbox or a standalone local server artifact downloaded from [`festival-tap/cloud-deploy` Releases](https://github.com/cloud-deploy/releases).
2. **Test-First Verification (Red -> Tag -> Green):** Write or update `specs/us-*.txt` and its matching acceptance script, verify that it fails against an unimplemented endpoint or passes against a completed build, and cut a new Git tag.
3. **State Isolation:** Generate unique dispenser or session identifiers inside test runs so suites execute safely against both ephemeral local instances and shared persistent environments.

---

## Packaging & Release Governance

* **Semantic Versioning (`SemVer`):** Breaking behavioral changes increment `MAJOR`; new user stories increment `MINOR`; clarifications or non-breaking test refinements increment `PATCH`.
* **Immutable Release Archives:** Every milestone is tagged (`v1.0.0`) and packaged as an immutable source/tarball archive via GitHub Releases so `cloud-deploy` can reproducibly verify any historical release on demand.
