# Odoo Database Migration Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Odoo |
| **Source Database** | PostgreSQL 12.x |
| **Target Database** | PostgreSQL 14.x+ (modernized) |
| **Estimated Records** | ~20M+ across 500+ tables |
| **Estimated Duration** | 12-16 hours (full migration) |

---

## 1. Migration Strategy

### 1.1 Approach: Odoo Module-Aware Migration

Odoo's ORM creates and manages database schema through module installation. Migration must respect Odoo's module dependency chain.

```
Phase 1: Module inventory and dependency mapping (Week 1)
Phase 2: Base module schema migration (Week 2)
Phase 3: Data migration by module group (Week 3-4)
Phase 4: Custom module migration (Week 5)
Phase 5: Filestore migration (Week 5)
Phase 6: Validation and cutover (Week 6)
```

### 1.2 Key Challenges

| Challenge | Mitigation |
|-----------|-----------|
| ORM-managed schema (ir.model) | Export schema via Odoo, not raw DDL |
| Module dependencies (ir.module.module) | Migrate in dependency order |
| Computed/stored fields | Recompute after migration |
| File attachments (ir.attachment) | Migrate filestore separately |
| Multi-company data isolation | Verify company_id integrity |
| Translations (ir.translation) | Migrate with base data |
| Custom fields (ir.model.fields) | Map custom field definitions |

### 1.3 Module Groups for Migration Order

| Priority | Module Group | Key Tables | Est. Records |
|----------|-------------|------------|--------------|
| 1 | Base (base, ir) | ir_model, ir_model_fields, ir_module_module | ~100K |
| 2 | Auth (res) | res_users, res_partner, res_company | ~200K |
| 3 | Accounting | account_move, account_move_line, account_journal | ~5M |
| 4 | Sales | sale_order, sale_order_line | ~500K |
| 5 | Purchase | purchase_order, purchase_order_line | ~200K |
| 6 | Inventory | stock_move, stock_quant, stock_picking | ~2M |
| 7 | HR | hr_employee, hr_contract, hr_payslip | ~100K |
| 8 | CRM | crm_lead, calendar_event | ~500K |
| 9 | Website/E-commerce | website, product_template | ~50K |
| 10 | Custom Addons | varies | varies |

### 1.4 Data Type Mapping

| Odoo Field Type | PostgreSQL Type | Notes |
|----------------|-----------------|-------|
| Char | VARCHAR(n) | Length from field definition |
| Text | TEXT | |
| Integer | INTEGER | |
| Float | DOUBLE PRECISION | |
| Monetary | NUMERIC(precision) | Currency precision |
| Boolean | BOOLEAN | |
| Date | DATE | |
| Datetime | TIMESTAMP WITHOUT TIME ZONE | Odoo stores UTC |
| Binary | BYTEA or filestore | Depending on attachment_use |
| Many2one | INTEGER (FK) | |
| One2many | (reverse FK) | No column |
| Many2many | Junction table | ir_model_relation |
| Selection | VARCHAR | Stored as key string |
| Html | TEXT | HTML content |
| Reference | VARCHAR | 'model,id' format |

---

## 2. Pre-Migration Steps

1. Run pre-migration checks (see `odoo-pre-migration-checks.sql`)
2. Full database backup: `pg_dump -Fc odoo_production`
3. Filestore backup: `tar czf filestore.tar.gz /opt/odoo/.local/share/Odoo/filestore/`
4. Document installed modules: `SELECT name, state FROM ir_module_module WHERE state = 'installed'`
5. Record sequence values for all models
6. Verify no pending module upgrades
7. Test migration in staging environment

---

## 3. Migration Execution

### 3.1 Full Database Migration (Recommended for Odoo)

```bash
#!/bin/bash
# For Odoo, a full pg_dump/pg_restore is usually the safest approach
# since Odoo manages its own schema

# Dump source
pg_dump -Fc -U odoo -d odoo_production -f odoo_full.dump

# Restore to target
createdb -U odoo odoo_target
pg_restore -U odoo -d odoo_target --no-owner --no-acl odoo_full.dump

# Apply modernization changes
psql -U odoo -d odoo_target -f odoo_modernization_patches.sql
```

### 3.2 Post-Restore Modernization

```sql
-- Convert datetime columns to TIMESTAMPTZ where appropriate
ALTER TABLE sale_order ALTER COLUMN date_order TYPE TIMESTAMPTZ;
ALTER TABLE account_move ALTER COLUMN date TYPE DATE;  -- Keep as DATE

-- Add missing indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_account_move_line_account
    ON account_move_line(account_id);
CREATE INDEX IF NOT EXISTS idx_stock_move_product
    ON stock_move(product_id);
CREATE INDEX IF NOT EXISTS idx_sale_order_partner
    ON sale_order(partner_id);

-- Update statistics
ANALYZE;
```

### 3.3 Filestore Migration

```bash
# Sync filestore
rsync -av /opt/odoo/.local/share/Odoo/filestore/odoo_production/ \
    /opt/odoo-new/.local/share/Odoo/filestore/odoo_target/

# Verify attachment references
psql -U odoo -d odoo_target -c "
    SELECT count(*) AS total_attachments,
           count(store_fname) AS filestore_attachments,
           count(*) - count(store_fname) AS db_attachments
    FROM ir_attachment;"
```

---

## 4. Post-Migration Validation

1. Run post-migration checks (see `odoo-post-migration-checks.sql`)
2. Start Odoo against target database in test mode
3. Verify module list matches source
4. Run Odoo module upgrade: `./odoo-bin -d odoo_target -u all --stop-after-init`
5. Verify accounting balances
6. Test login for sample users
7. Verify cron jobs execute correctly
8. Check filestore attachment access

---

## 5. Rollback Plan

```
1. Stop Odoo service
2. Revert connection to source database in odoo.conf
3. Restart Odoo
4. Verify functionality
```
