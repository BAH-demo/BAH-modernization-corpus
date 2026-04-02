/**
 * Minimal C test framework (similar to Unity/MinUnit).
 * Provides basic assertion macros and test runner.
 */

#ifndef TEST_FRAMEWORK_H
#define TEST_FRAMEWORK_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

static int tests_run = 0;
static int tests_passed = 0;
static int tests_failed = 0;

#define TEST_ASSERT(condition, message) do { \
    if (!(condition)) { \
        printf("  FAIL: %s (line %d)\n", message, __LINE__); \
        tests_failed++; \
        return; \
    } \
} while(0)

#define TEST_ASSERT_EQUAL_INT(expected, actual, message) do { \
    if ((expected) != (actual)) { \
        printf("  FAIL: %s - expected %d, got %d (line %d)\n", \
               message, (int)(expected), (int)(actual), __LINE__); \
        tests_failed++; \
        return; \
    } \
} while(0)

#define TEST_ASSERT_EQUAL_DOUBLE(expected, actual, tolerance, message) do { \
    double _diff = fabs((double)(expected) - (double)(actual)); \
    if (_diff > (tolerance)) { \
        printf("  FAIL: %s - expected %.15g, got %.15g (diff=%.2e, tol=%.2e) (line %d)\n", \
               message, (double)(expected), (double)(actual), _diff, (double)(tolerance), __LINE__); \
        tests_failed++; \
        return; \
    } \
} while(0)

#define TEST_ASSERT_TRUE(condition, message) \
    TEST_ASSERT(condition, message)

#define TEST_ASSERT_FALSE(condition, message) \
    TEST_ASSERT(!(condition), message)

#define RUN_TEST(test_func) do { \
    tests_run++; \
    printf("  Running: %s\n", #test_func); \
    test_func(); \
    if (tests_run == tests_passed + tests_failed + 1) { \
        tests_passed++; \
        printf("  PASS: %s\n", #test_func); \
    } else { \
        tests_passed = tests_run - tests_failed - 1 + (tests_run > tests_passed + tests_failed ? 0 : 0); \
    } \
} while(0)

/* Simpler version that properly counts */
static void run_test_impl(void (*test_func)(void), const char *name) {
    int failed_before = tests_failed;
    tests_run++;
    printf("  Running: %s\n", name);
    test_func();
    if (tests_failed == failed_before) {
        tests_passed++;
        printf("  PASS: %s\n", name);
    }
}

#define RUN(func) run_test_impl(func, #func)

#define TEST_SUMMARY() do { \
    printf("\n========================================\n"); \
    printf("Tests: %d run, %d passed, %d failed\n", tests_run, tests_passed, tests_failed); \
    printf("========================================\n"); \
} while(0)

#endif /* TEST_FRAMEWORK_H */
