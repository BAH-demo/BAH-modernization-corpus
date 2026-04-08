# Legacy Database Patterns and Modern Equivalents

## Overview

This catalog maps common legacy database patterns to their modern equivalents. Each pattern includes the legacy approach, why it exists, the risks it introduces, and the recommended modern alternative. These patterns are informed by real schemas in the [db-schema-corpus](https://github.com/mmartoccia/db-schema-corpus), including Oracle EBS PL/SQL packages, PeopleSoft stored procedures and triggers, and ERP reference schemas.

---

## 1. Oracle PL/SQL to PostgreSQL/MySQL Conversion Patterns

### 1.1 Package Bodies to Schema-Organized Functions

**Legacy (Oracle PL/SQL):**
```sql
-- Oracle EBS HRMS pattern (see db-schema-corpus/oracle/oracle-ebs-scripts/)
CREATE OR REPLACE PACKAGE OIM_EBSHRMS_SCHEMA_PKG AS
  PROCEDURE get_schema(schemaout OUT schemalist);
END OIM_EBSHRMS_SCHEMA_PKG;

CREATE OR REPLACE PACKAGE BODY OIM_EBSHRMS_SCHEMA_PKG AS
  PROCEDURE get_schema(schemaout OUT schemalist) AS
    attr attributelist;
  BEGIN
    schemaout := schemalist();
    schemaout.extend(1);
    attr := attributelist();
    attr.extend(50);
    attr(1) := attributeinfo('HIRE_DATE','date',1,1,0,1);
    -- ... 27 attributes for __PERSON__
  END get_schema;
END OIM_EBSHRMS_SCHEMA_PKG;
```

**Modern (PostgreSQL + Application Logic):**
```sql
-- PostgreSQL: Schema as data, not code
CREATE TABLE hrms_entity_attributes (
    entity_name   TEXT NOT NULL,
    attribute_name TEXT NOT NULL,
    data_type     TEXT NOT NULL,
    is_required   BOOLEAN DEFAULT FALSE,
    is_searchable BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (entity_name, attribute_name)
);

-- Application layer (Python/Java) reads attribute metadata
-- and dynamically constructs queries — no PL/SQL needed
```

**Migration notes:**
- Oracle `PACKAGE` has no direct PostgreSQL equivalent; split into schema-qualified functions or move logic to the application layer
- Oracle custom types (`schemalist`, `attributeinfo`) should become database tables or application-layer data structures
- Prefer application-layer logic for schema introspection over database-embedded procedures

### 1.2 Oracle-Specific SQL to PostgreSQL

| Oracle Syntax | PostgreSQL Equivalent |
|--------------|----------------------|
| `NVL(x, y)` | `COALESCE(x, y)` |
| `SYSDATE` | `CURRENT_TIMESTAMP` |
| `ROWNUM` | `ROW_NUMBER() OVER()` or `LIMIT` |
| `DECODE(x, a, b, c)` | `CASE WHEN x = a THEN b ELSE c END` |
| `VARCHAR2(n)` | `VARCHAR(n)` or `TEXT` |
| `NUMBER(p,s)` | `NUMERIC(p,s)` |
| `TO_DATE(NULL, 'YYYYMMDD')` | `NULL::DATE` |
| `CONNECT BY PRIOR` | Recursive CTE (`WITH RECURSIVE`) |
| `DBMS_OUTPUT.PUT_LINE(...)` | `RAISE NOTICE '...'` |
| `EXCEPTION WHEN OTHERS THEN` | `EXCEPTION WHEN OTHERS THEN` (same syntax, different behavior) |

### 1.3 Oracle Grants and Synonyms

**Legacy (Oracle EBS):**
```sql
-- db-schema-corpus/oracle/oracle-ebs-scripts/ebs_hrms_grants.sql pattern
GRANT EXECUTE ON OIM_EBSHRMS_SCHEMA_PKG TO oim_user;
CREATE SYNONYM oim_user.SCHEMA_PKG FOR owner.OIM_EBSHRMS_SCHEMA_PKG;
```

**Modern (PostgreSQL):**
```sql
-- PostgreSQL: Use schema search_path instead of synonyms
CREATE SCHEMA hrms;
GRANT USAGE ON SCHEMA hrms TO app_role;
GRANT SELECT ON ALL TABLES IN SCHEMA hrms TO app_role;
SET search_path TO hrms, public;
```

---

## 2. COBOL File Structures to Relational Schema Patterns

### 2.1 Fixed-Length Record Files to Normalized Tables

**Legacy (COBOL Copybook):**
```cobol
01 EMPLOYEE-RECORD.
   05 EMP-ID          PIC 9(6).
   05 EMP-NAME.
      10 EMP-FIRST    PIC X(20).
      10 EMP-LAST     PIC X(25).
   05 EMP-DEPT        PIC 9(3).
   05 EMP-SALARY      PIC 9(7)V99 COMP-3.
   05 EMP-HIRE-DATE   PIC 9(8).
   05 FILLER          PIC X(30).
```

**Modern (PostgreSQL):**
```sql
CREATE TABLE employees (
    emp_id      INTEGER PRIMARY KEY,
    first_name  VARCHAR(20) NOT NULL,
    last_name   VARCHAR(25) NOT NULL,
    dept_id     INTEGER REFERENCES departments(dept_id),
    salary      NUMERIC(9,2),
    hire_date   DATE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_employees_dept ON employees(dept_id);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);
```

**Migration notes:**
- COBOL `PIC 9(7)V99 COMP-3` (packed decimal) maps to `NUMERIC(9,2)` — validate precision during conversion
- COBOL date fields (PIC 9(8) = YYYYMMDD) must be parsed and converted to SQL `DATE` type
- `FILLER` fields are discarded — they exist only for record alignment
- Hierarchical group items (e.g., `EMP-NAME` containing `EMP-FIRST` and `EMP-LAST`) are flattened to individual columns

### 2.2 COBOL REDEFINES to Polymorphic Tables

**Legacy (COBOL):**
```cobol
01 TRANSACTION-RECORD.
   05 TRANS-TYPE       PIC X(1).
   05 TRANS-DATA.
      10 DEPOSIT-DATA REDEFINES TRANS-DATA.
         15 DEP-AMOUNT PIC 9(9)V99.
         15 DEP-ACCOUNT PIC 9(10).
      10 WITHDRAWAL-DATA REDEFINES TRANS-DATA.
         15 WDR-AMOUNT PIC 9(9)V99.
         15 WDR-ACCOUNT PIC 9(10).
         15 WDR-REASON PIC X(20).
```

**Modern (PostgreSQL — table-per-type):**
```sql
CREATE TABLE transactions (
    trans_id    SERIAL PRIMARY KEY,
    trans_type  CHAR(1) NOT NULL CHECK (trans_type IN ('D', 'W')),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE deposits (
    trans_id    INTEGER PRIMARY KEY REFERENCES transactions(trans_id),
    amount      NUMERIC(11,2) NOT NULL,
    account_id  BIGINT NOT NULL REFERENCES accounts(account_id)
);

CREATE TABLE withdrawals (
    trans_id    INTEGER PRIMARY KEY REFERENCES transactions(trans_id),
    amount      NUMERIC(11,2) NOT NULL,
    account_id  BIGINT NOT NULL REFERENCES accounts(account_id),
    reason      VARCHAR(20)
);
```

---

## 3. VSAM/IMS to Modern Key-Value/Document Store Patterns

### 3.1 VSAM KSDS (Key-Sequenced) to Key-Value Store

**Legacy (VSAM KSDS):**
- Fixed-length records indexed by a primary key
- Sequential and random access by key
- No SQL interface — accessed via COBOL `READ`, `WRITE`, `REWRITE`, `DELETE`

**Modern (DynamoDB):**
```json
{
    "TableName": "CustomerRecords",
    "KeySchema": [
        { "AttributeName": "customer_id", "KeyType": "HASH" }
    ],
    "AttributeDefinitions": [
        { "AttributeName": "customer_id", "AttributeType": "S" },
        { "AttributeName": "region", "AttributeType": "S" }
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "region-index",
            "KeySchema": [
                { "AttributeName": "region", "KeyType": "HASH" }
            ]
        }
    ]
}
```

**Alternative (PostgreSQL):**
```sql
-- If staying relational, VSAM KSDS maps cleanly to an indexed table
CREATE TABLE customer_records (
    customer_id VARCHAR(20) PRIMARY KEY,
    region      VARCHAR(10),
    record_data JSONB  -- flexible schema for varying record layouts
);

CREATE INDEX idx_customer_region ON customer_records(region);
```

### 3.2 IMS Hierarchical to Document Store

**Legacy (IMS):**
```
DBD: EMPLOYEE_DB
  SEGM: EMPLOYEE (root)
    FIELD: EMP_ID (KEY)
    FIELD: EMP_NAME
    SEGM: DEPARTMENT (child of EMPLOYEE)
      FIELD: DEPT_ID (KEY)
      FIELD: DEPT_NAME
      SEGM: PROJECT (child of DEPARTMENT)
        FIELD: PROJ_ID (KEY)
        FIELD: PROJ_NAME
```

**Modern (DocumentDB/MongoDB):**
```json
{
    "emp_id": "E12345",
    "emp_name": "Jane Smith",
    "departments": [
        {
            "dept_id": "D100",
            "dept_name": "Engineering",
            "projects": [
                { "proj_id": "P001", "proj_name": "Modernization" },
                { "proj_id": "P002", "proj_name": "Cloud Migration" }
            ]
        }
    ]
}
```

**Migration notes:**
- IMS hierarchical segments map naturally to nested documents
- IMS secondary indexes map to MongoDB/DocumentDB secondary indexes
- IMS `GU` (Get Unique) = `findOne()`, `GN` (Get Next) = cursor iteration
- Referential integrity must move to the application layer — document stores do not enforce foreign keys

---

## 4. Stored Procedures to API Layer + Application Logic

### 4.1 Business Logic in Stored Procedures

**Legacy (Oracle PL/SQL — common in EBS):**
```sql
CREATE OR REPLACE PROCEDURE process_employee_transfer(
    p_emp_id IN NUMBER,
    p_new_dept IN NUMBER,
    p_transfer_date IN DATE
) AS
BEGIN
    UPDATE employees SET department_id = p_new_dept WHERE employee_id = p_emp_id;
    INSERT INTO transfer_history (emp_id, old_dept, new_dept, transfer_date)
        SELECT p_emp_id, department_id, p_new_dept, p_transfer_date
        FROM employees WHERE employee_id = p_emp_id;
    -- Nested business rules, exception handling, notifications...
    COMMIT;
END;
```

**Modern (Application Layer + API):**
```python
# Python (FastAPI example)
@app.post("/api/v1/employees/{emp_id}/transfer")
async def transfer_employee(emp_id: int, request: TransferRequest):
    async with db.transaction():
        old_dept = await db.fetchval(
            "SELECT department_id FROM employees WHERE employee_id = $1", emp_id
        )
        await db.execute(
            "UPDATE employees SET department_id = $1 WHERE employee_id = $2",
            request.new_dept_id, emp_id
        )
        await db.execute(
            "INSERT INTO transfer_history (emp_id, old_dept, new_dept, transfer_date) "
            "VALUES ($1, $2, $3, $4)",
            emp_id, old_dept, request.new_dept_id, request.transfer_date
        )
    await notify_hr_system(emp_id, request)
    return {"status": "transferred", "employee_id": emp_id}
```

**Migration notes:**
- Each stored procedure becomes an API endpoint or service method
- Transaction management moves from the database (`COMMIT`/`ROLLBACK`) to the application layer
- Business rules become testable application code (unit tests, integration tests)
- Notifications and side effects move to event-driven patterns (message queues, webhooks)

---

## 5. Triggers to Event-Driven Application Logic

### 5.1 Audit/Change Tracking Triggers

**Legacy (Oracle/PeopleSoft pattern):**
```sql
-- db-schema-corpus/oracle/peoplesoft-stored-procedures/ps_job_delete_trigger.sql
CREATE OR REPLACE TRIGGER ps_job_delete_trigger AFTER DELETE ON ps_job
FOR EACH ROW
DECLARE
    operationcode VARCHAR2(20);
    entitykey     VARCHAR2(30);
BEGIN
    IF deleting THEN
        operationcode := '2';
        entitykey := :old.emplid;
    END IF;
    UPDATE oag_entity_changes oec
    SET oec.timestamp = current_timestamp
    WHERE oec.opcode = operationcode AND oec.key = entitykey;
    IF SQL%rowcount = 0 THEN
        INSERT INTO oag_entity_changes VALUES (entitykey, operationcode, current_timestamp);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION ALERT!!!');
END;
```

**Modern (Event-Driven with Application Logic):**
```python
# Application-layer change tracking
class EmployeeService:
    async def delete_employee(self, emp_id: str):
        async with self.db.transaction():
            await self.db.execute("DELETE FROM ps_job WHERE emplid = $1", emp_id)
            await self.event_bus.publish("employee.deleted", {
                "entity_key": emp_id,
                "operation": "DELETE",
                "timestamp": datetime.utcnow().isoformat()
            })

# Event consumer handles change tracking
class ChangeTrackingConsumer:
    async def handle_entity_change(self, event):
        await self.db.execute(
            "INSERT INTO entity_changes (entity_key, operation, changed_at) "
            "VALUES ($1, $2, $3) "
            "ON CONFLICT (entity_key, operation) DO UPDATE SET changed_at = $3",
            event["entity_key"], event["operation"], event["timestamp"]
        )
```

**Migration notes:**
- Triggers hide business logic in the database — move to explicit application-layer event handlers
- `EXCEPTION WHEN OTHERS THEN` with `dbms_output` provides no real error handling — replace with structured logging and alerting
- `UPSERT` pattern (`INSERT ... ON CONFLICT`) replaces the legacy `UPDATE` + check `SQL%rowcount` + `INSERT` pattern
- Event-driven architecture allows multiple consumers to react to changes independently

---

## 6. Database Links to API Orchestration

### 6.1 Cross-Database Joins via DB Links

**Legacy (Oracle DB Links):**
```sql
-- Direct cross-database query via DB link
SELECT e.employee_name, d.department_name, p.project_budget
FROM employees e
JOIN departments@hr_db d ON e.dept_id = d.dept_id
JOIN projects@project_db p ON e.current_project = p.project_id
WHERE e.location = 'DC';
```

**Modern (API Orchestration):**
```python
# API orchestration replaces cross-database joins
async def get_employee_details(location: str):
    employees = await hr_api.get("/employees", params={"location": location})
    dept_ids = {e["dept_id"] for e in employees}
    project_ids = {e["current_project"] for e in employees}

    departments = await hr_api.get("/departments", params={"ids": list(dept_ids)})
    projects = await project_api.get("/projects", params={"ids": list(project_ids)})

    dept_map = {d["dept_id"]: d for d in departments}
    proj_map = {p["project_id"]: p for p in projects}

    return [
        {
            "employee_name": e["employee_name"],
            "department_name": dept_map[e["dept_id"]]["department_name"],
            "project_budget": proj_map[e["current_project"]]["project_budget"]
        }
        for e in employees
    ]
```

**Migration notes:**
- DB links create tight coupling between database instances — a failure in one database breaks queries in another
- API orchestration introduces network latency but provides fault isolation, independent scaling, and versioning
- For performance-critical joins, consider a read-replica or materialized view within a single database instead of cross-database links
- Use GraphQL or BFF (Backend-for-Frontend) patterns when clients need data from multiple services

---

## 7. Materialized Views to Caching + Query Optimization

### 7.1 Materialized Views for Reporting

**Legacy (Oracle Materialized Views):**
```sql
CREATE MATERIALIZED VIEW mv_department_summary
REFRESH COMPLETE ON DEMAND
AS
SELECT d.department_name,
       COUNT(e.employee_id) AS headcount,
       AVG(e.salary) AS avg_salary,
       SUM(p.budget) AS total_project_budget
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
JOIN projects p ON e.current_project = p.project_id
GROUP BY d.department_name;

-- Refreshed nightly via DBMS_MVIEW.REFRESH
```

**Modern (Application-Layer Caching + Optimized Queries):**
```python
# Option 1: Application-level cache (Redis)
@cache(ttl=3600, key="dept_summary:{dept_name}")
async def get_department_summary(dept_name: str):
    return await db.fetch("""
        SELECT d.department_name,
               COUNT(e.employee_id) AS headcount,
               AVG(e.salary) AS avg_salary,
               SUM(p.budget) AS total_project_budget
        FROM departments d
        JOIN employees e ON d.dept_id = e.dept_id
        JOIN projects p ON e.current_project = p.project_id
        WHERE d.department_name = $1
        GROUP BY d.department_name
    """, dept_name)
```

```sql
-- Option 2: PostgreSQL materialized view (if staying in-database)
CREATE MATERIALIZED VIEW mv_department_summary AS
SELECT d.department_name,
       COUNT(e.employee_id) AS headcount,
       AVG(e.salary) AS avg_salary,
       SUM(p.budget) AS total_project_budget
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
JOIN projects p ON e.current_project = p.project_id
GROUP BY d.department_name;

-- Refresh on schedule via pg_cron or application scheduler
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_department_summary;
```

**Migration notes:**
- PostgreSQL supports `MATERIALIZED VIEW` natively — direct migration is possible for simpler cases
- For high-frequency refresh needs, application-layer caching (Redis, Memcached) provides more control over invalidation
- `REFRESH MATERIALIZED VIEW CONCURRENTLY` in PostgreSQL allows reads during refresh (requires a unique index)
- Consider event-driven cache invalidation instead of scheduled refresh for near-real-time requirements

---

## Quick Reference: Pattern Migration Summary

| Legacy Pattern | Modern Equivalent | Complexity |
|---------------|-------------------|-----------|
| Oracle PL/SQL packages | PostgreSQL functions or application logic | Medium |
| Oracle custom types | Application-layer data classes / DB tables | Medium |
| COBOL fixed-length records | Normalized relational tables | High |
| COBOL REDEFINES | Table-per-type or JSONB columns | High |
| VSAM KSDS | DynamoDB / indexed PostgreSQL table | Medium |
| IMS hierarchical | DocumentDB/MongoDB nested documents | High |
| Stored procedure business logic | API endpoints + service layer | Medium |
| Database triggers (audit) | Event-driven application logic | Medium |
| Database links (cross-DB joins) | API orchestration / BFF pattern | High |
| Materialized views | Application caching + PostgreSQL mat views | Low–Medium |
| Oracle grants + synonyms | PostgreSQL schemas + search_path | Low |
| Oracle-specific SQL syntax | PostgreSQL-compatible SQL | Low |
