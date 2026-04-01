# Nuxeo Migration Plan

## Phase 1: javax -> jakarta
- javax imports: 527
## Phase 2: Simplify Abstractions
- Interfaces: 735 | Abstract classes: 333
- Flatten unnecessary abstraction layers
## Phase 3: Plugin Architecture Modernization
- Migrate OSGI-based plugins to Spring Boot starters
## Phase 4: Containerization
- POM modules: 361 - consolidate where possible
## Estimated Effort: 10-14 months
