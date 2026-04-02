# COBOL → Java/Spring Boot Modernization Notes

## Source System
- **Name**: CICS Banking Sample (CBSA)
- **Language**: COBOL with CICS
- **Source**: IBM cicsdev/cics-banking-sample-cbsa
- **LOC**: ~30K+ lines of COBOL

## What Was Translated

### Core Banking Operations
| COBOL Program | Java Class | Description |
|--------------|------------|-------------|
| Account creation paragraphs | `AccountService.createAccount()` | New account setup |
| Balance inquiry logic | `AccountService.getBalance()` | Account balance lookup |
| Fund transfer processing | `AccountService.transfer()` | Inter-account transfers |
| Credit/debit processing | `AccountService.credit()/debit()` | Deposit/withdrawal |
| Customer management | `CustomerService` | Customer CRUD operations |

### Data Layer
| COBOL Construct | Java Equivalent | Notes |
|----------------|-----------------|-------|
| VSAM KSDS files | JPA + H2 Database | Key-sequenced → indexed DB |
| VSAM ESDS files | Transaction table | Sequential → timestamped records |
| COPYBOOK records | JPA @Entity classes | Field-level mapping |
| COMP-3 (packed decimal) | BigDecimal | Preserves exact decimal arithmetic |
| PIC 9(n) fields | String/int/long | Sized appropriately |
| PIC X(n) fields | String with @Size | Length constraints preserved |
| Level-88 conditions | Java enums | Type-safe replacements |

### Transaction Processing
| CICS Feature | Spring Boot Equivalent | Notes |
|-------------|----------------------|-------|
| CICS Transaction IDs | REST endpoints | ACCT→POST /api/accounts |
| BMS Screens | JSON request/response | Terminal I/O → REST API |
| SYNCPOINT | @Transactional | Atomic commit/rollback |
| EXEC CICS HANDLE | @ExceptionHandler | Error routing |
| EXEC CICS SEND MAP | ResponseEntity | Response formatting |

## What Was Simplified

1. **CICS Region Management**: Spring Boot auto-configuration replaces manual CICS region setup
2. **BMS Map Definitions**: Eliminated in favor of JSON REST API
3. **JCL Job Control**: Not needed - application runs as a standalone JAR
4. **VSAM File Definitions**: Replaced by JPA entity annotations and DDL auto-generation
5. **COBOL WORKING-STORAGE**: Method-local variables replace shared working storage
6. **PERFORM THRU**: Standard method calls replace PERFORM...THRU paragraph ranges

## CICS Semantics Approximated

### Transaction Isolation
- COBOL CICS used `EXEC CICS SYNCPOINT` for transaction boundaries
- Spring `@Transactional` provides equivalent ACID guarantees
- Rollback on exception replaces CICS ABEND handling

### Data Access Patterns
- VSAM READ/WRITE/REWRITE/DELETE → JPA repository methods
- VSAM START/READNEXT browsing → JPA queries with sorting
- Record locking → JPA optimistic/pessimistic locking

### Error Handling
- COBOL `EXEC CICS HANDLE CONDITION` → Spring `@ExceptionHandler`
- COBOL ABEND codes → Java exception hierarchy
- FILE STATUS checks → JPA exception translation

## Architecture Comparison

```
COBOL/CICS Architecture:           Spring Boot Architecture:
┌─────────────────────┐            ┌─────────────────────┐
│   BMS Screens       │            │   REST Controllers  │
│   (Terminal I/O)    │            │   (JSON API)        │
├─────────────────────┤            ├─────────────────────┤
│   CICS Programs     │            │   Service Layer     │
│   (COBOL Paragraphs)│            │   (@Service)        │
├─────────────────────┤            ├─────────────────────┤
│   VSAM Files        │            │   JPA Repositories  │
│   (KSDS/ESDS)       │            │   (H2/PostgreSQL)   │
└─────────────────────┘            └─────────────────────┘
```

## Running the Tests

```bash
cd modernization-targets/cobol-to-java
mvn test
```

## Key Design Decisions

1. **BigDecimal for all monetary values**: Preserves COBOL COMP-3 precision
2. **Account numbers as strings**: Matches COBOL PIC 9(10) with leading zeros
3. **Enum for account/transaction types**: Replaces COBOL level-88 conditions
4. **H2 for testing**: In-memory database simulates VSAM without infrastructure
5. **Record types for DTOs**: Java 17 records for request/response objects
