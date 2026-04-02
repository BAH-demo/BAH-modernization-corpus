/**
 * Navigation Routines Implementation
 *
 * Modernized from AGC navigation assembly in Luminary099:
 *   - NAVIGATION (state vector maintenance)
 *   - KEPLER (orbital propagation)
 *   - LATITUDE/LONGITUDE (coordinate conversion)
 *   - PIPA (IMU processing - Pulsed Integrating Pendulous Accelerometer)
 *
 * The original AGC maintained state vectors in fixed-point arithmetic
 * with careful scaling to prevent overflow. This C implementation uses
 * double precision IEEE 754.
 */

#define _GNU_SOURCE
#include "navigation.h"
#include <math.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* Earth parameters */
#define EARTH_RADIUS    6371000.0    /* Mean radius (meters) */
#define EARTH_MU        3.986004418e14  /* GM (m^3/s^2) */
#define EARTH_ROTATION  7.2921159e-5    /* Rotation rate (rad/s) */

/* Moon parameters */
#define MOON_RADIUS     1737400.0
#define MOON_MU         4.9048695e12

/* Convergence for Kepler equation */
#define KEPLER_TOL      1e-12
#define KEPLER_MAX_ITER 100

/**
 * Initialize navigation state.
 *
 * Replaces AGC initialization sequence that set up
 * the state vector in erasable memory.
 */
void nav_initialize(nav_state_t *nav, const state_vector_t *initial_state) {
    memcpy(&nav->state, initial_state, sizeof(state_vector_t));
    nav->epoch = initial_state->time;
    nav->coordinate_system = 0;  /* Earth-centered by default */
    nav->last_update_time = initial_state->time;
}

/**
 * Propagate state vector forward by dt seconds using Kepler propagation.
 *
 * Replaces AGC KEPLER subroutine which used the interpretive language
 * for the iterative Kepler equation solution.
 */
void nav_propagate(nav_state_t *nav, double dt) {
    double mu = (nav->coordinate_system == 0) ? EARTH_MU : MOON_MU;
    kepler_propagate(&nav->state, dt, mu);
    nav->state.time += dt;
    nav->last_update_time = nav->state.time;
}

/**
 * Update state vector with IMU (PIPA) readings.
 *
 * Replaces AGC PIPA processing:
 *   The AGC read accelerometer pulses from the PIPAs and
 *   accumulated delta-V to update the state vector.
 *
 *   Original process:
 *   1. Read PIPA counters
 *   2. Compensate for known biases
 *   3. Transform to navigation frame
 *   4. Update velocity: V = V + delta_V
 *   5. Update position: R = R + V*dt + 0.5*delta_V*dt
 */
void nav_update_with_imu(nav_state_t *nav, const imu_reading_t *reading) {
    double dt = reading->delta_t;

    /* Update position (trapezoidal integration) */
    nav->state.position.x += nav->state.velocity.x * dt +
                             0.5 * reading->delta_v_x * dt;
    nav->state.position.y += nav->state.velocity.y * dt +
                             0.5 * reading->delta_v_y * dt;
    nav->state.position.z += nav->state.velocity.z * dt +
                             0.5 * reading->delta_v_z * dt;

    /* Update velocity */
    nav->state.velocity.x += reading->delta_v_x;
    nav->state.velocity.y += reading->delta_v_y;
    nav->state.velocity.z += reading->delta_v_z;

    nav->state.time += dt;
    nav->last_update_time = nav->state.time;
}

/**
 * Compute altitude above reference body.
 *
 * Replaces AGC altitude calculation used for lunar descent guidance.
 */
double nav_compute_altitude(const nav_state_t *nav) {
    double r = vector_magnitude(&nav->state.position);
    double body_radius = (nav->coordinate_system == 0) ? EARTH_RADIUS : MOON_RADIUS;
    return r - body_radius;
}

/**
 * Compute velocity magnitude.
 */
double nav_compute_velocity_magnitude(const nav_state_t *nav) {
    return vector_magnitude(&nav->state.velocity);
}

/**
 * Compute orbital period: T = 2*pi*sqrt(a^3/mu)
 */
double nav_compute_orbital_period(const nav_state_t *nav, double mu) {
    double energy = compute_orbital_energy(&nav->state, mu);
    double a = compute_semi_major_axis(energy, mu);

    if (a <= 0.0) {
        return -1.0;  /* Hyperbolic or parabolic - no period */
    }

    return 2.0 * M_PI * sqrt(a * a * a / mu);
}

/**
 * Convert ECI (Earth-Centered Inertial) to ECEF (Earth-Centered Earth-Fixed).
 *
 * Replaces AGC coordinate transformation routines.
 * ECEF rotates with the Earth, so we need GMST (Greenwich Mean Sidereal Time).
 */
vector3_t eci_to_ecef(const vector3_t *eci_pos, double gmst) {
    vector3_t ecef;
    double cos_g = cos(gmst);
    double sin_g = sin(gmst);

    ecef.x = cos_g * eci_pos->x + sin_g * eci_pos->y;
    ecef.y = -sin_g * eci_pos->x + cos_g * eci_pos->y;
    ecef.z = eci_pos->z;

    return ecef;
}

