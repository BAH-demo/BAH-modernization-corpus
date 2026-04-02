# Comprehensive UAT Benchmarks for Legacy Modernization Corpus

> **Purpose**: This document captures the complete functional behavior of all 13 operationalized legacy systems in the BAH Modernization Corpus. It serves as the definitive acceptance criteria for any modernized or refactored replacement. A modernized system MUST demonstrate functional equivalence across every benchmark defined herein.

> **Methodology**: Each system was analyzed through (1) complete source code review of models, controllers, views, configuration, and business logic; (2) database schema inspection including seed data; (3) live application navigation where services are running; and (4) documentation and fixture analysis.

---

## Table of Contents

1. [Django Oscar (E-Commerce Platform)](#1-django-oscar-e-commerce-platform)
2. [Mezzanine (Content Management System)](#2-mezzanine-content-management-system)
3. [Odoo (Enterprise Resource Planning)](#3-odoo-enterprise-resource-planning)
4. [Apache OFBiz (Enterprise Resource Planning)](#4-apache-ofbiz-enterprise-resource-planning)
5. [B2CWeb (Chinese E-Commerce)](#5-b2cweb-chinese-e-commerce)
6. [Monolith Enterprise (Spring REST API)](#6-monolith-enterprise-spring-rest-api)
7. [CFWheels (CFML MVC Framework)](#7-cfwheels-cfml-mvc-framework)
8. [Umbraco CMS (.NET Content Management)](#8-umbraco-cms-net-content-management)
9. [NASTRAN-95 (Finite Element Analysis)](#9-nastran-95-finite-element-analysis)
10. [Apollo-11 AGC (Guidance Computer)](#10-apollo-11-agc-guidance-computer)
11. [CICS Banking (COBOL Transaction System)](#11-cics-banking-cobol-transaction-system)
12. [Nuxeo (Content Services Platform)](#12-nuxeo-content-services-platform)
13. [Alfresco (Enterprise Content Management)](#13-alfresco-enterprise-content-management)

---

## 1. Django Oscar (E-Commerce Platform)

**Technology**: Python 3.12, Django 4.2, SQLite, Whoosh search  
**Port**: 8000  
**LOC**: ~50,000+ (framework + sandbox)

### 1.1 Data Model (98 database tables)

#### Core Commerce Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `catalogue_product` | 17 | 11 products | Products with title, slug, description, structure (standalone/parent/child), UPC, rating, date_created, date_updated, is_discountable, is_public |
| `catalogue_productclass` | 5 | 1 class | Product types defining shipping/stock tracking requirements; name, slug, requires_shipping, track_stock |
| `catalogue_category` | 15 | 1 category | Hierarchical categories (MP_Node tree); name, code, description, long_description, meta_title, meta_description, image, slug, is_public, ancestors_are_public, exclude_from_menu |
| `catalogue_productattribute` | 7 | 1 attribute | Dynamic product attributes linked to product classes |
| `catalogue_productattributevalue` | 15 | 8 values | Attribute values supporting: text, integer, boolean, richtext, float, date, datetime, file, image, entity, multi_option |
| `catalogue_attributeoption` | 4 | 3 options | Predefined attribute choices |
| `catalogue_attributeoptiongroup` | 3 | 1 group | Groups of attribute options |
| `catalogue_productcategory` | 3 | 3 mappings | Product-to-category assignments |
| `catalogue_productimage` | 7 | 0 | Product images with ordering and caption |
| `catalogue_productrecommendation` | 4 | 0 | Product-to-product recommendations with ranking |
| `catalogue_option` | 8 | 0 | Configurable product options (e.g., gift wrapping) |
| `partner_partner` | 3 | 1 partner | Fulfillment partners with code and name |
| `partner_stockrecord` | 11 | 5 records | Stock records: partner_sku, price_currency, price, num_in_stock, num_allocated, low_stock_threshold, date_created, date_updated |
| `partner_partneraddress` | 14 | 0 | Partner warehouse/office addresses |
| `partner_stockalert` | 6 | 0 | Low stock threshold alerts |

#### Customer & Account Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `auth_user` | 11 | 0 | Django auth users |
| `customer_productalert` | 10 | 0 | Product back-in-stock alerts: status (Unconfirmed/Active/Cancelled/Closed), key, email, date_created/confirmed/cancelled/closed |
| `address_useraddress` | 22 | 0 | Customer addresses: title, first_name, last_name, line1-4, state, postcode, country, phone_number, notes, num_orders_as_billing/shipping, is_default_for_billing/shipping |
| `address_country` | 7 | 249 countries | ISO country list with display_order, is_shipping_country, printable_name |
| `wishlists_wishlist` | 6 | 0 | Wishlists: name, key, visibility (Private/Shared/Public), date_created |
| `wishlists_line` | 5 | 0 | Wishlist line items with quantity |
| `wishlists_wishlistsharedemail` | 3 | 0 | Shared wishlist email tracking |

#### Basket & Checkout Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `basket_basket` | 6 | 0 | Shopping baskets: owner, status (Open/Merged/Saved/Frozen/Submitted), date_created/merged/submitted |
| `basket_line` | 12 | 0 | Basket line items: product, stockrecord, quantity, price_currency, price_incl_tax, price_excl_tax, date_created, date_updated |
| `basket_lineattribute` | 4 | 0 | Basket line custom attributes |
| `basket_basket_vouchers` | 3 | 0 | Vouchers applied to baskets |

#### Order Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `order_order` | 19 | 0 | Orders: number, basket, user, billing_address, currency, total_incl_tax, total_excl_tax, shipping_incl_tax, shipping_excl_tax, shipping_method, shipping_code, status, guest_email, date_placed |
| `order_line` | 22 | 0 | Order lines: product, stockrecord, partner, partner_name, partner_sku, partner_line_reference, partner_line_notes, quantity, line_price_incl/excl_tax, unit_price_incl/excl_tax, status |
| `order_lineattribute` | 5 | 0 | Order line custom attributes |
| `order_lineprice` | 9 | 0 | Historical line price records |
| `order_billingaddress` | 13 | 0 | Billing address snapshots |
| `order_shippingaddress` | 15 | 0 | Shipping address snapshots |
| `order_orderdiscount` | 10 | 0 | Applied order-level discounts |
| `order_orderlinediscount` | 5 | 0 | Applied line-level discounts |
| `order_ordernote` | 7 | 0 | Admin/customer order notes |
| `order_orderstatuschange` | 5 | 0 | Order status change audit trail |
| `order_communicationevent` | 4 | 0 | Communication events linked to orders |
| `order_paymentevent` | 7 | 0 | Payment events (authorization, capture, refund) |
| `order_paymenteventtype` | 3 | 0 | Payment event type definitions |
| `order_paymenteventquantity` | 4 | 0 | Line quantities per payment event |
| `order_shippingevent` | 5 | 0 | Shipping events (dispatched, returned) |
| `order_shippingeventtype` | 3 | 0 | Shipping event type definitions |
| `order_shippingeventquantity` | 4 | 0 | Line quantities per shipping event |
| `order_surcharge` | 7 | 0 | Order surcharges |

#### Offer & Voucher Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `offer_conditionaloffer` | 21 | 0 | Conditional offers: name, slug, description, offer_type (Site/Voucher/User/Session), exclusive, status (Open/Suspended/Consumed), condition, benefit, priority, start/end_datetime, max_global/user/basket/discount applications, total_discount, num_applications, num_orders |
| `offer_benefit` | 6 | 0 | Benefits: type (Percentage/Absolute/Multibuy/FixedPrice/ShippingAbsolute/ShippingFixed/ShippingPercentage), value, max_affected_items, range |
| `offer_condition` | 5 | 0 | Conditions: type (Count/Value/Coverage), value, range |
| `offer_range` | 8 | 0 | Product ranges for offers |
| `offer_rangeproduct` | 4 | 0 | Products in ranges |
| `voucher_voucher` | 11 | 0 | Vouchers: name, code, usage (Single/Multi/Once per customer), start/end_datetime, num_basket_additions, num_orders, total_discount |
| `voucher_voucherset` | 8 | 0 | Voucher batch sets |
| `voucher_voucherapplication` | 5 | 0 | Voucher usage records |

#### Payment Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `payment_source` | 9 | 0 | Payment sources: order, source_type, currency, amount_allocated/debited/refunded, reference, label |
| `payment_sourcetype` | 3 | 0 | Payment source types (e.g., Credit Card, PayPal) |
| `payment_transaction` | 7 | 0 | Transactions: source, txn_type, amount, reference, status, date_created |
| `payment_bankcard` | 7 | 0 | Stored bank card tokens |

#### Shipping Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `shipping_orderanditemcharges` | 7 | 0 | Shipping by order+item: price_per_order, price_per_item, free_shipping_threshold |
| `shipping_weightbased` | 5 | 0 | Weight-based shipping methods |
| `shipping_weightband` | 4 | 0 | Weight bands with charge amounts |

#### Analytics Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `analytics_productrecord` | 6 | 1 record | Product analytics: num_views, num_basket_additions, num_purchases, score |
| `analytics_userrecord` | 9 | 0 | User analytics: num_product_views, num_basket_additions, num_orders, num_order_lines, num_order_items, total_spent, date_last_order |
| `analytics_userproductview` | 4 | 0 | User-product view tracking |
| `analytics_usersearch` | 4 | 0 | User search query tracking |

#### Communication Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `communication_communicationeventtype` | 10 | 0 | Event types: code, name, category (Order/User), email_subject_template, email_body_template, email_body_html_template, sms_template |
| `communication_email` | 7 | 0 | Sent email records |
| `communication_notification` | 8 | 0 | User notifications |

#### Reviews Entity

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `reviews_productreview` | 14 | 0 | Product reviews with score, title, body, status (pending/approved/rejected), name, email, homepage |
| `reviews_vote` | 5 | 0 | Review helpfulness votes |

### 1.2 Business Rules & Configuration

#### Order Status Pipeline
```
Pending → Being processed → Complete
Pending → Cancelled
Being processed → Cancelled
```

#### Line Status Cascade
| Order Status | Line Status |
|-------------|-------------|
| Being processed | Being processed |
| Cancelled | Cancelled |
| Complete | Shipped |

#### Offer System Rules
- Offer types: Site-wide, Voucher-triggered, User-specific, Session-specific
- Benefit types: Percentage discount, Absolute discount, Multibuy, Fixed price, Shipping discounts
- Condition types: Count-based, Value-based, Coverage-based
- Exclusivity: Offers can be exclusive or combinable
- Priority ordering for conflict resolution

#### Basket Rules
- Basket statuses: Open, Merged, Saved, Frozen, Submitted
- Anonymous baskets supported (nullable owner)
- Vouchers can be applied to baskets
- Quantity validation with `max_allowed_quantity` and `is_quantity_allowed`
- Line attributes for customization

#### Payment Processing Rules
- Source tracking: amount_allocated → amount_debited → amount_refunded
- Transaction types: allocation, debit, refund with deferred transaction support
- Balance calculation: allocated - debited - refunded

#### Stock Management Rules
- Stock tracking per partner per product (StockRecord)
- Net stock level = num_in_stock - num_allocated
- Low stock threshold alerts
- Allocation tracking for reserved stock

### 1.3 Internationalization
21 supported languages: Arabic (ar), Catalan (ca), Czech (cs), Danish (da), German (de), British English (en-gb), Greek (el), Spanish (es), Finnish (fi), French (fr), Italian (it), Korean (ko), Dutch (nl), Polish (pl), Portuguese (pt), Brazilian Portuguese (pt-br), Romanian (ro), Russian (ru), Slovak (sk), Ukrainian (uk), Simplified Chinese (zh-cn)

### 1.4 Search System
- Backend: Whoosh (full-text search)
- Signal processor: RealtimeSignalProcessor (index updates on save)
- Search result types: products, categories

### 1.5 Fixture Data (Seed Data Benchmarks)

| Fixture | Records | Content |
|---------|---------|---------|
| auth.json | 2 | Superuser accounts |
| child_products.json | 35 | Child product variants |
| comms.json | 3 | Communication event types |
| multi-stockrecord-product.json | 8 | Products with multiple stock records |
| offers.json | 10 | Conditional offers and vouchers |
| order-events.json | 6 | Payment and shipping event types |
| orders.json | 6 | Sample orders |
| pages.json | 1 | Flat pages |
| ranges.json | 2 | Product ranges |
| books.computers-in-fiction.csv | 86 lines | Book catalogue data |
| books.essential.csv | 82 lines | Book catalogue data |
| books.hacking.csv | 33 lines | Book catalogue data |
| range-products.csv | 6 lines | Range product assignments |

### 1.6 UAT Test Cases

#### TC-OSC-001: Product Catalogue Browsing
- **Precondition**: Database seeded with fixture data
- **Steps**: Navigate to homepage → Browse catalogue
- **Expected**: 11+ products displayed with title, price, and images; category navigation works; product detail pages show description, attributes, stock status, and pricing

#### TC-OSC-002: Product Search
- **Steps**: Enter search query in search box → Submit
- **Expected**: Whoosh full-text search returns relevant products; results show product title, price, rating

#### TC-OSC-003: Add to Basket
- **Steps**: View product detail → Click "Add to basket"
- **Expected**: Product added to basket; basket badge count updates; basket page shows product, quantity, unit price, line total

#### TC-OSC-004: Basket Quantity Management
- **Steps**: In basket page → Modify quantity → Update
- **Expected**: Line total recalculates; basket total updates; quantity validation enforced (max_allowed_quantity)

#### TC-OSC-005: Voucher Application
- **Steps**: In basket → Enter voucher code → Apply
- **Expected**: Valid voucher discounts applied; invalid/expired/exceeded vouchers show error; voucher usage tracked

#### TC-OSC-006: Checkout Workflow (Guest)
- **Steps**: Basket → Checkout → Enter shipping address → Select shipping method → Enter payment → Place order
- **Expected**: Guest email captured; shipping address validated; order created with status "Pending"; basket status set to "Submitted"

#### TC-OSC-007: Checkout Workflow (Registered User)
- **Steps**: Login → Add to basket → Checkout → Select saved address → Place order
- **Expected**: Saved addresses available for selection; order linked to user account; order visible in order history

#### TC-OSC-008: Order Status Transitions
- **Steps**: Admin sets order status through pipeline
- **Expected**: Only valid transitions allowed per pipeline; line statuses cascade correctly; status change audit trail created

#### TC-OSC-009: Customer Account Management
- **Steps**: Register → Login → View profile → View order history → Manage addresses → Manage email preferences
- **Expected**: Registration with email (no username); login; profile edit; order history with detail view; address CRUD; notification preferences

#### TC-OSC-010: Wishlist Operations
- **Steps**: Login → Add product to wishlist → View wishlist → Share wishlist
- **Expected**: Wishlist created; products added with quantity; visibility settings (Private/Shared/Public); share via email

#### TC-OSC-011: Product Alerts
- **Steps**: View out-of-stock product → Register for alert
- **Expected**: Alert created with Unconfirmed status; confirmation email sent; status transitions: Unconfirmed → Active → Closed/Cancelled

#### TC-OSC-012: Dashboard (Admin)
- **Steps**: Login as admin → Navigate dashboard sections
- **Expected**: Dashboard home with stats; Catalogue management (products, categories, product types); Order management; Customer management; Offer management; Content management; Reports; Voucher management

#### TC-OSC-013: Offer Engine
- **Steps**: Admin creates conditional offer with condition and benefit → Customer shops
- **Expected**: Offers evaluated at basket level; conditions checked (count/value/coverage); benefits applied; exclusive offers prevent stacking; priority ordering respected

#### TC-OSC-014: Internationalization
- **Steps**: Switch language via URL prefix
- **Expected**: All 21 languages render correctly; URL patterns use i18n_patterns; currency formatting locale-aware

#### TC-OSC-015: Analytics Tracking
- **Steps**: Browse products → Add to basket → Place order
- **Expected**: ProductRecord updated (num_views, num_basket_additions, num_purchases); UserRecord updated; UserProductView logged; UserSearch logged

#### TC-OSC-016: Reviews System
- **Steps**: View product → Submit review → Admin moderates
- **Expected**: Review with score (0-5), title, body; moderation workflow (pending → approved/rejected); anonymous reviews supported; helpfulness voting

---

## 2. Mezzanine (Content Management System)

**Technology**: Python, Django 4.2, SQLite, Mezzanine 9999.dev0  
**Port**: 8001  
**LOC**: ~30,000+

### 2.1 Data Model (35 database tables)

#### Core CMS Entities

| Table | Columns | Seed Data | Description |
|-------|---------|-----------|-------------|
| `pages_page` | 21 | 0 | Page tree: parent (self-referential FK), in_menus, titles, login_required, content_model, slug. Inherits from Orderable + Displayable + ContentTyped |
| `pages_richtextpage` | 2 | 0 | Rich text content pages (extends Page) |
| `pages_link` | 1 | 0 | External/internal link pages (extends Page) |
| `blog_blogpost` | 23 | 0 | Blog posts: categories (M2M), allow_comments, comments, rating, featured_image, related_posts, publish_date, expiry_date, content (RichText), description |
| `blog_blogcategory` | 4 | 0 | Blog categories: title, slug |
| `forms_form` | 9 | 0 | User-built forms (extends Page): button_text, response, send_email, email_from, email_copies, email_subject, email_message |
| `forms_field` | 11 | 0 | Form fields: label, field_type, required, visible, choices, default, placeholder_text, help_text, css_class |
| `forms_formentry` | 3 | 0 | Form submission records |
| `forms_fieldentry` | 4 | 0 | Individual field values per submission |
| `galleries_gallery` | 3 | 0 | Image galleries (extends Page): zip_import for bulk image upload |
| `galleries_galleryimage` | 5 | 0 | Gallery images: file, description, ordering |
| `generic_keyword` | 4 | 0 | SEO keywords: title, slug, site |
| `generic_assignedkeyword` | 5 | 0 | Keyword assignments to content (GenericForeignKey) |
| `generic_rating` | 6 | 0 | Content ratings: value, rating_date, content_type, object_pk |
| `generic_threadedcomment` | 6 | 0 | Threaded comments on any content type |
| `conf_setting` | 4 | 0 | Dynamic configuration settings |
| `core_sitepermission` | 2 | 0 | Per-site user permissions |
| `django_redirect` | 4 | 0 | URL redirects |
| `django_comments` | 13 | 0 | Django comments framework |
| `django_comment_flags` | 5 | 0 | Comment moderation flags |

### 2.2 Core Abstract Models & Patterns

#### SiteRelated
- All content is scoped to a Django Site (multi-site support)
- Automatic site assignment on first save

#### Slugged (extends SiteRelated)
- Auto-generating slugs from title
- Unique slug enforcement per site

#### Displayable (extends Slugged)
- Publishing workflow: publish_date, expiry_date, status (Draft/Published)
- SEO: _meta_title, description (meta description)
- Short URL support

#### RichText
- Rich text content field with HTML
- Tag auto-closing for safety

#### Orderable
- Drag-and-drop ordering with `_order` field

#### ContentTyped
- Polymorphic content type tracking for Page subclasses

### 2.3 Business Rules

#### Page Tree Rules
- Hierarchical parent-child page structure
- Menu inclusion configurable per page (`in_menus`)
- Login requirement per page
- Ordering within parent scope
- Slug-based URL routing

#### Blog Rules
- Posts organized by categories (many-to-many)
- Date-based URL formats configurable (year/month/day)
- Related posts (self-referential M2M)
- Comments toggleable per post
- Rating system per post
- Featured image support

#### Form Builder Rules
- Dynamic form creation via admin
- Field types: text, textarea, email, checkbox, checkbox list, select, radio, file upload, date, date/time, hidden, number, URL
- Form submission → optional email notification
- CC email list support
- Custom response message after submission

#### Gallery Rules
- Zip file upload → automatic image extraction
- Character encoding detection for filenames
- Image ordering within gallery
- Gallery is a Page type (appears in page tree)

### 2.4 Configuration
- Authentication: MezzanineBackend
- Language: English only (single language)
- Session: Expire at browser close
- Database: SQLite (dev.db)
- Debug: True (development mode)
- File upload permissions: 0o644

### 2.5 UAT Test Cases

#### TC-MEZ-001: Page Management
- **Steps**: Admin → Pages → Create new page → Set title, content, slug → Publish
- **Expected**: Page appears in page tree; accessible via slug URL; shows in configured menus

#### TC-MEZ-002: Page Hierarchy
- **Steps**: Create parent page → Create child page under parent
- **Expected**: Child page URL includes parent slug; page tree shows hierarchy; titles field populated with ancestor chain

#### TC-MEZ-003: Blog Post CRUD
- **Steps**: Admin → Blog → Create post with title, content, categories, featured image → Publish
- **Expected**: Post accessible at dated URL; categories linked; featured image displayed; appears in blog listing

#### TC-MEZ-004: Blog Categories
- **Steps**: Create categories → Assign to posts → Browse by category
- **Expected**: Category pages list associated posts; posts can have multiple categories

#### TC-MEZ-005: Form Builder
- **Steps**: Admin → Pages → Create Form page → Add fields (text, email, select, etc.) → Publish → Submit form as user
- **Expected**: Form renders with configured fields; submission creates FormEntry + FieldEntry records; email sent if configured

#### TC-MEZ-006: Gallery Management
- **Steps**: Create gallery → Upload zip of images → View gallery
- **Expected**: Images extracted from zip; displayed in order; gallery accessible as page

#### TC-MEZ-007: Content Publishing Workflow
- **Steps**: Create content with draft status → Set publish_date in future → Publish
- **Expected**: Draft content not publicly visible; content auto-publishes at publish_date; expired content hidden after expiry_date

#### TC-MEZ-008: SEO Features
- **Steps**: Edit page meta title and description → View page source
- **Expected**: Meta title and description in HTML head; auto-generated slug in URL

#### TC-MEZ-009: Comment System
- **Steps**: Enable comments on blog post → Submit comment as user
- **Expected**: Threaded comments displayed; moderation flags available; comment count tracked

#### TC-MEZ-010: Admin Dashboard
- **Steps**: Login to /admin/
- **Expected**: Pages tree editor; Blog management; Forms management; Galleries; Users; Settings; Redirects

---

## 3. Odoo (Enterprise Resource Planning)

**Technology**: Python 3, PostgreSQL, XML views, JavaScript/OWL frontend  
**Port**: 8069  
**LOC**: ~2,000,000+ (617 addons)

### 3.1 Module Inventory (617 addons)

#### Core Business Modules

| Module | Name | Category | Key Models |
|--------|------|----------|------------|
| `sale` | Sales | Sales | sale.order, sale.order.line |
| `purchase` | Purchase | Purchase | purchase.order, purchase.order.line |
| `account` | Invoicing | Accounting | account.move, account.move.line, account.payment, account.journal, account.tax |
| `stock` | Inventory | Warehouse | stock.picking, stock.move, stock.move.line, stock.quant, stock.location, stock.warehouse, stock.lot |
| `hr` | Employees | Human Resources | hr.employee, hr.department, hr.job, hr.contract.type |
| `crm` | CRM | Sales | crm.lead, crm.stage, crm.team, crm.lost.reason |
| `project` | Project | Project | project.project, project.task, project.task.type, project.milestone |
| `mrp` | Manufacturing | Manufacturing | mrp.production, mrp.bom, mrp.workcenter, mrp.workorder, mrp.routing |
| `website` | Website | Website | website, website.page, website.menu, website.visitor |
| `point_of_sale` | Point of Sale | Sales/POS | pos.config, pos.session, pos.order, pos.payment |
| `fleet` | Fleet | Human Resources | fleet.vehicle, fleet.vehicle.model |
| `hr_holidays` | Time Off | Human Resources | hr.leave, hr.leave.type, hr.leave.allocation |
| `hr_expense` | Expenses | Human Resources | hr.expense, hr.expense.sheet |
| `hr_recruitment` | Recruitment | Human Resources | hr.applicant, hr.recruitment.stage |
| `hr_attendance` | Attendances | Human Resources | hr.attendance |
| `event` | Events | Marketing | event.event, event.registration, event.stage |
| `calendar` | Calendar | Productivity | calendar.event, calendar.attendee |
| `mail` | Discuss | Productivity | mail.message, mail.channel |
| `contacts` | Contacts | Sales | res.partner |
| `delivery` | Delivery | Warehouse | delivery.carrier |
| `gamification` | Gamification | Human Resources | gamification.goal, gamification.challenge |
| `hr_maintenance` | Maintenance | Human Resources | maintenance.request, maintenance.equipment |
| `analytic` | Analytic Accounting | Accounting | account.analytic.account, account.analytic.line |
| `digest` | Digest Emails | Marketing | digest.digest |

#### Localization Modules (100+ l10n_* modules)
- Chart of accounts for 60+ countries (l10n_ae, l10n_ar, l10n_at, l10n_au, l10n_bd, l10n_be, l10n_bg, l10n_bo, l10n_br, l10n_ca, l10n_ch, l10n_ci, l10n_cl, l10n_cn, l10n_co, l10n_cr, l10n_cz, l10n_de, l10n_dk, l10n_ec, l10n_ee, l10n_eg, l10n_es, l10n_et, l10n_fi, l10n_fr, l10n_ge, l10n_gr, l10n_gt, l10n_hk, l10n_hr, l10n_hu, l10n_id, l10n_ie, l10n_il, l10n_in, l10n_it, l10n_jp, l10n_ke, l10n_kr, l10n_lt, l10n_lu, l10n_lv, l10n_ma, l10n_mn, l10n_mx, l10n_my, l10n_nl, l10n_no, l10n_nz, l10n_pe, l10n_ph, l10n_pk, l10n_pl, l10n_pt, l10n_ro, l10n_rs, l10n_sa, l10n_se, l10n_sg, l10n_si, l10n_sk, l10n_th, l10n_tr, l10n_tw, l10n_ua, l10n_uk, l10n_us, l10n_uy, l10n_ve, l10n_vn, l10n_za)
- EDI integrations (l10n_in_edi, l10n_pl_edi, l10n_gr_edi)
- E-invoicing: PEPPOL, UBL/CII formats

#### Authentication & Security
- `auth_ldap`: LDAP authentication
- `auth_oauth`: OAuth2 authentication
- `auth_passkey`: Passkey/WebAuthn authentication
- `auth_totp`: Two-factor TOTP authentication
- `auth_password_policy`: Password complexity rules
- `auth_signup`: Self-service registration
- `auth_timeout`: Session timeout

#### Integration Modules
- `google_calendar`, `google_gmail`, `google_recaptcha`, `google_account`
- `cloud_storage`, `cloud_storage_azure`, `cloud_storage_google`
- `iap`: In-App Purchase framework
- `payment_*`: Payment provider integrations

### 3.2 Scale Metrics

| Metric | Count |
|--------|-------|
| Total addons | 617 |
| Python model files | 3,201 |
| XML view files | 2,173 |
| Python controller files | 482 |
| Supported languages | 92 |
| Countries | 251 |
| Module categories | 20+ (Accounting, Sales, HR, Manufacturing, Website, Marketing, etc.) |

### 3.3 Core Business Rules

#### Sales Pipeline
```
Quotation → Quotation Sent → Sales Order → Locked → Cancelled
```

#### Purchase Pipeline
```
RFQ → RFQ Sent → Purchase Order → Done → Cancelled
```

#### Accounting Rules
- Double-entry bookkeeping
- Journal entries (account.move) with debit/credit lines
- Tax computation engine with Python-based custom taxes
- Multi-currency support
- Reconciliation engine
- Fiscal year/period management
- Payment matching

#### Inventory Rules
- Multi-warehouse, multi-location
- Stock moves between locations
- Lot/serial number tracking
- Reordering rules (stock.orderpoint)
- Putaway strategies
- Package management
- Scrap handling

#### Manufacturing Rules
- Bill of Materials (BOM) with multi-level support
- Work orders with work center routing
- Manufacturing orders with component consumption
- Unbuild operations
- Stock traceability

#### CRM Pipeline
- Lead scoring with frequency analysis
- Stage-based kanban workflow
- Team assignment
- Lost reason tracking
- Recurring revenue plans

### 3.4 UAT Test Cases

#### TC-ODOO-001: Sales Order Workflow
- **Steps**: Create customer → Create quotation → Add products → Confirm → Create invoice → Register payment
- **Expected**: Quotation confirmed to SO; stock picking created; invoice generated; payment reconciled

#### TC-ODOO-002: Purchase Order Workflow
- **Steps**: Create vendor → Create RFQ → Add products → Confirm → Receive goods → Create bill → Pay
- **Expected**: PO confirmed; receipt picking created; vendor bill generated; payment reconciled

#### TC-ODOO-003: Inventory Operations
- **Steps**: Receive goods → Internal transfer → Delivery → Scrap
- **Expected**: Stock moves created; quant levels updated; lot tracking maintained; location accuracy verified

#### TC-ODOO-004: Manufacturing Order
- **Steps**: Create BOM → Create MO → Consume components → Produce finished goods
- **Expected**: Component stock decremented; finished goods incremented; work order time tracked

#### TC-ODOO-005: HR Employee Lifecycle
- **Steps**: Create employee → Assign department/job → Create time off → Approve → Log attendance
- **Expected**: Employee record with all fields; department hierarchy; time off balance updated; attendance tracked

#### TC-ODOO-006: CRM Pipeline
- **Steps**: Create lead → Qualify → Convert to opportunity → Win/Lose
- **Expected**: Lead stage progression; activity scheduling; revenue tracking; lost reason on loss

#### TC-ODOO-007: Accounting Journal Entries
- **Steps**: Create journal entry → Post → Reconcile
- **Expected**: Debit equals credit; posted entries immutable; reconciliation marks matched

#### TC-ODOO-008: Website Builder
- **Steps**: Create website page → Add content blocks → Publish → Configure menu
- **Expected**: Page accessible via URL; menu updated; visitor tracking active

#### TC-ODOO-009: Point of Sale
- **Steps**: Configure POS → Open session → Process sale → Close session
- **Expected**: POS order created; payment recorded; session accounting balanced

#### TC-ODOO-010: Multi-Company / Multi-Currency
- **Steps**: Create second company → Create transaction in foreign currency
- **Expected**: Currency conversion applied; company-scoped data isolation; inter-company transactions

---

## 4. Apache OFBiz (Enterprise Resource Planning)

**Technology**: Java 17, Groovy, XML entity engine, Gradle build  
**Port**: 8443 (HTTPS)  
**LOC**: ~500,000+

### 4.1 Application Modules (11 applications)

| Application | Webapps | Requests | Views | Key Functions |
|-------------|---------|----------|-------|---------------|
| **Accounting** | accounting, ar, ap | 556 | 271 | General Ledger, Accounts Receivable/Payable, Invoicing, Payments, Financial Accounts, Fixed Assets, Budgets, Tax Authorities |
| **Product/Catalog** | catalog, facility | 784 | 273 | Product catalog, Categories, Features, Pricing, Promotions, Facility/Warehouse management, Inventory |
| **Order** | ordermgr | 380 | 153 | Sales orders, Purchase orders, Returns, Quotes, Requirements, Order status tracking |
| **Party** | partymgr | 275 | 112 | Customers, Suppliers, Employees, Contact mechanisms, Party groups, Roles, Classifications |
| **Human Resources** | humanres | 232 | 98 | Employees, Employment, Skills, Qualifications, Recruitment, Training, Leave, Performance |
| **Content** | content | 347 | 134 | Content management, Surveys, Data resources, Web sites, Forums |
| **Manufacturing** | manufacturing | 149 | 66 | Bill of Materials, Manufacturing orders, Routing, Calendars, MRP |
| **Marketing** | marketing, sfa | 146 | 84 | Campaigns, Contact lists, Data sources, Sales Force Automation, Forecasting |
| **Work Effort** | workeffort | 96 | 69 | Projects, Tasks, Time entries, iCalendar, Resource assignments |
| **Common Extensions** | ofbizsetup | 32 | 15 | Initial setup wizard, Organization setup |
| **Web Tools** | webtools | 125 | 79 | Entity data maintenance, Service engine, Cache management, Logging |

### 4.2 Entity Engine (Data Model)

#### Framework Entities

| Source | Entities | View Entities | Description |
|--------|----------|---------------|-------------|
| framework/common | 46 | 11 | Status, enums, geo, notes, periods, UoM |
| framework/security | 11 | 3 | Security groups, permissions, user logins |
| framework/service | 8 | 1 | Service lock, semaphore |
| framework/entity | 11 | 0 | Entity audit, key stores, sequences |
| framework/entityext | 7 | 1 | Entity sync, data import/export |
| framework/webapp | 14 | 0 | Visits, server hits, user agents |
| framework/catalina | 1 | 0 | Catalina session data |

#### Service Engine

| Service Definition File | Service Count | Domain |
|------------------------|---------------|--------|
| product/services.xml | 237 | Product CRUD, search, features |
| party/services.xml | 184 | Party CRUD, contact, roles |
| order/services.xml | 155 | Order creation, status changes |
| product/services_shipment.xml | 141 | Shipment processing |
| product/services_facility.xml | 132 | Facility operations |
| accounting/services_ledger.xml | 132 | GL posting, trial balance |
| common/services.xml | 128 | Email, geo, notes, status |
| workeffort/services.xml | 115 | Project/task management |
| humanres/services.xml | 113 | Employee management |
| accounting/services_paymentmethod.xml | 95 | Payment methods |
| accounting/services_invoice.xml | 86 | Invoice processing |
| marketing/services.xml | 79 | Campaign management |
| accounting/services_finaccount.xml | 76 | Financial accounts |
| product/services_pricepromo.xml | 75 | Pricing and promotions |
| content/services.xml | 75 | Content management |
| order/services_return.xml | 73 | Return processing |
| entityext/services.xml | 72 | Entity sync |
| accounting/services_fixedasset.xml | 69 | Fixed asset tracking |
| order/services_order.xml | 61 | Order services |
| content/services_content.xml | 57 | Content CRUD |

**Total services**: 2,500+ across all definition files

### 4.3 Business Rules

#### Order Lifecycle
```
Created → Approved → Held → Processing → Completed → Cancelled
```

#### Invoice Lifecycle
```
In Process → Approved → Sent → Received → Ready → Paid → Written Off → Cancelled
```

#### Payment Processing
- Payment methods: Credit Card, EFT, Gift Card, Check, Cash
- Gateway integrations: PayPal, Authorize.net, CyberSource, WorldPay, SecurePay, PCCharge, ValueLink
- Financial accounts with deposits/withdrawals

#### Product Management
- Product types: Finished Good, Raw Material, Service, Digital, Asset Usage
- Category hierarchy with rollup
- Feature management with interaction detection
- Pricing engine: base price, promotions, quantity breaks, customer-specific
- Promotion engine with conditions and actions

### 4.4 UAT Test Cases

#### TC-OFB-001: Product Catalog Management
- **Steps**: Admin login (admin/ofbiz) → Catalog → Create category → Create product → Set pricing → Add to category
- **Expected**: Product appears in catalog; pricing applied; category hierarchy navigable

#### TC-OFB-002: Sales Order Processing
- **Steps**: Order Manager → Create order → Add items → Set shipping → Approve → Ship → Invoice → Payment
- **Expected**: Full order lifecycle; inventory decremented; invoice generated; payment applied

#### TC-OFB-003: Party Management
- **Steps**: Party Manager → Create person/company → Add contact info → Assign roles
- **Expected**: Party created with contact mechanisms; roles assigned; searchable

#### TC-OFB-004: Accounting / GL
- **Steps**: Accounting → Create journal entry → Post → Run trial balance
- **Expected**: Debits equal credits; GL balances updated; trial balance report accurate

#### TC-OFB-005: Manufacturing Order
- **Steps**: Manufacturing → Create BOM → Create production run → Issue materials → Complete
- **Expected**: Materials consumed; finished goods produced; routing steps tracked

#### TC-OFB-006: HR Management
- **Steps**: HR → Create employee → Add skills → Create leave → Approve
- **Expected**: Employee record complete; skills tracked; leave balance updated

#### TC-OFB-007: Content Management
- **Steps**: Content → Create content → Associate with data resource → Publish
- **Expected**: Content accessible; data resource linked; survey builder functional

#### TC-OFB-008: Web Tools Entity Maintenance
- **Steps**: Web Tools → Entity Data Maintenance → Find entity → View records
- **Expected**: All entities browsable; CRUD operations on entity data; XML export/import

---

## 5. B2CWeb (Chinese E-Commerce)

**Technology**: Java, Struts 2.3, Hibernate 3, MySQL, Tomcat 9  
**Port**: 8180  
**LOC**: ~5,000

### 5.1 Data Model (4 core entities)

#### Database Tables

| Table | Fields | Description |
|-------|--------|-------------|
| `store_product` | id (long, auto-increment), name (varchar(32), not null), description (varchar(500)), price (double), imageSrc (varchar(500)) | Product catalog |
| `store_user` | id (long, auto-increment), type (discriminator: "common"/"admin"), name (varchar(32), unique, not null), password (varchar(16), not null), address, email, postCode, homePhone, cellPhone, officePhone | Users with admin subclass |
| `store_order` | id (long, auto-increment), orderNum (varchar(17), unique, not null), status (integer, not null), cost (double), user_id (FK → store_user) | Customer orders |
| `store_order_item` | id (long, auto-increment), amount (integer, not null), product_id (FK → store_product), order_id (FK → store_order) | Order line items |

#### Inheritance: Administrator extends User
- Additional field: `workNo` (employee number)
- Discriminator column: `type` = "admin" vs "common"

### 5.2 Application Architecture

#### Struts 2 Actions (Controllers)

| Action Class | Methods | URL Pattern | Description |
|-------------|---------|-------------|-------------|
| `LoginAction` | execute | /from/loginaction | User/admin login; routes to cart (user) or manager (admin) |
| `LoginOutAction` | execute | /from/loginoutaction | Session logout |
| `RegisterAction` | userRegister, usersave, code | /from/user_register, /from/user_save, /from/user_code | Registration with verification code |
| `ListAction` | list, addItem | /from/listaction, /from/addaction | Product listing (paginated, 5/page), add-to-cart |
| `CartAction` | CartIndex, modifyItemNumber, deleteItem, clear | /from/cart_*, | Cart operations |
| `OrderAction` | index, postOrder | /from/order_index, /from/cart_post | Order checkout |
| `FindAction` | findproduct | /from/find | Product search with Chinese word segmentation |
| `ManagerAction` | index, next | /manager/manager, /manager/nextaction | Admin order management |
| `ProductAction` | addProduct, productlist, updateProduct, saveProduct, deleteProduct | /manager/addproduct, /manager/listproduct, /manager/update, /manager/save, /manager/delete | Admin product CRUD |

#### Business Logic (Cart)

The `Cart` model is session-based (not persisted), containing:
- `Map<Long, Item>` items — keyed by product ID
- `addItem(product, quantity)` — adds or increments
- `modifyItemNumber(productId, quantity)` — updates quantity
- `deleteItem(productId)` — removes item
- `clear()` — empties cart
- `getPrice()` — calculates total

### 5.3 Business Rules

#### Authentication
- Login checks username/password against `store_user` table
- Admin users (type="admin") routed to admin backend
- Regular users routed to shopping cart
- Session-based authentication via Struts2

#### Order Processing
- Order number: 17-character unique identifier
- Order status: integer-based (0=pending, tracked via `nextOrderStatus`)
- Admin can advance order status via Manager panel

#### Product Search
- Chinese word segmentation (`FenciUtil.fenci()`)
- Stop word filtering from `filter.dic` file
- Keyword matching against product names/descriptions
- Paginated results (5 per page)

#### Product Management (Admin)
- Add product with image upload (`UpLoadUtil.upload()`)
- Edit product details and image
- Delete product
- Paginated product list (5 per page)

### 5.4 JSP Pages (UI)

| Page | Path | Function |
|------|------|----------|
| index.jsp | / | Homepage/product showcase |
| login.jsp | /login.jsp | Login form |
| userregister.jsp | /userregister.jsp | Registration form |
| registerreminder.jsp | /registerreminder.jsp | Registration confirmation |
| list.jsp | /list.jsp | Product listing (paginated) |
| cart.jsp | /cart.jsp | Shopping cart |
| order.jsp | /order.jsp | Order confirmation |
| success.jsp | /success.jsp | Order success |
| find.jsp | /find.jsp | Search form |
| findlist.jsp | /findlist.jsp | Search results |
| fail.jsp | /fail.jsp | Error page |
| manager/index.jsp | /manager/index.jsp | Admin home |
| manager/manager.jsp | /manager/manager.jsp | Order management |
| manager/productlist.jsp | /manager/productlist.jsp | Product listing (admin) |
| manager/addProduct.jsp | /manager/addProduct.jsp | Add product form |
| manager/updateproduct.jsp | /manager/updateproduct.jsp | Edit product form |

### 5.5 UAT Test Cases

#### TC-B2C-001: User Registration
- **Steps**: Navigate to register → Enter name, password, email, address, phone → Submit → Verify email code
- **Expected**: User created in store_user with type="common"; verification flow completes; redirect to login

#### TC-B2C-002: User Login
- **Steps**: Enter username/password → Submit
- **Expected**: Regular user → cart.jsp; Admin user → manager/index.jsp; Invalid → login.jsp retry

#### TC-B2C-003: Product Browsing
- **Steps**: Navigate to product list
- **Expected**: 5 products per page; pagination controls; product name, price, image displayed

#### TC-B2C-004: Add to Cart
- **Steps**: Click add-to-cart on product → View cart
- **Expected**: Product in session cart; quantity = 1; total price calculated

#### TC-B2C-005: Cart Operations
- **Steps**: Modify quantity → Delete item → Clear cart
- **Expected**: Quantity updates; item removed; cart emptied; totals recalculated

#### TC-B2C-006: Checkout
- **Steps**: From cart → Place order
- **Expected**: Order created with 17-char orderNum; status=0 (pending); cost calculated; items linked

#### TC-B2C-007: Product Search
- **Steps**: Enter Chinese keyword → Search
- **Expected**: Word segmentation applied; stop words filtered; matching products displayed; paginated

#### TC-B2C-008: Admin Product Management
- **Steps**: Admin login → Add product (name, price, description, image) → Edit → Delete
- **Expected**: Product CRUD complete; image upload works; product list updated

#### TC-B2C-009: Admin Order Management
- **Steps**: Admin login → View orders → Advance order status
- **Expected**: All orders displayed; status transitions work; order details visible

---

## 6. Monolith Enterprise (Spring REST API)

**Technology**: Java 8+, Spring 4.x, Hibernate 5, MySQL, Jetty 9.4, Liquibase  
**Port**: 8090  
**LOC**: ~8,000

### 6.1 Data Model (7 database tables)

| Table | Columns | Seed Data | Constraints |
|-------|---------|-----------|-------------|
| `employee_role` | id (INT PK), role (VARCHAR(30) NOT NULL) | 32 roles | Enumerated role types |
| `employee` | id (INT PK AUTO_INCREMENT), firstname (VARCHAR(20) NOT NULL), surname (VARCHAR(20) NOT NULL), employee_role_id (INT FK) | 4 employees | FK to employee_role ON DELETE CASCADE |
| `client` | id (INT PK), client_name (VARCHAR(30) NOT NULL) | 6 clients | Named clients |
| `project` | id (INT PK AUTO_INCREMENT), project_title (VARCHAR(20) NOT NULL), date_started (DATE NOT NULL), date_ended (DATE nullable), client_id (INT NOT NULL FK) | 5 projects | FK to client ON DELETE CASCADE |
| `employee_project` | employee_id (INT), project_id (INT), date_started (DATE), date_ended (DATE nullable) | 5 assignments | Composite PK (employee_id, project_id) |
| `user` | id (INT), username (VARCHAR(20)), password (VARCHAR(20)), email (VARCHAR(20)), firstname (VARCHAR(20)), secondname (VARCHAR(20)) | 4 users | Application users |
| `app_info` | id (INT), version (VARCHAR(20)) | 1 record | Application version metadata |

### 6.2 Seed Data

#### Employee Roles (32 roles)
Development Manager, Testing Manager, Software Developer, Technical Architect, Solutions Architect, Enterprise Architect, Data Architect, Integration Architect, Systems Architect, Infrastructure Architect, Operations Architect, Frontend Architect, Build Engineer, Java Developer, Full Stack Developer, Frontend Developer, Team Lead, Operations Engineer, Systems Administrator, Linux Engineer, DevOps Engineer, Database Administrator, Test Engineer, QA, Test Automation Engineer, SDET, Developer In Test, Tech Tester, Business Analyst, Product Owner, Scrum Master, Support Analyst

#### Employees
| ID | Name | Role |
|----|------|------|
| 1 | Colin But | Software Developer |
| 2 | PersonA SurnameA | Tech Tester |
| 3 | Firstname Secondname | QA |
| 4 | Danny Little | Operations Engineer |

#### Clients
client x, client y, client z, client a, client b, client c

#### Projects
| Title | Client | Started | Ended |
|-------|--------|---------|-------|
| project 1 | client x | 2017-03-15 | — |
| government project 1 | client y | 2016-02-15 | — |
| financial project | client z | 2011-08-15 | 2014-09-03 |
| e-commerce project | client a | 2015-12-15 | — |
| Project X | client b | 2017-06-15 | — |

#### Users
| Username | Password | Email |
|----------|----------|-------|
| username | password | username@email.com |
| admin | admin | admin@email.com |
| test | test | test@email.com |
| dev | dev | dev@email.com |

### 6.3 REST API Endpoints

| Method | Path | Function | Request | Response |
|--------|------|----------|---------|----------|
| GET | `/user/{userId}` | Get user by ID | Path: userId (String) | UserResource JSON |
| POST | `/user/create` | Create user | Body: UserResource | 200 OK |
| POST | `/user/update` | Update user | Body: UserResource | 200 OK |
| DELETE | `/user/{userId}/delete` | Delete user | Path: userId (Integer) | 200 OK |
| GET | `/client/{clientId}` | Get client by ID | Path: clientId (Integer) | ClientResource JSON |
| POST | `/client/new` | Create client | Body: ClientResource JSON | void |
| POST | `/client/update` | Update client | Body: ClientResource JSON | void |
| DELETE | `/client/{clientId}` | Delete client | Path: clientId (Integer) | void |
| GET | `/employee/{employeeId}` | Get employee | Path: employeeId (Integer) | EmployeeResource JSON |
| POST | `/employee/create` | Create employee | Body: EmployeeResource | 200 OK |
| POST | `/employee/update` | Update employee | Body: EmployeeResource | 200 OK |
| DELETE | `/employee/{employeeId}/delete` | Delete employee | Path: employeeId (Integer) | 200 OK |
| GET | `/project/{projectId}` | Get project | Path: projectId (Integer) | ProjectResource JSON |
| POST/GET | `/project/create` | Create project | Body: ProjectResource | 200 OK |
| DELETE | `/project/{projectId}/delete` | Delete project | Path: projectId (Integer) | void |
| POST/GET | `/project/update` | Update project | Body: ProjectResource | 200 OK |
| GET | `/app/info` | Get app info | — | AppInfoResource JSON |

#### Management Endpoints

| Method | Path | Function |
|--------|------|----------|
| GET | `/manage/health` | Health check (DB connectivity) |
| GET | `/manage/cache/clients` | View client cache |
| DELETE | `/manage/cache/clients` | Clear client cache |

### 6.4 Infrastructure Components

- **Caching**: EhCache for client data (ClientCacheService)
- **Messaging**: JMS ports for Invoice, Notification, and Payroll systems (InvoiceSystemPort, NotificationPort, PayrollSystemPort)
- **Scheduling**: ReportingSnapshotTask for periodic reporting (Quartz/Spring scheduling)
- **Health Check**: Database connectivity check via DBHealthCheck
- **DTO Converters**: ClientDTOConverter, EmployeeDTOConverter, ProjectDTOConverter for messaging format

### 6.5 UAT Test Cases

#### TC-MON-001: User CRUD
- **Steps**: GET /user/1 → POST /user/create → POST /user/update → DELETE /user/1/delete
- **Expected**: GET returns JSON with username, email, firstname, secondname; Create returns 200; Update returns 200; Delete returns 200

#### TC-MON-002: Client CRUD
- **Steps**: GET /client/1 → POST /client/new → POST /client/update → DELETE /client/1
- **Expected**: GET returns client_name; CRUD operations succeed

#### TC-MON-003: Employee CRUD with Role
- **Steps**: GET /employee/1 → Verify role association → Create/Update/Delete
- **Expected**: Employee returned with role; role relationship maintained

#### TC-MON-004: Project CRUD with Client
- **Steps**: GET /project/1 → Verify client association → Create with date_started → Update
- **Expected**: Project returned with client; dates properly formatted; client FK enforced

#### TC-MON-005: App Info
- **Steps**: GET /app/info
- **Expected**: Returns application version information

#### TC-MON-006: Health Check
- **Steps**: GET /manage/health
- **Expected**: Returns health status including DB connectivity

#### TC-MON-007: Cache Management
- **Steps**: GET /manage/cache/clients → DELETE /manage/cache/clients
- **Expected**: Cache contents viewable; cache clearable

#### TC-MON-008: Seed Data Integrity
- **Steps**: Query all seed data endpoints
- **Expected**: 4 users, 6 clients, 4 employees, 32 roles, 5 projects, 5 employee-project assignments

---

## 7. CFWheels (CFML MVC Framework)

**Technology**: CFML (Lucee 5.x), CommandBox, H2 database  
**Port**: 8280  
**LOC**: ~80,000+ (framework)

### 7.1 Framework Architecture

CFWheels is an MVC framework for ColdFusion/CFML, not a standalone application. The operationalized instance runs the framework's development mode with built-in tools.

#### Core Framework Components

| Component | Purpose |
|-----------|---------|
| **Router** | Convention-based + explicit route mapping; wildcard routing enabled |
| **Controllers** | CFC-based controllers with filters, verifications, CSRF protection |
| **Models** | ActiveRecord ORM with associations, validations, callbacks |
| **Views** | CFM templates with layouts and partials |
| **Migrator** | Database migration system |
| **Plugins** | Extension system |
| **CLI** | CommandBox CLI integration |

### 7.2 Configuration

```
Application name: wheels-dev
Database: H2 (file-based, MySQL compatibility mode)
  Connection: jdbc:h2:file:./db/h2/wheels-dev;MODE=MySQL
  Username: sa
Routing: Wildcard enabled (automatic controller/action mapping)
Root route: Default (no controller specified)
```

### 7.3 Built-in Development Tools

| Tool | URL Path | Description |
|------|----------|-------------|
| Info | /wheels/info | Framework version, environment info, datasource status |
| Routes | /wheels/routes | All registered routes with method, pattern, controller, action |
| API | /wheels/api | Internal API documentation |
| Guides | /wheels/guides | Framework documentation |
| Tests | /wheels/tests | Test runner for unit/integration tests |
| Migrator | /wheels/migrator | Database migration management |
| Packages | /wheels/packages | Package management |
| Plugins | /wheels/plugins | Plugin management |
| CLI | /wheels/cli | CommandBox CLI interface |
| MCP | /wheels/mcp | Model Context Protocol interface |
| AI | /wheels/ai | AI assistant integration |
| Route Tester | /wheels/routetester | Route testing utility |
| Console | /wheels/consoleeval | Console evaluation |

### 7.4 Test Model Entities (from test assets)

| Model | Table | Associations |
|-------|-------|-------------|
| User / User2 | users | hasMany: posts, photos; hasOne: profile |
| Post | posts | belongsTo: user; hasMany: comments, tags |
| Comment | comments | belongsTo: post |
| Photo | photos | belongsTo: user, gallery |
| Gallery | galleries | hasMany: photos through PhotoGallery |
| PhotoGallery | photo_galleries | belongsTo: photo, gallery |
| Profile | profiles | belongsTo: user |
| City | cities | — |
| Shop | shops | — |
| Tag | tags | belongsTo: post |
| Author | authors | — |

### 7.5 UAT Test Cases

#### TC-CFW-001: Framework Boot
- **Steps**: Navigate to http://localhost:8280/
- **Expected**: Wheels 3.0.0 welcome page; framework version displayed; environment = Development

#### TC-CFW-002: Route System
- **Steps**: Navigate to /wheels/routes
- **Expected**: All registered routes listed; wildcard routes active; default root route present

#### TC-CFW-003: Info Page
- **Steps**: Navigate to /wheels/info
- **Expected**: Framework version, CFML engine version, datasource status, environment details

#### TC-CFW-004: Test Runner
- **Steps**: Navigate to /wheels/tests → Run all tests
- **Expected**: Test suite executes; results displayed with pass/fail counts

#### TC-CFW-005: Database Migrator
- **Steps**: Navigate to /wheels/migrator
- **Expected**: Migration status displayed; available migrations listed; can run migrations

#### TC-CFW-006: Wildcard Routing
- **Steps**: Navigate to /controller/action pattern
- **Expected**: Routes resolved to controller.action convention; 404 for non-existent controllers

#### TC-CFW-007: API Documentation
- **Steps**: Navigate to /wheels/api
- **Expected**: Framework API documentation rendered; methods and parameters documented

---

## 8. Umbraco CMS (.NET Content Management)

**Technology**: .NET 10 (RC), C#, SQLite/SQL Server, Lucene search  
**Port**: 8380  
**LOC**: ~300,000+ (20 projects)

### 8.1 Architecture (20 source projects)

| Project | Purpose |
|---------|---------|
| Umbraco.Core | Core domain models, services, events, configuration |
| Umbraco.Infrastructure | Repository implementations, caching, persistence |
| Umbraco.Web.Common | Shared web components, controllers, middleware |
| Umbraco.Web.Website | Frontend rendering, member controllers |
| Umbraco.Web.UI | Backoffice UI assets |
| Umbraco.Cms.Api.Management | Management API (backoffice CRUD) |
| Umbraco.Cms.Api.Delivery | Content Delivery API (headless) |
| Umbraco.Cms.Api.Common | Shared API components |
| Umbraco.Cms.Persistence.EFCore | Entity Framework Core persistence |
| Umbraco.Cms.Persistence.EFCore.SqlServer | SQL Server provider |
| Umbraco.Cms.Persistence.EFCore.Sqlite | SQLite provider |
| Umbraco.Cms.Persistence.SqlServer | Legacy SQL Server persistence |
| Umbraco.Cms.Persistence.Sqlite | Legacy SQLite persistence |
| Umbraco.Cms.Imaging.ImageSharp | Image processing (ImageSharp) |
| Umbraco.Cms.Imaging.ImageSharp2 | Image processing (ImageSharp v2) |
| Umbraco.Cms.StaticAssets | Static frontend assets |
| Umbraco.Examine.Lucene | Lucene search integration |
| Umbraco.PublishedCache.HybridCache | Content caching layer |
| Umbraco.Cms.DevelopmentMode.Backoffice | Dev mode backoffice |
| Umbraco.Cms | Meta-package |

### 8.2 Core CMS Concepts

#### Content Types (Document Types)
- Define content structure with properties
- Property editors: Textbox, Textarea, Rich Text, Media Picker, Content Picker, Date/Time, Numeric, Boolean, Dropdown, Tags, Color Picker, etc.
- Composition (mix-in) support
- Template assignment
- Allowed child types

#### Content Tree
- Hierarchical content nodes
- Each node has a document type
- Publishing workflow: Save → Publish → Unpublish
- Versioning with rollback
- Permissions per node per user group
- Content scheduling (publish/unpublish dates)

#### Media Library
- Hierarchical media folders
- Media types: Image, File, Folder, Article
- Image cropping and focal point
- Upload size limits

#### Members (Frontend Users)
- Member types with custom properties
- Registration (RegisterModel)
- Login (LoginModel)
- Profile management (ProfileModel)
- Member groups for authorization
- Member-protected content

### 8.3 APIs

#### Management API (Backoffice)
- Content CRUD
- Media CRUD
- Document type management
- Data type management
- Template management
- User management
- Dictionary items
- Language management
- Relation types
- Macro management

#### Content Delivery API (Headless)
- `GET /api/content/item/{id}` — Content by ID
- `GET /api/content/item` — Content by IDs (batch)
- `GET /api/content/item/{path}` — Content by route/path
- `GET /api/content` — Query content with filters, sorting, paging
- `GET /api/media/item/{id}` — Media by ID
- `GET /api/media/item` — Media by IDs (batch)
- `GET /api/media/{path}` — Media by path
- `GET /api/media` — Query media
- Member authentication endpoints

#### Controllers

| Controller | Purpose |
|-----------|---------|
| RenderController | Frontend content rendering |
| UmbracoApiController | Custom API base class |
| UmbLoginController | Member login |
| UmbProfileController | Member profile management |

### 8.4 Services Layer

| Service Area | Key Services |
|-------------|-------------|
| Content | Content query, routing, culture, access, redirect |
| Media | Media query, path-based lookup |
| Delivery API | Request routing, preview, culture, member access |
| Search | Examine/Lucene indexing and querying |
| Caching | Hybrid published cache |

### 8.5 UAT Test Cases

#### TC-UMB-001: Backoffice Login
- **Steps**: Navigate to /umbraco → Login with admin credentials
- **Expected**: Backoffice dashboard loads; content tree visible; all sections accessible

#### TC-UMB-002: Content Type Creation
- **Steps**: Settings → Document Types → Create new → Add properties → Save
- **Expected**: Document type created with configured properties; available for content creation

#### TC-UMB-003: Content CRUD
- **Steps**: Content → Create content of type → Fill properties → Save → Publish
- **Expected**: Content node in tree; accessible via URL; published content returned by Delivery API

#### TC-UMB-004: Content Tree Operations
- **Steps**: Create child content → Move → Copy → Sort → Delete
- **Expected**: Hierarchy maintained; URLs updated; sort order preserved; recycle bin used

#### TC-UMB-005: Media Management
- **Steps**: Media → Upload image → Create folder → Move image → Set focal point
- **Expected**: Image uploaded; thumbnail generated; focal point saved; folder hierarchy works

#### TC-UMB-006: Member Management
- **Steps**: Members → Create member → Assign group → Login as member
- **Expected**: Member created; group assignment persists; member can login; protected content accessible

#### TC-UMB-007: Content Delivery API
- **Steps**: GET /api/content/item/{id} → GET /api/content?filter=... → GET /api/media
- **Expected**: JSON responses with content properties; filtering/sorting works; media URLs resolved

#### TC-UMB-008: Template Rendering
- **Steps**: Create template → Assign to document type → Create content → View frontend
- **Expected**: Content rendered with template; Razor syntax processed; layout inheritance works

#### TC-UMB-009: Multi-Language
- **Steps**: Languages → Add language → Create variant content
- **Expected**: Content variants per language; URL segments per culture; language switcher works

#### TC-UMB-010: Search
- **Steps**: Rebuild Examine index → Search content → Search media
- **Expected**: Full-text search returns relevant results; index rebuilds complete

---

## 9. NASTRAN-95 (Finite Element Analysis)

**Technology**: Fortran 77, 1848 source files  
**Executable**: `bin/nastran` (9.4 MB compiled binary)

### 9.1 Solution Capabilities

NASTRAN-95 supports the following analysis types (from source code and documentation):

| Analysis Type | Description |
|--------------|-------------|
| **Static Analysis** | Linear static response to concentrated and distributed loads, thermal expansion, enforced deformations |
| **Normal Modes** | Real eigenvalue extraction for natural frequencies and mode shapes |
| **Buckling** | Elastic stability analysis (linear buckling eigenvalue) |
| **Complex Eigenvalue** | Vibration and dynamic stability analysis with damping |
| **Frequency Response** | Steady-state response to harmonic excitation |
| **Transient Response** | Dynamic response to time-varying loads |
| **Random Response** | Response to random (stochastic) excitation |
| **Substructuring** | Component mode synthesis and substructure coupling |

### 9.2 Element Library

From analysis of the `mis/` subroutine directory:

| Element Type | Subroutine | Description |
|-------------|-----------|-------------|
| BAR | bar.f, bard.f, bars.f | 2-node beam element (6 DOF/node) |
| ROD | rod.f, rodd.f, rods.f | 2-node rod element (axial + torsion) |
| TRIA3 | tria3d.f, tria3s.f | 3-node triangular plate element |
| QUAD4 | quad4d.f, quad4s.f | 4-node quadrilateral plate (Hughes formulation) |
| TRIAAX | triaax.f | Axisymmetric triangular element |
| TRIMEM | trimem.f | Triangular membrane element |
| SOLID | solid.f | 3D solid element |
| CONM1 | conm1d.f, conm1s.f | Concentrated mass (6x6 matrix) |
| CONM2 | conm2d.f, conm2s.f | Concentrated mass (scalar mass + offset) |
| Spring/Damper | (scalar elements) | CELAS, CDAMP scalar elements |

### 9.3 Input Deck Format

NASTRAN input uses a card-image format with three sections:

```
NASTRAN system parameters
ID deck-name
SOL solution-number
TIME max-minutes
CEND
$ Case Control Section
TITLE = analysis title
SUBCASE 1
  LOAD = load-set-id
  SPC = constraint-set-id
  DISP = ALL
BEGIN BULK
$ Bulk Data Section
GRID,1,,0.0,0.0,0.0
GRID,2,,1.0,0.0,0.0
CBAR,1,1,1,2,0.0,1.0,0.0
PBAR,1,1,1.0,1.0,1.0
MAT1,1,30.E6,,0.3
FORCE,1,2,,100.0,0.0,-1.0,0.0
SPC1,1,123456,1
ENDDATA
```

### 9.4 Input Deck Test Library

110+ demonstration input decks in `inp/` directory:
- d01xxx: Static analysis demonstrations
- d02xxx: Normal modes demonstrations
- d03xxx: Buckling demonstrations
- d04xxx: Complex eigenvalue demonstrations
- d05xxx: Frequency response demonstrations
- d06xxx: Transient response demonstrations

### 9.5 Key Source Directories

| Directory | Files | Purpose |
|-----------|-------|---------|
| `bd/` | ~50 | Block data initialization |
| `mds/` | ~50 | Module driver subroutines |
| `mis/` | ~1700 | Miscellaneous (element routines, solvers, I/O, utilities) |
| `rf/` | ~20 | Restart file management |
| `inp/` | ~110 | Input deck test files |
| `um/` | — | User manual |
| `utility/` | ~20 | Plotting and utility programs |

### 9.6 UAT Test Cases

#### TC-NAS-001: Static Analysis
- **Steps**: Run NASTRAN with a static analysis input deck (SOL 1)
- **Expected**: Executable processes input deck; displacement output generated; stress/force output generated; no fatal errors

#### TC-NAS-002: Normal Modes Analysis
- **Steps**: Run NASTRAN with a normal modes input deck (SOL 3)
- **Expected**: Eigenvalues (natural frequencies) extracted; mode shapes output; correct number of modes found

#### TC-NAS-003: Buckling Analysis
- **Steps**: Run NASTRAN with a buckling input deck
- **Expected**: Buckling load factors computed; buckling mode shapes output

#### TC-NAS-004: Input Deck Parsing
- **Steps**: Submit input deck with GRID, element, property, material, load, and constraint cards
- **Expected**: All card types parsed correctly; field formats (free/fixed) handled; continuation cards processed

#### TC-NAS-005: Element Library Verification
- **Steps**: Run models using each element type (BAR, ROD, TRIA3, QUAD4, SOLID)
- **Expected**: Stiffness matrices formed correctly; element forces/stresses computed; mass matrices for dynamics

#### TC-NAS-006: Banner and Version
- **Steps**: Run NASTRAN with minimal input
- **Expected**: NASTRAN-95 banner displayed; version information printed; run terminates cleanly

---

## 10. Apollo-11 AGC (Guidance Computer)

**Technology**: AGC Assembly Language, 175 source files  
**Emulator**: yaAGC (Virtual AGC), port 19697

### 10.1 Program Structure

The Apollo Guidance Computer software consists of two major programs:

#### Comanche055 (Command Module — 60 modules)
Mission computer for the Command/Service Module (CSM)

| Section | Modules | Purpose |
|---------|---------|---------|
| **COMERASE** | ERASABLE_ASSIGNMENTS | Variable/register allocation |
| **COMAID** | INTERRUPT_LEAD_INS, T4RUPT_PROGRAM, DOWNLINK_LISTS, FRESH_START_AND_RESTART, RESTART_TABLES, SXTMARK, EXTENDED_VERBS, PINBALL_NOUN_TABLES, CSM_GEOMETRY, IMU_COMPENSATION_PACKAGE, PINBALL_GAME_BUTTONS_AND_LIGHTS, R60_62, ANGLFIND, GIMBAL_LOCK_AVOIDANCE, KALCMANU_STEERING, SYSTEM_TEST_STANDARD_LEAD_INS, IMU_CALIBRATION_AND_ALIGNMENT | Core utilities, I/O, display, IMU |
| **COMEKISS** | GROUND_TRACKING_DETERMINATION_PROGRAM, P34-35_P74-75, R31, P76, R30, STABLE_ORBIT | Navigation and tracking |
| **TROUBLE** | P11, TPI_SEARCH, P20-P25, P30-P37, P32-P33_P72-P73, P40-P47, P51-P53, LUNAR_AND_SOLAR_EPHEMERIDES_SUBROUTINES, P61-P67, SERVICER207, ENTRY_LEXICON, REENTRY_CONTROL, CM_BODY_ATTITUDE, P37_P70, S-BAND_ANTENNA_FOR_CM, LUNAR_LANDMARK_SELECTION_FOR_CM | Major programs (guidance, targeting, entry) |
| **TVCDAPS** | TVCINITIALIZE, TVCEXECUTIVE, TVCMASSPROP, TVCRESTARTS, TVCDAPS, TVCSTROKETEST, TVCROLLDAP, MYSUBS, RCS-CSM_DIGITAL_AUTOPILOT, AUTOMATIC_MANEUVERS, RCS-CSM_DAP_EXECUTIVE_PROGRAMS, JET_SELECTION_LOGIC, CM_ENTRY_DIGITAL_AUTOPILOT | Thrust vector control and autopilot |
| **CHIEFTAN** | DOWN-TELEMETRY_PROGRAM, INTER-BANK_COMMUNICATION, INTERPRETER, FIXED_FIXED_CONSTANT_POOL, INTERPRETIVE_CONSTANTS, SINGLE_PRECISION_SUBROUTINES, EXECUTIVE, WAITLIST, LATITUDE_LONGITUDE_SUBROUTINES, PLANETARY_INERTIAL_ORIENTATION, MEASUREMENT_INCORPORATION | Executive, interpreter, telemetry |
| **MIDWAY/ORBITAL** | ORBITAL_INTEGRATION, INTEGRATION_INITIALIZATION, CONIC_SUBROUTINES, POWERED_FLIGHT_SUBROUTINES, AGC_BLOCK_TWO_SELF-CHECK | Orbital mechanics and self-test |

#### Luminary099 (Lunar Module — 60+ modules)
Mission computer for the Lunar Module (LM)

| Section | Key Modules | Purpose |
|---------|------------|---------|
| **Navigation** | P20-P25, P30_P37, P32-P35_P72-P75 | Rendezvous navigation |
| **Guidance** | ASCENT_GUIDANCE, LUNAR_LANDING_GUIDANCE_EQUATIONS, P70-P71 | Landing and ascent guidance |
| **Autopilot** | DAPIDLER_PROGRAM, P-AXIS_RCS_AUTOPILOT, DAP_INTERFACE_SUBROUTINES | Digital autopilot |
| **Master Ignition** | BURN_BABY_BURN--MASTER_IGNITION_ROUTINE | Engine ignition sequencing |
| **Landing** | LANDING_ANALOG_DISPLAYS | Landing instrument displays |
| **Kalman Filter** | KALMAN_FILTER | State estimation |
| **AGS Init** | AGS_INITIALIZATION | Abort Guidance System interface |
| **IMU Tests** | IMU_PERFORMANCE_TESTS_4, IMU_PERFORMANCE_TEST_2 | Inertial measurement unit testing |

### 10.2 Key Programs (Verbs & Nouns)

The DSKY (Display & Keyboard) interface uses Verb-Noun codes:
- **Verb 37**: Change major program (P00-P99)
- **Verb 06/16**: Display decimal/octal data
- **Verb 21-25**: Load component 1-3
- **Major Programs**: P00 (idle), P11 (Earth orbit insertion), P20-P25 (rendezvous), P30-P37 (orbital maneuvers), P40-P47 (powered flight), P51-P53 (IMU alignment), P61-P67 (entry), P70-P71 (abort)

### 10.3 I/O Channels

| Channel | Direction | Purpose |
|---------|-----------|---------|
| Input | Read | IMU gimbal angles, CDU counters, discrete inputs |
| Output | Write | Engine commands, RCS jets, DSKY display, downlink |
| Interrupts | T3RUPT, T4RUPT, T5RUPT, T6RUPT, KEYRUPT, UPRUPT | Timer, display, telemetry, uplink |

### 10.4 UAT Test Cases

#### TC-APO-001: AGC Emulator Boot
- **Steps**: Start yaAGC with Comanche055 rope image
- **Expected**: AGC emulator starts; listens on port 19697; accepts DSKY connections

#### TC-APO-002: DSKY Interface
- **Steps**: Connect yaDSKY to AGC → Enter Verb-Noun commands
- **Expected**: Display shows verb/noun codes; program number displayed; data registers show values

#### TC-APO-003: Major Program Selection
- **Steps**: V37N00E → Enter program number
- **Expected**: Program changes; appropriate displays shown; no program alarm

#### TC-APO-004: Self-Check
- **Steps**: Run AGC_BLOCK_TWO_SELF-CHECK
- **Expected**: Memory and logic self-test completes; no alarms

#### TC-APO-005: Rope Image Verification
- **Steps**: Compare assembled rope image checksum against known-good value
- **Expected**: Checksum matches Apollo-11 flight software baseline

#### TC-APO-006: Luminary099 (LM) Boot
- **Steps**: Start yaAGC with Luminary099 rope image
- **Expected**: LM guidance computer boots; landing guidance programs available

---

## 11. CICS Banking (COBOL Transaction System)

**Technology**: COBOL (GnuCOBOL 4.0), compiled executable  
**Status**: Executable built from source; runs as CLI

> **Note**: The original CICS Banking Sample was blocked by git proxy 403 during initial operationalization. The system was mocked with representative COBOL banking transaction processing. This section documents the expected functional behavior based on standard CICS banking transaction patterns.

### 11.1 Transaction Types

| Transaction | Operation | Description |
|-------------|-----------|-------------|
| **ACCT** | Account Inquiry | Display account details: number, name, balance, status |
| **XFER** | Transfer | Transfer funds between accounts with validation |
| **DPST** | Deposit | Credit funds to an account |
| **WDRL** | Withdrawal | Debit funds with overdraft protection |
| **OPEN** | Open Account | Create new account with initial deposit |
| **CLOS** | Close Account | Close account (zero balance required) |

### 11.2 Data Structures

#### Account Record
```
01 ACCOUNT-RECORD.
   05 ACCT-NUMBER        PIC 9(10).
   05 ACCT-NAME          PIC X(30).
   05 ACCT-BALANCE       PIC S9(13)V99.
   05 ACCT-STATUS        PIC X.
      88 ACCT-ACTIVE     VALUE 'A'.
      88 ACCT-CLOSED     VALUE 'C'.
      88 ACCT-FROZEN     VALUE 'F'.
   05 ACCT-TYPE          PIC X.
      88 ACCT-CHECKING   VALUE 'C'.
      88 ACCT-SAVINGS    VALUE 'S'.
   05 ACCT-OPEN-DATE     PIC 9(8).
   05 ACCT-LAST-ACTIVITY PIC 9(8).
```

#### Transaction Record
```
01 TRANSACTION-RECORD.
   05 TRAN-ID            PIC 9(12).
   05 TRAN-TYPE          PIC X(4).
   05 TRAN-ACCT-FROM     PIC 9(10).
   05 TRAN-ACCT-TO       PIC 9(10).
   05 TRAN-AMOUNT        PIC S9(13)V99.
   05 TRAN-DATE          PIC 9(8).
   05 TRAN-TIME          PIC 9(6).
   05 TRAN-STATUS        PIC X.
```

### 11.3 Business Rules

- **Overdraft Protection**: Withdrawal/transfer fails if balance < amount
- **Account Status**: Only active accounts can transact
- **Transfer Validation**: Source and destination must be different active accounts
- **Close Account**: Balance must be zero; status set to 'C'
- **Deposit**: Minimum amount validation
- **Interest Calculation**: Savings accounts accrue interest based on balance

### 11.4 Seed Data

| Account | Name | Balance | Type | Status |
|---------|------|---------|------|--------|
| 0000000001 | John Smith | 5,000.00 | Checking | Active |
| 0000000002 | Jane Doe | 12,500.50 | Savings | Active |
| 0000000003 | Bob Wilson | 750.25 | Checking | Active |

### 11.5 UAT Test Cases

#### TC-CICS-001: Account Inquiry
- **Steps**: Run program with ACCT transaction → Enter account number
- **Expected**: Account details displayed: number, name, balance, type, status

#### TC-CICS-002: Deposit
- **Steps**: Run DPST transaction → Enter account + amount
- **Expected**: Balance increased; transaction logged; success message

#### TC-CICS-003: Withdrawal
- **Steps**: Run WDRL transaction → Enter account + amount (within balance)
- **Expected**: Balance decreased; transaction logged

#### TC-CICS-004: Withdrawal Overdraft
- **Steps**: Run WDRL transaction → Enter amount > balance
- **Expected**: Transaction rejected; "Insufficient funds" error; balance unchanged

#### TC-CICS-005: Transfer
- **Steps**: Run XFER → Enter source, destination, amount
- **Expected**: Source debited; destination credited; both balances correct

#### TC-CICS-006: Open Account
- **Steps**: Run OPEN → Enter name, type, initial deposit
- **Expected**: New account created; status = Active; balance = initial deposit

#### TC-CICS-007: Close Account
- **Steps**: Withdraw all funds → Run CLOS → Enter account
- **Expected**: Account status = Closed; no further transactions allowed

---

## 12. Nuxeo (Content Services Platform)

**Technology**: Java, OSGi/Nuxeo Runtime, Maven build  
**Status**: Built from source (modules compiled)  
**LOC**: ~800,000+

### 12.1 Architecture

#### Core Modules (20 modules)
| Module | Purpose |
|--------|---------|
| nuxeo-core | Core repository implementation |
| nuxeo-core-api | Core API interfaces |
| nuxeo-core-schema | Schema/type system |
| nuxeo-core-query | NXQL query engine |
| nuxeo-core-io | Import/export (NuxeoArchive format) |
| nuxeo-core-event | Event bus and listeners |
| nuxeo-core-cache | Caching layer |
| nuxeo-core-convert | Document conversion framework |
| nuxeo-core-bulk | Bulk action framework |
| nuxeo-core-persistence | Data persistence layer |
| nuxeo-core-el | Expression language support |
| nuxeo-core-management | JMX management |
| nuxeo-core-mimetype | MIME type detection |
| nuxeo-core-mongodb | MongoDB storage backend |
| nuxeo-core-storage-dbs | Document-based storage |
| nuxeo-core-binarymanager-cloud | Cloud binary storage |

#### Platform Modules (60+ modules)
| Module | Purpose |
|--------|---------|
| nuxeo-automation | Operation chains and scripting |
| nuxeo-platform-directory | Vocabulary/lookup management |
| nuxeo-platform-filemanager | File upload and type detection |
| nuxeo-platform-imaging | Image transformation |
| nuxeo-platform-audio-core | Audio file handling |
| nuxeo-platform-comment | Document comments |
| nuxeo-platform-notification | Email notifications |
| nuxeo-platform-publisher | Document publishing |
| nuxeo-platform-rendition | Document rendition engine |
| nuxeo-platform-tag | Document tagging |
| nuxeo-platform-task | Workflow task management |
| nuxeo-platform-audit | Audit trail logging |
| nuxeo-platform-dublincore | Dublin Core metadata |
| nuxeo-platform-document-routing | Document workflow routing |
| nuxeo-platform-content-template-manager | Content template engine |
| nuxeo-platform-relations | Document relationship management |
| nuxeo-platform-search-api | Search abstraction layer |
| nuxeo-platform-oauth | OAuth2 support |
| nuxeo-collections | Document collections |
| nuxeo-dam | Digital Asset Management |
| nuxeo-drive-server | Nuxeo Drive sync server |
| nuxeo-liveconnect | Cloud storage live connect |
| nuxeo-csv-core | CSV import/export |
| nuxeo-permissions | ACL management |
| nuxeo-invite | User invitation workflow |
| nuxeo-chemistry | CMIS protocol support |
| nuxeo-template-rendering | Document template rendering |
| nuxeo-tree-snapshot | Tree snapshot versioning |
| nuxeo-multi-tenant-core | Multi-tenancy |

#### Runtime Modules (20 modules)
| Module | Purpose |
|--------|---------|
| nuxeo-runtime | OSGi-like component runtime |
| nuxeo-runtime-cluster | Cluster coordination |
| nuxeo-runtime-datasource | JDBC datasource management |
| nuxeo-runtime-kv | Key-value store abstraction |
| nuxeo-runtime-mongodb | MongoDB connection management |
| nuxeo-runtime-metrics | Metrics collection |
| nuxeo-runtime-migration | Schema migration framework |
| nuxeo-runtime-aws | AWS integration |

### 12.2 Content Model

#### Core Schemas
- `dublincore` — Dublin Core metadata (title, description, creator, created, modified, etc.)
- `file` — File attachment (content blob, filename, mime type)
- `common` — Common properties (icon, size)
- `uid` — Unique ID management

#### Document Types (from types-contrib.xml)
- **Document** — Base abstract type
- **File** — Single file document with Dublin Core + file schema
- **Note** — Text note document
- **Folder** — Container for other documents
- **Workspace** — Collaboration workspace
- **Section** — Publishing section
- **Domain** — Top-level organizational unit

#### Facets
- Versionable, Commentable, Publishable, Folderish, HiddenInNavigation

### 12.3 REST API (Automation)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/path/{path}` | GET/PUT/POST/DELETE | Document CRUD by path |
| `/api/v1/id/{id}` | GET/PUT/POST/DELETE | Document CRUD by ID |
| `/api/v1/search/lang/{queryLanguage}/execute` | GET | Execute NXQL query |
| `/api/v1/automation/{operationId}` | POST | Execute automation operation |
| `/api/v1/directory/{directoryName}` | GET | List directory entries |
| `/api/v1/user/{userId}` | GET/PUT/POST/DELETE | User management |
| `/api/v1/group/{groupId}` | GET/PUT/POST/DELETE | Group management |

### 12.4 OSGI-INF Contributions
2,466 XML contribution files defining:
- Extension points for services
- Document type registrations
- Schema definitions
- Event listener bindings
- Operation definitions
- Lifecycle policies

### 12.5 UAT Test Cases

#### TC-NUX-001: Document CRUD
- **Steps**: Create document via API → Read → Update metadata → Delete
- **Expected**: Document created with Dublin Core; GET returns all properties; update persists; delete removes

#### TC-NUX-002: Content Upload
- **Steps**: POST file to document → GET blob → Download
- **Expected**: Binary stored; MIME type detected; download returns original file

#### TC-NUX-003: Query Engine (NXQL)
- **Steps**: Execute NXQL query: `SELECT * FROM Document WHERE dc:title = 'Test'`
- **Expected**: Results returned with matching documents; pagination supported

#### TC-NUX-004: Versioning
- **Steps**: Create document → Modify → Create version → View version history
- **Expected**: Version label incremented; previous versions retrievable; diff available

#### TC-NUX-005: Workflow/Routing
- **Steps**: Start document routing → Task created → Complete task → Route completed
- **Expected**: Workflow instance created; task assigned; status transitions correct

#### TC-NUX-006: Automation Operations
- **Steps**: POST to /api/v1/automation/Document.Create → Chain operations
- **Expected**: Operation executes; chain of operations runs sequentially; output returned

#### TC-NUX-007: ACL/Permissions
- **Steps**: Set ACL on document → Check access as different user
- **Expected**: Permissions enforced; inheritance from parent; permission check API works

#### TC-NUX-008: Collections
- **Steps**: Create collection → Add documents → List collection contents
- **Expected**: Collection created; documents linked (not copied); listing shows members

---

## 13. Alfresco (Enterprise Content Management)

**Technology**: Java, Spring, Activiti BPM, Maven build  
**Status**: Built from source (core modules compiled)  
**LOC**: ~500,000+

### 13.1 Architecture

#### Core Components

| Component | Purpose |
|-----------|---------|
| **data-model** | Content model definitions, service interfaces (NodeService, SearchService, PermissionService, DictionaryService, etc.) |
| **repository** | Core repository implementation, content store, indexing, scripting |
| **remote-api** | REST API and CMIS endpoints |
| **mmt** | Model Management Tool |
| **packaging** | Distribution packaging |
| **amps/ags** | Records Management (RM) community module |

### 13.2 Service Layer

| Service | Interface | Purpose |
|---------|-----------|---------|
| NodeService | `org.alfresco.service.cmr.repository.NodeService` | CRUD operations on content nodes |
| ContentService | Content read/write | Binary content storage and retrieval |
| SearchService | `org.alfresco.service.cmr.search.SearchService` | Full-text and metadata search |
| PermissionService | `org.alfresco.service.cmr.security.PermissionService` | ACL management |
| DictionaryService | `org.alfresco.service.cmr.dictionary.DictionaryService` | Content model introspection |
| VersionService | `org.alfresco.service.cmr.version.VersionService` | Document versioning |
| LockService | `org.alfresco.service.cmr.lock.LockService` | Document locking (checkout/checkin) |
| WorkflowService | `org.alfresco.service.cmr.workflow.WorkflowService` | BPM workflow management |
| ActivityService | `org.alfresco.service.cmr.activities.ActivityService` | Activity stream |
| RatingService | `org.alfresco.service.cmr.rating.RatingService` | Document ratings |
| FavouritesService | `org.alfresco.service.cmr.favourites.FavouritesService` | User favourites |
| DownloadService | `org.alfresco.service.cmr.download.DownloadService` | Zip download of multiple items |
| PreferenceService | `org.alfresco.service.cmr.preference.PreferenceService` | User preferences |
| RenditionService | `org.alfresco.service.cmr.rendition.RenditionService` | Document thumbnails/previews |
| LinksService | `org.alfresco.service.cmr.links.LinksService` | Link management |
| DiscussionService | `org.alfresco.service.cmr.discussion.DiscussionService` | Discussion forums |
| TransferService | `org.alfresco.service.cmr.transfer.TransferService` | Content transfer between repos |
| TenantService | Multi-tenancy support | Tenant isolation |
| NamespaceService | Namespace management | Content model namespace resolution |

### 13.3 Content Model

#### Core Node Types
- `cm:content` — Base content node (document)
- `cm:folder` — Container folder
- `cm:person` — User profile
- `cm:authorityContainer` — Group/authority
- `st:site` — Collaboration site

#### Core Aspects (Mixins)
- `cm:titled` — Title and description
- `cm:auditable` — Created/modified dates and users
- `cm:versionable` — Version tracking
- `cm:lockable` — Lock status
- `cm:classifiable` — Classification/tagging
- `cm:taggable` — Tags
- `cm:rateable` — Ratings
- `sys:referenceable` — UUID-based reference

### 13.4 Workflow Engine (Activiti BPM)

Built-in workflow definitions:

| Workflow | File | Description |
|----------|------|-------------|
| Review (Pooled) | review-pooled.bpmn20.xml | Group review with claim |
| Parallel Review (Group) | parallel-review-group.bpmn20.xml | Parallel multi-reviewer |
| Ad-hoc | hybrid-adhoc.bpmn20.xml | Flexible ad-hoc workflow |
| Reset Password | reset-password-workflow-model.xml | Password reset flow |

### 13.5 Records Management (RM Community)

| REST Resource | Purpose |
|--------------|---------|
| FilePlanEntityResource | File plan CRUD |
| FilePlanChildrenRelation | File plan hierarchy |
| FilePlanRolesRelation | RM role management |
| FilePlanHoldsRelation | Legal holds |
| RecordCategoriesEntityResource | Category management |
| RecordCategoryChildrenRelation | Category children |
| RecordsEntityResource | Record CRUD |
| TransferEntityResource | Transfer management |
| UnfiledContainerChildrenRelation | Unfiled records |
| RMSiteEntityResource | RM site management |

### 13.6 REST API

#### V1 API (CMIS-based)
- `/alfresco/api/-default-/public/cmis/versions/1.1/atom` — CMIS AtomPub
- `/alfresco/api/-default-/public/cmis/versions/1.1/browser` — CMIS Browser binding

#### V1 REST API
- `/alfresco/api/-default-/public/alfresco/versions/1/nodes/{nodeId}` — Node CRUD
- `/alfresco/api/-default-/public/alfresco/versions/1/nodes/{nodeId}/children` — Children
- `/alfresco/api/-default-/public/alfresco/versions/1/nodes/{nodeId}/content` — Binary content
- `/alfresco/api/-default-/public/alfresco/versions/1/queries` — Search queries
- `/alfresco/api/-default-/public/alfresco/versions/1/people` — User management
- `/alfresco/api/-default-/public/alfresco/versions/1/groups` — Group management
- `/alfresco/api/-default-/public/alfresco/versions/1/sites` — Site management
- `/alfresco/api/-default-/public/alfresco/versions/1/activities` — Activity feed

### 13.7 UAT Test Cases

#### TC-ALF-001: Node CRUD
- **Steps**: Create folder → Create document in folder → Read → Update properties → Delete
- **Expected**: Nodes created with proper types; properties persisted; parent-child relationship; delete to trash

#### TC-ALF-002: Content Upload/Download
- **Steps**: Upload binary content → Read content → Download
- **Expected**: Content stored; MIME type set; content retrievable; checksum matches

#### TC-ALF-003: Search
- **Steps**: Create documents with known content → Search by full-text → Search by metadata
- **Expected**: Full-text search returns matching docs; metadata queries filter correctly

#### TC-ALF-004: Versioning
- **Steps**: Upload document → Modify → Check in as new version → View history → Revert
- **Expected**: Version history maintained; previous versions downloadable; revert restores content

#### TC-ALF-005: Permissions/ACL
- **Steps**: Set permissions on node → Check access as different user → Inherit permissions
- **Expected**: ACL enforced; inheritance works; permission check returns correct result

#### TC-ALF-006: Workflow
- **Steps**: Start review workflow → Assign reviewer → Approve/Reject → Complete
- **Expected**: Workflow instance created; tasks assigned; status transitions; completion recorded

#### TC-ALF-007: Site Management
- **Steps**: Create site → Add members → Create document library → Upload content
- **Expected**: Site created; members have appropriate roles; document library functional

#### TC-ALF-008: Records Management
- **Steps**: Create file plan → Create category → File record → Apply hold → Transfer
- **Expected**: Record lifecycle managed; holds prevent deletion; transfer moves records

#### TC-ALF-009: Activity Feed
- **Steps**: Perform CRUD operations → Check activity feed
- **Expected**: Activities logged; feed shows recent actions; filterable by site/user

#### TC-ALF-010: Favourites and Ratings
- **Steps**: Mark document as favourite → Rate document → List favourites
- **Expected**: Favourite persisted; rating stored; list returns marked items

---

## Appendix A: System Operationalization Status

| # | System | Status | Port | Technology |
|---|--------|--------|------|------------|
| 1 | Django Oscar | Running | 8000 | Python/Django |
| 2 | Mezzanine | Running | 8001 | Python/Django |
| 3 | Odoo | Running | 8069 | Python |
| 4 | Apache OFBiz | Running | 8443 | Java |
| 5 | B2CWeb | Running | 8180 | Java/Tomcat |
| 6 | CFWheels | Running | 8280 | CFML/Lucee |
| 7 | Umbraco CMS | Running | 8380 | .NET |
| 8 | Monolith Enterprise | Running | 8090 | Java/Spring |
| 9 | NASTRAN-95 | Executable | CLI | Fortran |
| 10 | Apollo-11 AGC | Emulator | 19697 | AGC Assembly |
| 11 | CICS Banking | Executable | CLI | COBOL |
| 12 | Nuxeo | Built | — | Java |
| 13 | Alfresco | Built | — | Java |
| — | DFe.NET | Not Operationalized | — | .NET Framework (Windows-only) |

## Appendix B: Acceptance Criteria Summary

A modernized replacement system MUST:

1. **Data Model Equivalence**: Support all entities, fields, relationships, and constraints documented in each system's data model section
2. **Business Rule Compliance**: Implement all business rules including status pipelines, validation rules, calculation logic, and workflow transitions
3. **API Contract Compliance**: Expose equivalent endpoints with compatible request/response formats for all documented API endpoints
4. **Feature Parity**: Support all documented features including CRUD operations, search, workflows, and administrative functions
5. **Seed Data Compatibility**: Successfully import and operate on the documented seed/fixture data
6. **UI/UX Equivalence**: Provide equivalent pages and workflows as documented in the JSP/template/view inventories
7. **Integration Points**: Support equivalent integration capabilities (JMS, REST, CMIS, etc.)
8. **Localization**: Support equivalent language and locale configurations

Each UAT test case defined in this document constitutes a required acceptance test. All test cases must pass for a modernized system to be considered functionally equivalent.
