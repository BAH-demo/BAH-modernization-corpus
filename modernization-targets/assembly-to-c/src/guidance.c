/**
 * Guidance Equation Implementation
 *
 * Modernized from AGC guidance assembly routines in the Apollo 11
 * Luminary099 source code. Key routines translated:
 *
 *   LAMBERT    - Lambert targeting (transfer orbit calculation)
 *   MIDGIM     - Midcourse guidance
 *   CALCRVG    - Calculate required velocity for guidance
 *   CROSS      - Vector cross product
 *   DOT        - Vector dot product
 *   UNIT       - Vector normalization
 *
 * The original AGC code used:
 *   - Fixed-point arithmetic (15-bit + sign)
 *   - Interpretive language for complex math
 *   - Registers A, L, Q for computation
 *   - Double precision via paired words
 *
 * This C implementation uses IEEE 754 double precision throughout
 * for clarity and accuracy.
 */

#define _GNU_SOURCE
#include "guidance.h"
#include <math.h>
#include <stdlib.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* Gravitational parameter for Earth (m^3/s^2) */
#define MU_EARTH    3.986004418e14

/* Gravitational parameter for Moon (m^3/s^2) */
#define MU_MOON     4.9048695e12

/* Convergence tolerance for iterative solutions */
#define GUIDANCE_TOLERANCE  1e-10

/* Maximum iterations for Lambert solver */
#define MAX_ITERATIONS      50

/**
 * Vector cross product: c = a x b
 *
 * Replaces AGC CROSS subroutine:
 *   VXSC    A cross B
 *   Store result in MPAC
 */
vector3_t cross_product(const vector3_t *a, const vector3_t *b) {
    vector3_t result;
    result.x = a->y * b->z - a->z * b->y;
    result.y = a->z * b->x - a->x * b->z;
    result.z = a->x * b->y - a->y * b->x;
    return result;
}

/**
 * Vector dot product: result = a . b
 *
 * Replaces AGC DOT subroutine
 */
double dot_product(const vector3_t *a, const vector3_t *b) {
    return a->x * b->x + a->y * b->y + a->z * b->z;
}

/**
 * Vector magnitude: |v|
 *
 * Replaces AGC ABVAL subroutine
 */
double vector_magnitude(const vector3_t *v) {
    return sqrt(dot_product(v, v));
}

/**
 * Normalize vector to unit length.
 *
 * Replaces AGC UNIT subroutine:
 *   UNIT    MPAC
 *   Returns unit vector in MPAC
 */
vector3_t vector_normalize(const vector3_t *v) {
    double mag = vector_magnitude(v);
    vector3_t result;

    if (mag < 1e-15) {
        result.x = result.y = result.z = 0.0;
        return result;
    }

    result.x = v->x / mag;
    result.y = v->y / mag;
    result.z = v->z / mag;
    return result;
}

/**
 * Vector addition: result = a + b
 *
 * Replaces AGC VAD subroutine
 */
vector3_t vector_add(const vector3_t *a, const vector3_t *b) {
    vector3_t result;
    result.x = a->x + b->x;
    result.y = a->y + b->y;
    result.z = a->z + b->z;
    return result;
}

/**
 * Vector subtraction: result = a - b
 *
 * Replaces AGC VSU subroutine
 */
vector3_t vector_subtract(const vector3_t *a, const vector3_t *b) {
    vector3_t result;
    result.x = a->x - b->x;
    result.y = a->y - b->y;
    result.z = a->z - b->z;
    return result;
}

/**
 * Scale vector: result = v * scalar
 *
 * Replaces AGC VXSC subroutine
 */
vector3_t vector_scale(const vector3_t *v, double scalar) {
    vector3_t result;
    result.x = v->x * scalar;
    result.y = v->y * scalar;
    result.z = v->z * scalar;
    return result;
}

/**
 * Compute specific orbital energy: E = v^2/2 - mu/r
 */
double compute_orbital_energy(const state_vector_t *state, double mu) {
    double r = vector_magnitude(&state->position);
    double v = vector_magnitude(&state->velocity);
    return 0.5 * v * v - mu / r;
}

/**
 * Compute semi-major axis from orbital energy.
 *   a = -mu / (2*E)
 */
double compute_semi_major_axis(double energy, double mu) {
    if (fabs(energy) < 1e-15) {
        return 1e15;  /* Parabolic orbit */
    }
    return -mu / (2.0 * energy);
}

/**
 * Compute specific angular momentum vector: h = r x v
 */
vector3_t compute_angular_momentum(const state_vector_t *state) {
    return cross_product(&state->position, &state->velocity);
}

/**
 * Stumpff function c2(psi).
 * Used in universal variable formulation of Lambert's problem.
 */
static double stumpff_c2(double psi) {
    if (fabs(psi) < 1e-6) {
        return 1.0 / 2.0;
    }
    if (psi > 0) {
        double sqrt_psi = sqrt(psi);
        return (1.0 - cos(sqrt_psi)) / psi;
    } else {
        double sqrt_neg_psi = sqrt(-psi);
        return (cosh(sqrt_neg_psi) - 1.0) / (-psi);
    }
}

/**
 * Stumpff function c3(psi).
 */
