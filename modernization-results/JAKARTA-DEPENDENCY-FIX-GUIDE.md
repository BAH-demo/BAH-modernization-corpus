# Jakarta EE Dependency Fix Guide

## Overview

When migrating Java source code from `javax.*` to `jakarta.*` namespaces, the corresponding build dependencies must also be updated. Jakarta EE uses different artifact coordinates and version numbers than their javax predecessors. This guide documents the required dependency fixes for all 5 Java systems in the modernization corpus.

## System-by-System Analysis

### 1. Monolith Enterprise ✅ FIXED

**Build System:** Maven (pom.xml)
**Status:** Dependency versions corrected and build verified (`mvn compile` SUCCESS)

| Old Dependency | New Dependency | Version |
|---|---|---|
| `javax.ws.rs:javax.ws.rs-api:2.0` | `jakarta.ws.rs:jakarta.ws.rs-api` | `3.1.0` |
| `javax.validation:validation-api:2.0.0.Final` | `jakarta.validation:jakarta.validation-api` | `3.0.2` |
| `javax.el:javax.el-api:3.0.0` | `jakarta.el:jakarta.el-api` | `5.0.1` |
| `org.glassfish.web:javax.el:2.2.6` | `org.glassfish:jakarta.el` | `5.0.0-M1` |
| *(missing)* | `jakarta.persistence:jakarta.persistence-api` | `3.1.0` |
| *(missing)* | `jakarta.jms:jakarta.jms-api` | `3.1.0` |

**Additional Fix:** Jetty pinned to `11.0.24` (open-ended range `[9.4.11,)` resolved to Jetty 12.x which removed `setResourceBase()`)

**Patch:** `modernization-results/patches/monolith-enterprise.patch` (updated)

---

### 2. Apache OFBiz ⚠️ REQUIRES GRADLE DEPENDENCY UPDATES

**Build System:** Gradle (build.gradle)
**Jakarta APIs Used:** `jakarta.activation`, `jakarta.jms`, `jakarta.mail`, `jakarta.transaction`

OFBiz resolves dependencies transitively through Gradle. The build.gradle loads JARs from component `lib/` directories and Gradle dependency resolution. The javax→jakarta migration requires adding explicit Jakarta EE dependencies to the root `build.gradle`.

**Required Changes to `build.gradle` dependencies block:**

```groovy
dependencies {
    // Jakarta EE dependencies (replacing transitive javax dependencies)
    implementation 'jakarta.activation:jakarta.activation-api:2.1.3'
    implementation 'jakarta.mail:jakarta.mail-api:2.1.3'
    implementation 'org.eclipse.angus:angus-mail:2.0.3'
    implementation 'jakarta.jms:jakarta.jms-api:3.1.0'
    implementation 'jakarta.transaction:jakarta.transaction-api:2.0.1'
}
```

**Build Verification Command:**
```bash
cd modernization-corpus-aggregate/apache-ofbiz
./gradlew classes
```

---

### 3. Alfresco Community ✅ NO CHANGES NEEDED

**Build System:** Maven (pom.xml)
**Jakarta APIs Used:** `jakarta.annotation.concurrent.NotThreadSafe`, `jakarta.transaction.xa.*`

Alfresco's pom.xml already declares correct Jakarta dependency versions:
- `jakarta.transaction:jakarta.transaction-api:2.0.1`
- `jakarta.annotation:jakarta.annotation-api:3.0.0`
- `jakarta.jms:jakarta.jms-api:3.1.0`
- `jakarta.mail:jakarta.mail-api:2.0.2`
- `jakarta.activation:jakarta.activation-api:2.0.1`

The patch only changes 2 import statements that are already covered by existing dependencies.

**Build Verification Command:**
```bash
cd modernization-corpus-aggregate/alfresco-community
mvn compile -pl core,data-model -DskipTests
```

---

### 4. Nuxeo ✅ NO CHANGES NEEDED