/**
 * Compute GMST from Julian date (simplified).
 */
double compute_gmst(double julian_date) {
    double T = (julian_date - 2451545.0) / 36525.0;
    double gmst = 280.46061837 + 360.98564736629 * (julian_date - 2451545.0) +
                  0.000387933 * T * T;

    /* Convert to radians and normalize */
    gmst = fmod(gmst, 360.0);
    if (gmst < 0.0) gmst += 360.0;

    return gmst * M_PI / 180.0;
}

/**
 * Kepler orbit propagation using universal variables.
 *
 * Replaces AGC KEPLER subroutine:
 *   The original used fixed-point arithmetic with careful scaling
 *   and the interpretive language for the iterative solution.
 *
 * This implementation uses Battin's universal variable formulation
 * with Laguerre-Conway iteration for robust convergence.
 */
void kepler_propagate(state_vector_t *state, double dt, double mu) {
    if (fabs(dt) < 1e-12) return;

    double r0 = vector_magnitude(&state->position);
    double v0 = vector_magnitude(&state->velocity);

    if (r0 < 1e-6) return;

    double vr0 = dot_product(&state->position, &state->velocity) / r0;
    double alpha = 2.0 / r0 - v0 * v0 / mu;  /* 1/a */

    /* Initial guess for universal variable chi */
    double chi;
    if (alpha > 1e-6) {
        /* Elliptical orbit */
        chi = sqrt(mu) * dt * alpha;
    } else if (fabs(alpha) < 1e-6) {
        /* Parabolic */
        vector3_t h = cross_product(&state->position, &state->velocity);
        double p = dot_product(&h, &h) / mu;
        double s = 0.5 * atan2(1.0, 3.0 * sqrt(mu / (p * p * p)) * dt);
        double w = atan(pow(tan(s), 1.0 / 3.0));
        chi = sqrt(p) * 2.0 / tan(2.0 * w);
    } else {
        /* Hyperbolic */
        double a_hyp = 1.0 / alpha;
        chi = copysign(1.0, dt) * sqrt(-a_hyp) *
              log(-2.0 * mu * alpha * dt /
                  (vr0 * r0 + copysign(1.0, dt) * sqrt(-mu * a_hyp) *
                   (1.0 - r0 * alpha)));
    }

    /* Newton-Raphson iteration */
    for (int i = 0; i < KEPLER_MAX_ITER; i++) {
        double psi = chi * chi * alpha;
        double c2 = (fabs(psi) < 1e-6) ? 0.5 :
                     (psi > 0) ? (1.0 - cos(sqrt(psi))) / psi :
                                 (cosh(sqrt(-psi)) - 1.0) / (-psi);
        double c3 = (fabs(psi) < 1e-6) ? 1.0 / 6.0 :
                     (psi > 0) ? (sqrt(psi) - sin(sqrt(psi))) / (psi * sqrt(psi)) :
                                 (sinh(sqrt(-psi)) - sqrt(-psi)) / ((-psi) * sqrt(-psi));

        double r = chi * chi * c2 + vr0 / sqrt(mu) * chi * (1.0 - psi * c3) + r0 * (1.0 - psi * c2);
        double F = chi * chi * chi * c3 + vr0 / sqrt(mu) * chi * chi * c2 + r0 * chi * (1.0 - psi * c3) - sqrt(mu) * dt;

        if (fabs(F) < KEPLER_TOL * sqrt(mu)) break;

        chi = chi - F / r;
    }

    /* Compute Lagrange coefficients f, g, fdot, gdot */
    double psi = chi * chi * alpha;
    double c2 = (fabs(psi) < 1e-6) ? 0.5 :
                 (psi > 0) ? (1.0 - cos(sqrt(psi))) / psi :
                             (cosh(sqrt(-psi)) - 1.0) / (-psi);
    double c3 = (fabs(psi) < 1e-6) ? 1.0 / 6.0 :
                 (psi > 0) ? (sqrt(psi) - sin(sqrt(psi))) / (psi * sqrt(psi)) :
                             (sinh(sqrt(-psi)) - sqrt(-psi)) / ((-psi) * sqrt(-psi));

    double r_new = chi * chi * c2 + vr0 / sqrt(mu) * chi * (1.0 - psi * c3) + r0 * (1.0 - psi * c2);

    double f = 1.0 - chi * chi * c2 / r0;
    double g = dt - chi * chi * chi * c3 / sqrt(mu);
    double fdot = sqrt(mu) / (r_new * r0) * chi * (psi * c3 - 1.0);
    double gdot = 1.0 - chi * chi * c2 / r_new;

    /* Update position and velocity */
    vector3_t new_pos, new_vel;
    new_pos.x = f * state->position.x + g * state->velocity.x;
    new_pos.y = f * state->position.y + g * state->velocity.y;
    new_pos.z = f * state->position.z + g * state->velocity.z;

    new_vel.x = fdot * state->position.x + gdot * state->velocity.x;
    new_vel.y = fdot * state->position.y + gdot * state->velocity.y;
    new_vel.z = fdot * state->position.z + gdot * state->velocity.z;

    state->position = new_pos;
    state->velocity = new_vel;
}
