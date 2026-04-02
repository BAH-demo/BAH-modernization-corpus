/**
 * AGC Fixed-Point Arithmetic Library
 *
 * Implements the Apollo Guidance Computer's 15-bit + sign
 * ones' complement fixed-point arithmetic.
 *
 * The AGC used ones' complement, meaning:
 *   - Positive zero: 00000000000000 (0x0000)
 *   - Negative zero: 11111111111111 (0x3FFF with sign = 0x7FFF)
 *   - Negation: bitwise complement of all 15 bits
 *   - Addition: binary add with end-around carry
 *
 * Fixed-point format: values represent fractions in [-1, +1)
 *   1.0   is represented as 0x3FFF (max positive)
 *   0.5   is represented as 0x2000
 *   -0.5  is represented as 0x5FFF (ones' complement of 0x2000)
 *   0.0   is represented as 0x0000
 */

#include "fixed_point.h"

/**
 * Add two AGC single-precision values with end-around carry.
 *
 * In AGC ones' complement addition:
 * 1. Perform binary addition on the 15-bit values
 * 2. If carry out of bit 14, add 1 to result (end-around carry)
 * 3. Handle overflow detection
 *
 * Replaces AGC instructions: AD (Add), ADS (Add to Storage)
 */
agc_word_t agc_add(agc_word_t a, agc_word_t b) {
    /* Convert from ones' complement to two's complement for computation */
    double da = agc_sp_to_double(a);
    double db = agc_sp_to_double(b);
    double result = da + db;

    /* Clamp to AGC range */
    if (result >= 1.0) result = 1.0 - (1.0 / AGC_SCALE_FACTOR);
    if (result <= -1.0) result = -1.0 + (1.0 / AGC_SCALE_FACTOR);

    return double_to_agc_sp(result);
}

/**
 * Subtract: a - b
 * Replaces AGC instruction sequence: CS B, AD A (complement and add)
 */
agc_word_t agc_subtract(agc_word_t a, agc_word_t b) {
    double da = agc_sp_to_double(a);
    double db = agc_sp_to_double(b);
    double result = da - db;

    if (result >= 1.0) result = 1.0 - (1.0 / AGC_SCALE_FACTOR);
    if (result <= -1.0) result = -1.0 + (1.0 / AGC_SCALE_FACTOR);

    return double_to_agc_sp(result);
}

/**
 * Multiply two AGC single-precision values.
 *
 * AGC multiplication produced a double-precision result in A,L registers.
 * This function returns only the high-order (single precision) result,
 * matching the common usage pattern.
 *
 * Replaces AGC instruction: MP (Multiply)
 */
agc_word_t agc_multiply(agc_word_t a, agc_word_t b) {
    double da = agc_sp_to_double(a);
    double db = agc_sp_to_double(b);
    double result = da * db;

    /* Multiplication of two fractional values stays in range */
    return double_to_agc_sp(result);
}

/**
 * Divide: dividend / divisor
 *
 * AGC division required |dividend| < |divisor| to avoid overflow.
 * The result is a fraction in [-1, +1).
 *
 * Replaces AGC instruction: DV (Divide)
 */
agc_word_t agc_divide(agc_word_t dividend, agc_word_t divisor) {
    double dd = agc_sp_to_double(dividend);
    double ds = agc_sp_to_double(divisor);

    /* Check for division by zero */
    if (agc_is_zero(divisor)) {
        /* AGC would overflow - return max positive or negative */
        return agc_is_negative(dividend) ?
            (agc_word_t)(-AGC_MAX_POS) : (agc_word_t)AGC_MAX_POS;
    }

    double result = dd / ds;

    /* Clamp to representable range */
    if (result >= 1.0) result = 1.0 - (1.0 / AGC_SCALE_FACTOR);
    if (result <= -1.0) result = -1.0 + (1.0 / AGC_SCALE_FACTOR);

    return double_to_agc_sp(result);
}

/**
 * Negate: return -a in ones' complement.
 * Replaces AGC instruction: CS (Clear and Subtract)
 */
agc_word_t agc_negate(agc_word_t a) {
    double da = agc_sp_to_double(a);
    return double_to_agc_sp(-da);
}

/**
 * Absolute value.
 * Replaces AGC instruction sequence: CCS A (Count, Compare, and Skip)
 * followed by conditional complement.
 */
agc_word_t agc_abs(agc_word_t a) {
    double da = agc_sp_to_double(a);
    if (da < 0) da = -da;
    return double_to_agc_sp(da);
}

/**
 * Ones' complement (bitwise NOT of 15 bits).
 * Replaces AGC instruction: COM (Complement)
 */
agc_word_t agc_complement(agc_word_t a) {
    return agc_negate(a);
}

/**
 * Double-precision add.
 * Replaces AGC instruction sequence: DCA, DAD
 */
agc_double_t agc_dp_add(agc_double_t a, agc_double_t b) {
    double da = agc_dp_to_double(a);
    double db = agc_dp_to_double(b);
    double result = da + db;

    if (result >= 1.0) result = 1.0 - (1.0 / AGC_DP_SCALE_FACTOR);
    if (result <= -1.0) result = -1.0 + (1.0 / AGC_DP_SCALE_FACTOR);

    return double_to_agc_dp(result);
}

/**
 * Double-precision subtract.
 * Replaces AGC instruction sequence: DCA, DSU
 */
agc_double_t agc_dp_subtract(agc_double_t a, agc_double_t b) {
    double da = agc_dp_to_double(a);
    double db = agc_dp_to_double(b);
    double result = da - db;

    if (result >= 1.0) result = 1.0 - (1.0 / AGC_DP_SCALE_FACTOR);
    if (result <= -1.0) result = -1.0 + (1.0 / AGC_DP_SCALE_FACTOR);

    return double_to_agc_dp(result);
}

/**
 * Double-precision multiply.
 * Replaces AGC instruction: DMP
 */
agc_double_t agc_dp_multiply(agc_double_t a, agc_double_t b) {
    double da = agc_dp_to_double(a);
    double db = agc_dp_to_double(b);
    double result = da * db;

    return double_to_agc_dp(result);
}

/**
 * Convert AGC angle word to degrees.
 * AGC angles: full circle = 2^14 units, so 1 unit = 360/16384 degrees.
 */
double agc_to_degrees(agc_word_t angle) {
    return agc_sp_to_double(angle) * 360.0;
}

/**
 * Convert degrees to AGC angle word.
 */
agc_word_t degrees_to_agc(double degrees) {
    /* Normalize to [0, 360) */
    while (degrees >= 360.0) degrees -= 360.0;
    while (degrees < 0.0) degrees += 360.0;

    return double_to_agc_sp(degrees / 360.0);
}

/**
 * Check if AGC word is negative.
 */
bool agc_is_negative(agc_word_t a) {
    return agc_sp_to_double(a) < 0.0;
}

/**
 * Check if AGC word is zero (positive or negative zero).
 */
bool agc_is_zero(agc_word_t a) {
    uint16_t uword = (uint16_t)a & AGC_WORD_MASK;
    return uword == AGC_ZERO_POS || uword == AGC_WORD_MASK;
}

/**
 * Compare two AGC words. Returns -1, 0, or 1.
 */
int agc_compare(agc_word_t a, agc_word_t b) {
    double da = agc_sp_to_double(a);
    double db = agc_sp_to_double(b);
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}