static double stumpff_c3(double psi) {
    if (fabs(psi) < 1e-6) {
        return 1.0 / 6.0;
    }
    if (psi > 0) {
        double sqrt_psi = sqrt(psi);
        return (sqrt_psi - sin(sqrt_psi)) / (psi * sqrt_psi);
    } else {
        double sqrt_neg_psi = sqrt(-psi);
        return (sinh(sqrt_neg_psi) - sqrt_neg_psi) / ((-psi) * sqrt_neg_psi);
    }
}

/**
 * Compute Lambert guidance solution.
 *
 * Implements a simplified Lambert targeting algorithm to determine
 * the required delta-V to transfer from current state to target.
 *
 * This replaces the AGC's LAMBERT and CALCRVG routines which used
 * the interpretive language for the iterative calculations.
 *
 * Method: Universal variable formulation with Newton-Raphson iteration.
 */
guidance_solution_t compute_lambert_guidance(
    const state_vector_t *current_state,
    const guidance_target_t *target
) {
    guidance_solution_t solution;
    solution.solution_valid = false;
    solution.delta_v.x = solution.delta_v.y = solution.delta_v.z = 0.0;
    solution.delta_v_magnitude = 0.0;
    solution.time_to_ignition = 0.0;
    solution.burn_duration = 0.0;

    double mu = MU_EARTH;
    double tof = target->time_of_flight;

    if (tof <= 0.0) {
        return solution;
    }

    /* Position magnitudes */
    double r1_mag = vector_magnitude(&current_state->position);
    double r2_mag = vector_magnitude(&target->target_position);

    if (r1_mag < 1e-6 || r2_mag < 1e-6) {
        return solution;
    }

    /* Cosine of transfer angle */
    double cos_dnu = dot_product(&current_state->position, &target->target_position)
                     / (r1_mag * r2_mag);

    /* Cross product to determine direction */
    vector3_t h_cross = cross_product(&current_state->position, &target->target_position);
    double sin_dnu_sign = (h_cross.z >= 0.0) ? 1.0 : -1.0;

    /* A parameter for Lambert's equation */
    double sin_dnu = sin_dnu_sign * sqrt(1.0 - cos_dnu * cos_dnu);
    double A = sin_dnu * sqrt(r1_mag * r2_mag / (1.0 - cos_dnu));

    if (fabs(A) < 1e-10) {
        return solution;  /* Degenerate case */
    }

    /* Newton-Raphson iteration on universal variable z */
    double z = 0.0;  /* Initial guess (parabolic) */
    double z_low = -4.0 * M_PI * M_PI;
    double z_high = 4.0 * M_PI * M_PI;

    for (int iter = 0; iter < MAX_ITERATIONS; iter++) {
        double c2 = stumpff_c2(z);
        double c3 = stumpff_c3(z);

        double y = r1_mag + r2_mag + A * (z * c3 - 1.0) / sqrt(c2);

        if (y < 0.0) {
            /* Adjust bounds */
            z_low = z;
            z = (z_low + z_high) / 2.0;
            continue;
        }

        double chi = sqrt(y / c2);
        double F = chi * chi * chi * c3 + A * sqrt(y) - sqrt(mu) * tof;

        if (fabs(F) < GUIDANCE_TOLERANCE * sqrt(mu)) {
            /* Converged! Compute velocities */
            double f = 1.0 - y / r1_mag;
            double g = A * sqrt(y / mu);

            /* v1 = (r2 - f*r1) / g */
            vector3_t fr1 = vector_scale(&current_state->position, f);
            vector3_t r2_minus_fr1 = vector_subtract(&target->target_position, &fr1);
            vector3_t v1_transfer = vector_scale(&r2_minus_fr1, 1.0 / g);

            /* Delta-V = v1_transfer - v1_current */
            solution.delta_v = vector_subtract(&v1_transfer, &current_state->velocity);
            solution.delta_v_magnitude = vector_magnitude(&solution.delta_v);
            solution.time_to_ignition = 0.0;

            /* Estimate burn duration (assuming constant thrust) */
            if (current_state->mass > 0.0) {
                /* Using Tsiolkovsky equation approximation */
                solution.burn_duration = solution.delta_v_magnitude * current_state->mass / 45000.0;
            }

            solution.solution_valid = true;
            return solution;
        }

        /* Newton-Raphson update */
        double dF;
        if (fabs(z) > 1e-6) {
            dF = (chi * chi * chi * (c3 - 3.0 * c2 * c3 / (2.0 * c2)) + A / (8.0)) *
                 (1.0 / sqrt(mu));
        } else {
            dF = (sqrt(2.0) / 40.0) * y * y * y / 2.0 + A / 8.0 *
                 (sqrt(y) + A * sqrt(1.0 / (2.0 * y)));
            dF /= sqrt(mu);
        }

        if (fabs(dF) < 1e-15) break;

        double z_new = z - F / dF;

        /* Bisection fallback */
        if (z_new < z_low || z_new > z_high) {
            z_new = (z_low + z_high) / 2.0;
        }

        if (F < 0.0) {
            z_low = z;
        } else {
            z_high = z;
        }

        z = z_new;
    }

    return solution;  /* Did not converge */
}
