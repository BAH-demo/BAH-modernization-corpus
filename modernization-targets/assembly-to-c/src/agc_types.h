/**
 * AGC Type Definitions - matching Apollo Guidance Computer word format.
 *
 * The AGC used a 15-bit word with a sign bit (ones' complement arithmetic).
 * Memory was organized as:
 *   - Erasable memory: 2048 words (8 banks of 256)
 *   - Fixed memory: 36,864 words (36 banks of 1024)
 *   - I/O channels: 512 words
 *
 * Word format: [S|B14|B13|...|B1] where S = sign bit
 *
 * Double precision used two consecutive words (SP + SP = DP):
 *   High word: [S|B14|...|B1]  (most significant)
 *   Low word:  [0|B14|...|B1]  (least significant, sign = 0)
 */

#ifndef AGC_TYPES_H
#define AGC_TYPES_H

#include <stdint.h>
#include <stdbool.h>

/* AGC word sizes */
#define AGC_WORD_BITS       15
#define AGC_WORD_MASK       0x7FFF    /* 15-bit mask */
#define AGC_SIGN_BIT        0x4000    /* Bit 14 = sign in ones' complement */
#define AGC_MAGNITUDE_MASK  0x3FFF    /* Bits 0-13 = magnitude */
#define AGC_MAX_POS         0x3FFF    /* Maximum positive value: 16383 */
#define AGC_MAX_NEG         0x7FFF    /* Maximum negative value (ones' complement -0) */
#define AGC_ZERO_POS        0x0000    /* Positive zero */
#define AGC_ZERO_NEG        0x7FFF    /* Negative zero (ones' complement) */

/* Scaling constants for fixed-point arithmetic */
#define AGC_SCALE_FACTOR    16384.0   /* 2^14 for single precision */
#define AGC_DP_SCALE_FACTOR 268435456.0  /* 2^28 for double precision */

/* Memory layout */
#define AGC_ERASABLE_SIZE   2048
#define AGC_FIXED_SIZE      36864
#define AGC_IO_CHANNELS     512

/**
 * AGC single-precision word (15 bits + sign).
 * Stored as int16_t for convenience, but only 15 bits are significant.
 */
typedef int16_t agc_word_t;

/**
 * AGC double-precision value (two 15-bit words).
 * Stored as int32_t, representing a 28-bit fixed-point value.
 */
typedef int32_t agc_double_t;

/**
 * AGC unsigned word for addresses and masks.
 */
typedef uint16_t agc_uword_t;

/**
 * AGC accumulator register set.
 * The AGC had a minimal register set:
 *   A  - Accumulator (16 bits including overflow)
 *   L  - Lower accumulator (for double precision)
 *   Q  - Return address register
 *   Z  - Program counter
 *   BB - Bank register (both EBANK and FBANK)
 */
typedef struct {
    agc_word_t a;       /* Accumulator */
    agc_word_t l;       /* Lower accumulator */
    agc_word_t q;       /* Return address */
    agc_uword_t z;      /* Program counter */
    agc_uword_t bb;     /* Bank register */
    bool overflow;       /* Overflow indicator */
    bool interrupts_enabled; /* Interrupt enable flag */
} agc_registers_t;

/**
 * Convert a C double to AGC single-precision fixed-point.
 * AGC fixed-point represents values in range [-1, +1) with 14 fractional bits.
 */
static inline agc_word_t double_to_agc_sp(double value) {
    if (value >= 1.0) return (agc_word_t)AGC_MAX_POS;
    if (value <= -1.0) return (agc_word_t)(-AGC_MAX_POS);

    int16_t raw = (int16_t)(value * AGC_SCALE_FACTOR);
    /* Convert from two's complement to ones' complement */
    if (raw < 0) {
        return (agc_word_t)(AGC_WORD_MASK + raw);  /* ones' complement negative */
    }
    return (agc_word_t)raw;
}

/**
 * Convert AGC single-precision fixed-point to C double.
 */
static inline double agc_sp_to_double(agc_word_t word) {
    uint16_t uword = (uint16_t)word & AGC_WORD_MASK;

    if (uword & AGC_SIGN_BIT) {
        /* Negative: ones' complement -> magnitude */
        uint16_t magnitude = (~uword) & AGC_MAGNITUDE_MASK;
        return -(double)magnitude / AGC_SCALE_FACTOR;
    }
    return (double)uword / AGC_SCALE_FACTOR;
}

/**
 * Convert a C double to AGC double-precision fixed-point.
 * DP uses 28 fractional bits in range [-1, +1).
 */
static inline agc_double_t double_to_agc_dp(double value) {
    if (value >= 1.0) return (agc_double_t)(AGC_DP_SCALE_FACTOR - 1);
    if (value <= -1.0) return (agc_double_t)(-(AGC_DP_SCALE_FACTOR - 1));
    return (agc_double_t)(value * AGC_DP_SCALE_FACTOR);
}

/**
 * Convert AGC double-precision to C double.
 */
static inline double agc_dp_to_double(agc_double_t dp) {
    return (double)dp / AGC_DP_SCALE_FACTOR;
}

#endif /* AGC_TYPES_H */
