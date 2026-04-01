# Modernization Corpus - Operationalization Report

**Date:** April 1, 2026
**Objective:** Prove that systems in the legacy rationalization corpus are runnable by operationalizing them end-to-end.

---

## Summary

Of the 14 legacy systems in the corpus, **4 were selected as candidates** for operationalization based on size, language availability, and dependency feasibility. **1 system (Django Oscar) was fully operationalized** and demonstrated running as a live e-commerce application with full functionality.

## Systems Evaluated

| System | Language | LOC | Result | Reason |
|--------|----------|-----|--------|--------|
| **Django Oscar** | Python/Django | 10K+ | **RUNNING** | Full sandbox with SQLite, 201 products, admin dashboard |
| Mezzanine | Python/Django | 5K+ | BLOCKED | `imp` module removed in Python 3.12; requires Python <= 3.11 |
| Monolith Enterprise (Snowman) | Java/Spring | 5K+ | BLOCKED | Requires Java 7 (javax namespace); Java 17 uses jakarta namespace. Also requires MySQL for Liquibase migrations |
| B2CWeb | Java/SSH | 5K+ | NOT ATTEMPTED | Requires Eclipse IDE, Tomcat, MySQL; Chinese documentation only |

## Django Oscar - Fully Operational

### What Was Demonstrated

1. **Product Catalogue** - 201 products across categories (Clothing, Books > Fiction, Non-Fiction) with pricing, stock status, and faceted search
2. **Shopping Cart** - Add-to-basket functionality with real-time basket total updates and offer/promotion triggers
3. **Admin Dashboard** - Full store management interface showing 209 products, order statistics, customer data, catalogue management, fulfilment, offers, content, and reports
4. **Search Engine** - Whoosh-based full-text search with product indexing
5. **User Authentication** - Login/registration system with email-based auth backend

### How to Run

```bash
# 1. Clone the corpus and aggregate django-oscar
cd BAH-modernization-corpus
bash CORPUS-AGGREGATION-SETUP.sh django-oscar

# 2. Run the automated setup script
bash operationalize-django-oscar.sh

# 3. Access the running application
#    Storefront: http://localhost:8000/en-gb/catalogue/
#    Dashboard:  http://localhost:8000/en-gb/dashboard/
#    Credentials: superuser / testing123
```

### Technical Stack Verified

- **Runtime:** Python 3.12, Django 5.2, Node.js 22
- **Database:** SQLite (zero-config, included)
- **Search:** Whoosh (file-based, included)
- **Assets:** Bootstrap CSS/JS via npm + Gulp
- **Server:** Django development server (runserver)

## Why Other Systems Could Not Run

### Mezzanine (Python CMS)
- Uses the `imp` module which was removed in Python 3.12 (PEP 594)
- The generated `settings.py` imports `imp` at line 298
- **Fix required:** Upgrade to Python 3.11 or patch Mezzanine to use `importlib`

### Monolith Enterprise / Snowman (Java)
- Configured for Java 7 (`<java.version>1.7</java.version>`)
- Uses `javax.annotation.PostConstruct` (removed in Java 11+, replaced by jakarta)
- Spring Framework version uses `javax.jms` but resolved dependencies use `jakarta.jms`
- Liquibase plugin requires a live MySQL database connection during Maven build
- Embedded Jetty API has breaking changes between versions
- **Fix required:** Downgrade to Java 8/11, or refactor javax -> jakarta imports + provide MySQL

### B2CWeb (Chinese Java E-Commerce)
- Requires Eclipse IDE for project import (no Maven/Gradle build)
- Requires Tomcat 7.0 application server
- Requires MySQL 5.6 with manual database creation
- Documentation is entirely in Chinese
- **Fix required:** Full environment setup with legacy Java toolchain

## Conclusions

1. **Django Oscar proves the corpus contains runnable, production-grade systems** - not just static code for analysis
2. **The legacy debt in other systems is real** - Java version incompatibilities, deprecated Python modules, and hard MySQL dependencies represent genuine modernization challenges
3. **The corpus accurately represents the spectrum** from "can run today" (Django Oscar) to "needs significant modernization effort" (Monolith Enterprise, B2CWeb)
4. **Recommended next steps:**
   - Use Django Oscar as a reference for what a fully modernized system looks like
   - Target Mezzanine for a Python 3.12 compatibility upgrade (smallest effort)
   - Target Monolith Enterprise for a Java 17 migration (javax -> jakarta, representative of real federal modernization)
