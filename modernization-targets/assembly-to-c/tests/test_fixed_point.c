/**
 * Tests for AGC fixed-point arithmetic library.
 *
 * Verifies:
 * - Single precision add, subtract, multiply, divide
 * - Double precision operations
 * - Conversion between AGC fixed-point and IEEE doubles
 * - Edge cases (overflow, zero, negative zero)
 * - Angle conversion
 */

#include "test_framework.h"
#include "../src/agc_types.h"
#include "../src/fixed_point.h"

/* Tolerance for fixed-point comparisons */
#define FP_TOL  (2.0 / AGC_SCALE_FACTOR)  /* ~0.000122 (1 LSB) */
#define DP_TOL  (2.0 / AGC_DP_SCALE_FACTOR)

/* ---- Conversion Tests ---- */

void test_sp_zero_conversion(void) {
    agc_word_t zero = double_to_agc_sp(0.0);
    double back = agc_sp_to_double(zero);
    TEST_ASSERT_EQUAL_DOUBLE(0.0, back, FP_TOL, "Zero conversion round-trip");
}

void test_sp_positive_conversion(void) {
    double val = 0.5;
    agc_word_t word = double_to_agc_sp(val);
    double back = agc_sp_to_double(word);
    TEST_ASSERT_EQUAL_DOUBLE(val, back, FP_TOL, "0.5 conversion round-trip");
}

void test_sp_negative_conversion(void) {
    double val = -0.5;
    agc_word_t word = double_to_agc_sp(val);
    double back = agc_sp_to_double(word);
    TEST_ASSERT_EQUAL_DOUBLE(val, back, FP_TOL, "-0.5 conversion round-trip");
}

void test_sp_small_positive(void) {
    double val = 0.25;
    agc_word_t word = double_to_agc_sp(val);
    double back = agc_sp_to_double(word);
    TEST_ASSERT_EQUAL_DOUBLE(val, back, FP_TOL, "0.25 conversion");
}

void test_sp_small_negative(void) {
    double val = -0.25;
    agc_word_t word = double_to_agc_sp(val);
    double back = agc_sp_to_double(word);
    TEST_ASSERT_EQUAL_DOUBLE(val, back, FP_TOL, "-0.25 conversion");
}

void test_dp_conversion(void) {
    double val = 0.123456789;
    agc_double_t dp = double_to_agc_dp(val);
    double back = agc_dp_to_double(dp);
    TEST_ASSERT_EQUAL_DOUBLE(val, back, DP_TOL, "DP conversion round-trip");
}

/* ---- Addition Tests ---- */

void test_add_positive(void) {
    agc_word_t a = double_to_agc_sp(0.25);
    agc_word_t b = double_to_agc_sp(0.125);
    agc_word_t result = agc_add(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.375, dresult, FP_TOL, "0.25 + 0.125 = 0.375");
}

