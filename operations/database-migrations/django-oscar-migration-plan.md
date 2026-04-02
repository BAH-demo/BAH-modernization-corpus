# Django Oscar Database Migration Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Django Oscar |
| **Source Database** | PostgreSQL 12.x |
| **Target Database** | PostgreSQL 14.x+ (modernized) |
| **Estimated Records** | ~5M+ across 100+ tables |
| **Estimated Duration** | 4-6 hours (full migration) |

---

## 1. Migration Strategy

### 1.1 Approach: Django-Managed Migration

Django Oscar uses Django's ORM and migration framework. The database schema is defined by Django models and migrations.

```
Phase 1: Model and migration audit (Week 1)
Phase 2: Schema migration to target (Week 2)
Phase 3: Data migration (Week 2-3)
Phase 4: Media file sync (Week 3)
Phase 5: Validation and cutover (Weekend)
```

### 1.2 Key Challenges

| Challenge | Mitigation |
|-----------|-----------|
| Django migration history | Preserve django_migrations table |
| Custom Oscar overrides | Document all forked apps |
| Celery task results | Migrate or purge old results |
| Session data | Let sessions expire naturally |
| Payment data (PCI) | Special handling for card tokens |
| Media files (product images) | Sync separately |

### 1.3 Core Table Groups (Django Oscar Apps)

| App | Key Tables | Est. Records |
|-----|-----------|--------------|
| catalogue | catalogue_product, catalogue_category, catalogue_productimage | ~50K |
| order | order_order, order_line, order_shippingaddress | ~500K |
| basket | basket_basket, basket_line | ~200K |
| partner | partner_partner, partner_stockrecord | ~20K |
| customer | customer_email, auth_user | ~100K |
| payment | payment_source, payment_transaction | ~300K |
| offer | offer_conditionaloffer, offer_benefit, offer_condition | ~5K |
| voucher | voucher_voucher, voucher_voucherapplication | ~50K |
| shipping | shipping_weightband, shipping_weightbased | ~1K |
| analytics | analytics_productrecord, analytics_userrecord | ~500K |
| reviews | reviews_productreview | ~50K |
| wishlists | wishlists_wishlist, wishlists_line | ~10K |

---

## 2. Pre-Migration Steps

1. Run pre-migration checks (see `django-oscar-pre-migration-checks.sql`)
2. Full database backup
3. Record Django migration state: `python manage.py showmigrations`
4. Document custom/forked Oscar apps
5. Inventory media files
6. Verify PCI data handling procedures
7. Test in staging

---

## 3. Migration Execution

### 3.1 Database Migration

```bash
#!/bin/bash
# Full dump/restore (simplest for Django)
pg_dump -Fc -U oscar -d oscar_production -f oscar_full.dump
createdb -U oscar oscar_target
pg_restore -U oscar -d oscar_target --no-owner oscar_full.dump

# Verify Django migrations are consistent
cd /opt/oscar
python manage.py showmigrations --database target
python manage.py migrate --database target --fake-initial
```

### 3.2 Media Files

```bash
# Sync product images and uploads
rsync -av --progress /opt/oscar/media/ /opt/oscar-new/media/
```

### 3.3 Modernization Enhancements

```sql
-- Add indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_order_date_placed ON order_order(date_placed);
CREATE INDEX IF NOT EXISTS idx_order_user ON order_order(user_id);
CREATE INDEX IF NOT EXISTS idx_product_upc ON catalogue_product(upc);
CREATE INDEX IF NOT EXISTS idx_line_order ON order_line(order_id);
CREATE INDEX IF NOT EXISTS idx_basket_owner ON basket_basket(owner_id);

-- Add partitioning for large tables (optional)
-- Consider partitioning order_order by date_placed for large datasets
```

---

## 4. Post-Migration Validation

1. Run post-migration checks (see `django-oscar-post-migration-checks.sql`)
2. Run Django system checks: `python manage.py check --database target`
3. Verify product catalog browsing
4. Test checkout flow
5. Verify order history
6. Check payment processing
7. Verify media file access (product images)

---

## 5. Rollback Plan

```
1. Stop Django Oscar on target
2. Revert DATABASE settings in Django settings.py
3. Restart application
4. Verify functionality
```
