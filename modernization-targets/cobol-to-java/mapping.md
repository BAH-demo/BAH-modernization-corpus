# COBOL Program → Java Class Mapping

## Transaction Mapping

| CICS Transaction ID | COBOL Program | Java Controller Method | REST Endpoint |
|---------------------|---------------|----------------------|---------------|
| ACCT | ACCTCTRL | `AccountController.createAccount()` | POST /api/accounts |
| BALN | BALNCTRL | `AccountController.getBalance()` | GET /api/accounts/{id}/balance |
| XFER | XFERCTRL | `AccountController.transfer()` | POST /api/accounts/transfer |
| CRDT | CRDTCTRL | `AccountController.credit()` | POST /api/accounts/{id}/credit |
| DBIT | DBITCTRL | `AccountController.debit()` | POST /api/accounts/{id}/debit |
| CUST | CUSTCTRL | `CustomerController.createCustomer()` | POST /api/customers |
| CUPU | CUSTUPDT | `CustomerController.updateCustomer()` | PUT /api/customers/{id} |
| CUGT | CUSTINQY | `CustomerController.getCustomer()` | GET /api/customers/{id} |

## Data Structure Mapping

| COBOL Copybook | Java Entity | Database Table |
|---------------|-------------|----------------|
| ACCOUNT-RECORD | `Account.java` | accounts |
| CUSTOMER-RECORD | `Customer.java` | customers |
| TRANSACTION-RECORD | `Transaction.java` | transactions |

## Field-Level Mapping

### Account Record
| COBOL Field | PIC Clause | Java Field | Java Type |
|------------|------------|------------|-----------|
| ACCOUNT-NUMBER | PIC 9(10) | accountNumber | String |
| CUSTOMER-NUMBER | PIC 9(10) | customerNumber | String |
| ACCOUNT-TYPE | PIC X(8) | accountType | AccountType (enum) |
| ACCOUNT-BALANCE | PIC S9(13)V99 COMP-3 | balance | BigDecimal |
| ACCOUNT-INTEREST-RATE | PIC 9V9(4) COMP-3 | interestRate | BigDecimal |
| ACCOUNT-OVERDRAFT | PIC S9(9)V99 COMP-3 | overdraftLimit | BigDecimal |
| ACCOUNT-AVAILABLE | PIC S9(13)V99 COMP-3 | availableBalance | BigDecimal |
| ACCOUNT-OPENED | PIC X(10) | openedDate | LocalDateTime |
| ACCOUNT-STATUS | PIC X(10) | status | String |

### Transaction Record
| COBOL Field | PIC Clause | Java Field | Java Type |
|------------|------------|------------|-----------|
| TRANSACTION-ID | PIC 9(12) | id | Long (auto-generated) |
| TRANSACTION-ACCT-NO | PIC 9(10) | accountNumber | String |
| TRANSACTION-TYPE | PIC X(4) | transactionType | TransactionType (enum) |
| TRANSACTION-AMOUNT | PIC S9(13)V99 COMP-3 | amount | BigDecimal |
| TRANSACTION-DATE | PIC X(26) | transactionDate | LocalDateTime |
| TRANSACTION-DESC | PIC X(40) | description | String |

## Service Layer Mapping

| COBOL Paragraph | Java Method | Notes |
|----------------|-------------|-------|
| CREATE-ACCOUNT-PARAGRAPH | AccountService.createAccount() | Includes validation |
| GET-BALANCE-PARAGRAPH | AccountService.getBalance() | Returns BigDecimal |
| PROCESS-CREDIT-PARAGRAPH | AccountService.credit() | With transaction record |
| PROCESS-DEBIT-PARAGRAPH | AccountService.debit() | Checks available balance |
| PROCESS-TRANSFER-PARAGRAPH | AccountService.transfer() | Atomic via @Transactional |
| CREATE-CUSTOMER-PARAGRAPH | CustomerService.createCustomer() | Auto-generates number |
| UPDATE-CUSTOMER-PARAGRAPH | CustomerService.updateCustomer() | Partial updates |
| GET-CUSTOMER-PARAGRAPH | CustomerService.getCustomer() | By customer number |

## Error Code Mapping

| COBOL Error | Java Exception | HTTP Status |
|-------------|---------------|-------------|
| FILE STATUS '23' (not found) | AccountNotFoundException | 404 |
| ABEND (insufficient funds) | InsufficientFundsException | 400 |
| FILE STATUS '22' (duplicate) | DataIntegrityViolationException | 409 |
| INVREQ | IllegalArgumentException | 400 |