**Build System:** Maven (pom.xml, multi-module)
**Jakarta APIs Used:** `jakarta.transaction.xa.*`

Nuxeo is already a Jakarta EE native project:
- Uses Tomcat 10.1.50 (Jakarta Servlet 6.0)
- Uses Jersey 3.1.11 (Jakarta REST)
- JTA (`jakarta.transaction.xa`) is provided transitively by Tomcat and the Nuxeo runtime

The patch only changes 3 import statements in test files that are covered by existing transitive dependencies.

**Build Verification Command:**
```bash
cd modernization-corpus-aggregate/nuxeo
mvn compile -pl modules/core/nuxeo-core-event -DskipTests
```

---

### 5. B2CWeb ⚠️ REQUIRES BUILD SYSTEM CREATION

**Build System:** None (legacy Chinese e-commerce application)
**Jakarta APIs Used:** `jakarta.servlet`, `jakarta.persistence`, `jakarta.mail`, `jakarta.annotation`

B2CWeb is a legacy Java web application with no build system (no pom.xml, no build.gradle). Source code lives under `Shop/src/` with compiled classes under `Shop/build/`. Dependencies were historically managed by copying JARs into `WebContent/WEB-INF/lib/`.

**Recommended Fix:** Create a `pom.xml` to formalize dependency management:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.cn.shop</groupId>
    <artifactId>b2cweb</artifactId>
    <version>1.0.0</version>
    <packaging>war</packaging>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>jakarta.servlet</groupId>
            <artifactId>jakarta.servlet-api</artifactId>
            <version>6.0.0</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>jakarta.persistence</groupId>
            <artifactId>jakarta.persistence-api</artifactId>
            <version>3.1.0</version>
        </dependency>
        <dependency>
            <groupId>jakarta.mail</groupId>
            <artifactId>jakarta.mail-api</artifactId>
            <version>2.1.3</version>
        </dependency>
        <dependency>
            <groupId>org.eclipse.angus</groupId>
            <artifactId>angus-mail</artifactId>
            <version>2.0.3</version>
        </dependency>
        <dependency>
            <groupId>jakarta.annotation</groupId>
            <artifactId>jakarta.annotation-api</artifactId>
            <version>3.0.0</version>
        </dependency>
        <dependency>
            <groupId>org.hibernate.orm</groupId>
            <artifactId>hibernate-core</artifactId>
            <version>6.4.0.Final</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-webmvc</artifactId>
            <version>6.1.0</version>
        </dependency>
    </dependencies>
</project>
```

**Build Verification Command:**
```bash
cd modernization-corpus-aggregate/b2cweb/Shop
mvn compile -DskipTests
```

---

## Summary

| System | Build System | Jakarta Fix Status | Effort |
|--------|-------------|-------------------|--------|
| Monolith Enterprise | Maven | ✅ Fixed & Verified | Complete |
| Apache OFBiz | Gradle | ⚠️ Requires 5 dependency additions | Low |
| Alfresco Community | Maven | ✅ No changes needed | None |
| Nuxeo | Maven | ✅ No changes needed | None |
| B2CWeb | None | ⚠️ Requires pom.xml creation | Medium |

## Key Lessons Learned

1. **Namespace migration requires version migration:** Jakarta EE artifacts use completely different version numbers than javax. For example, `javax.ws.rs:javax.ws.rs-api:2.0` becomes `jakarta.ws.rs:jakarta.ws.rs-api:3.1.0`.

2. **Artifact ID changes:** Some artifacts changed both group ID and artifact ID (e.g., `javax.validation:validation-api` → `jakarta.validation:jakarta.validation-api`).

3. **Transitive dependency awareness:** Some projects (Alfresco, Nuxeo) already have Jakarta dependencies because their frameworks migrated upstream.

4. **Build system compatibility:** Jetty 12.x removed APIs that older code depends on — always pin Jetty to 11.x for Jakarta EE 9/10 compatibility.
