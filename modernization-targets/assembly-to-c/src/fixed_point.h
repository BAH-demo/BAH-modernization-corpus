/**
 * AGC Fixed-Point Arithmetic Library - Header
 *
 * Provides fixed-point arithmetic operations matching the AGC's
 * 15-bit + sign ones' complement arithmetic.
 */

#ifndef FIXED_POINT_H
#define FIXED_POINT_H

#include "agc_types.h"

/* Single precision operations */
agc_word_t agc_add(agc_word_t a, agc_word_t b);
agc_word_t agc_subtract(agc_word_t a, agc_word_t b);
agc_word_t agc_multiply(agc_word_t a, agc_word_t b);
agc_word_t agc_divide(agc_word_t dividend, agc_word_t divisor);
agc_word_t agc_negate(agc_word_t a);
agc_word_t agc_abs(agc_word_t a);
agc_word_t agc_complement(agc_word_t a);

/* Double precision operations */
agc_double_t agc_dp_add(agc_double_t a, agc_double_t b);
agc_double_t agc_dp_subtract(agc_double_t a, agc_double_t b);
agc_double_t agc_dp_multiply(agc_double_t a, agc_double_t b);

/* Conversion and utility */
double agc_to_degrees(agc_word_t angle);
agc_word_t degrees_to_agc(double degrees);
bool agc_is_negative(agc_word_t a);
bool agc_is_zero(agc_word_t a);
int agc_compare(agc_word_t a, agc_word_t b);

#endif /* FIXED_POINT_H */