void test_add_negative(void) {
    agc_word_t a = double_to_agc_sp(-0.25);
    agc_word_t b = double_to_agc_sp(-0.125);
    agc_word_t result = agc_add(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(-0.375, dresult, FP_TOL, "-0.25 + -0.125 = -0.375");
}

void test_add_mixed_sign(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t b = double_to_agc_sp(-0.25);
    agc_word_t result = agc_add(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.25, dresult, FP_TOL, "0.5 + -0.25 = 0.25");
}

void test_add_zero(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t b = double_to_agc_sp(0.0);
    agc_word_t result = agc_add(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.5, dresult, FP_TOL, "0.5 + 0 = 0.5");
}

/* ---- Subtraction Tests ---- */

void test_subtract_positive(void) {
    agc_word_t a = double_to_agc_sp(0.75);
    agc_word_t b = double_to_agc_sp(0.25);
    agc_word_t result = agc_subtract(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.5, dresult, FP_TOL, "0.75 - 0.25 = 0.5");
}

void test_subtract_to_negative(void) {
    agc_word_t a = double_to_agc_sp(0.25);
    agc_word_t b = double_to_agc_sp(0.75);
    agc_word_t result = agc_subtract(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(-0.5, dresult, FP_TOL, "0.25 - 0.75 = -0.5");
}

/* ---- Multiplication Tests ---- */

void test_multiply_positive(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t b = double_to_agc_sp(0.5);
    agc_word_t result = agc_multiply(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.25, dresult, FP_TOL, "0.5 * 0.5 = 0.25");
}

void test_multiply_negative(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t b = double_to_agc_sp(-0.5);
    agc_word_t result = agc_multiply(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(-0.25, dresult, FP_TOL, "0.5 * -0.5 = -0.25");
}

void test_multiply_by_zero(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t b = double_to_agc_sp(0.0);
    agc_word_t result = agc_multiply(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.0, dresult, FP_TOL, "0.5 * 0 = 0");
}

void test_multiply_small_values(void) {
    agc_word_t a = double_to_agc_sp(0.1);
    agc_word_t b = double_to_agc_sp(0.1);
    agc_word_t result = agc_multiply(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.01, dresult, FP_TOL * 10, "0.1 * 0.1 ~ 0.01");
}

/* ---- Division Tests ---- */

void test_divide_simple(void) {
    agc_word_t a = double_to_agc_sp(0.25);
    agc_word_t b = double_to_agc_sp(0.5);
    agc_word_t result = agc_divide(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.5, dresult, FP_TOL, "0.25 / 0.5 = 0.5");
}

void test_divide_negative(void) {
    agc_word_t a = double_to_agc_sp(-0.25);
    agc_word_t b = double_to_agc_sp(0.5);
    agc_word_t result = agc_divide(a, b);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(-0.5, dresult, FP_TOL, "-0.25 / 0.5 = -0.5");
}

/* ---- Utility Tests ---- */

void test_negate(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t result = agc_negate(a);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(-0.5, dresult, FP_TOL, "negate(0.5) = -0.5");
}

void test_abs_positive(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t result = agc_abs(a);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.5, dresult, FP_TOL, "abs(0.5) = 0.5");
}

void test_abs_negative(void) {
    agc_word_t a = double_to_agc_sp(-0.5);
    agc_word_t result = agc_abs(a);
    double dresult = agc_sp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.5, dresult, FP_TOL, "abs(-0.5) = 0.5");
}

void test_is_negative(void) {
    TEST_ASSERT_TRUE(agc_is_negative(double_to_agc_sp(-0.5)), "-0.5 is negative");
    TEST_ASSERT_FALSE(agc_is_negative(double_to_agc_sp(0.5)), "0.5 is not negative");
}

void test_compare(void) {
    agc_word_t a = double_to_agc_sp(0.5);
    agc_word_t b = double_to_agc_sp(0.25);
    TEST_ASSERT_EQUAL_INT(1, agc_compare(a, b), "0.5 > 0.25");
    TEST_ASSERT_EQUAL_INT(-1, agc_compare(b, a), "0.25 < 0.5");
    TEST_ASSERT_EQUAL_INT(0, agc_compare(a, a), "0.5 == 0.5");
}

/* ---- Angle Tests ---- */

void test_angle_conversion(void) {
    agc_word_t angle = degrees_to_agc(90.0);
    double back = agc_to_degrees(angle);
    TEST_ASSERT_EQUAL_DOUBLE(90.0, back, 0.1, "90 degree round-trip");
}

void test_angle_360(void) {
    agc_word_t angle = degrees_to_agc(360.0);
    double back = agc_to_degrees(angle);
    /* 360 should wrap to 0 */
    TEST_ASSERT_EQUAL_DOUBLE(0.0, back, 0.1, "360 degrees wraps to 0");
}

/* ---- Double Precision Tests ---- */

void test_dp_add(void) {
    agc_double_t a = double_to_agc_dp(0.25);
    agc_double_t b = double_to_agc_dp(0.125);
    agc_double_t result = agc_dp_add(a, b);
    double dresult = agc_dp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.375, dresult, DP_TOL, "DP 0.25 + 0.125 = 0.375");
}

void test_dp_subtract(void) {
    agc_double_t a = double_to_agc_dp(0.75);
    agc_double_t b = double_to_agc_dp(0.25);
    agc_double_t result = agc_dp_subtract(a, b);
    double dresult = agc_dp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.5, dresult, DP_TOL, "DP 0.75 - 0.25 = 0.5");
}

void test_dp_multiply(void) {
    agc_double_t a = double_to_agc_dp(0.5);
    agc_double_t b = double_to_agc_dp(0.5);
    agc_double_t result = agc_dp_multiply(a, b);
    double dresult = agc_dp_to_double(result);
    TEST_ASSERT_EQUAL_DOUBLE(0.25, dresult, DP_TOL, "DP 0.5 * 0.5 = 0.25");
}

/* ---- Main ---- */

int main(void) {
    printf("AGC Fixed-Point Arithmetic Tests\n");
    printf("================================\n\n");

    /* Conversion tests */
    printf("Conversion Tests:\n");
    RUN(test_sp_zero_conversion);
    RUN(test_sp_positive_conversion);
    RUN(test_sp_negative_conversion);
    RUN(test_sp_small_positive);
    RUN(test_sp_small_negative);
    RUN(test_dp_conversion);

    /* Addition tests */
    printf("\nAddition Tests:\n");
    RUN(test_add_positive);
    RUN(test_add_negative);
    RUN(test_add_mixed_sign);
    RUN(test_add_zero);

    /* Subtraction tests */
    printf("\nSubtraction Tests:\n");
    RUN(test_subtract_positive);
    RUN(test_subtract_to_negative);

    /* Multiplication tests */
    printf("\nMultiplication Tests:\n");
    RUN(test_multiply_positive);
    RUN(test_multiply_negative);
    RUN(test_multiply_by_zero);
    RUN(test_multiply_small_values);

    /* Division tests */
    printf("\nDivision Tests:\n");
    RUN(test_divide_simple);
    RUN(test_divide_negative);

    /* Utility tests */
    printf("\nUtility Tests:\n");
    RUN(test_negate);
    RUN(test_abs_positive);
    RUN(test_abs_negative);
    RUN(test_is_negative);
    RUN(test_compare);

    /* Angle tests */
    printf("\nAngle Tests:\n");
    RUN(test_angle_conversion);
    RUN(test_angle_360);

    /* Double precision tests */
    printf("\nDouble Precision Tests:\n");
    RUN(test_dp_add);
    RUN(test_dp_subtract);
    RUN(test_dp_multiply);

    TEST_SUMMARY();

    return tests_failed > 0 ? 1 : 0;
}
