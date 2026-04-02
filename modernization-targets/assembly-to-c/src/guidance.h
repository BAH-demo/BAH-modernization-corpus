/**
 * Guidance Equations - Header
 *
 * Modernized from AGC guidance assembly routines.
 */

#ifndef GUIDANCE_H
#define GUIDANCE_H

#include "agc_types.h"

/**
 * 3D vector in AGC fixed-point representation.
 */
typedef struct {
    double x;
    double y;
    double z;
} vector3_t;

/**
 * Spacecraft state vector.
 */
typedef struct {
    vector3_t position;     /* Position (meters) */
    vector3_t velocity;     /* Velocity (m/s) */
    double mass;            /* Mass (kg) */
    double time;            /* Mission elapsed time (seconds) */
} state_vector_t;

/**
 * Guidance target parameters.
 */
typedef struct {
    vector3_t target_position;
    vector3_t target_velocity;
    double target_radius;
    double time_of_flight;
} guidance_target_t;

/**
 * Guidance solution output.
 */
typedef struct {
    vector3_t delta_v;          /* Required velocity change */
    double delta_v_magnitude;   /* |delta-V| */
    double time_to_ignition;    /* Seconds until burn */
    double burn_duration;       /* Burn duration (seconds) */
    bool solution_valid;        /* Whether solution converged */
} guidance_solution_t;

/* Core guidance functions */
guidance_solution_t compute_lambert_guidance(
    const state_vector_t *current_state,
    const guidance_target_t *target
);

vector3_t cross_product(const vector3_t *a, const vector3_t *b);
double dot_product(const vector3_t *a, const vector3_t *b);
double vector_magnitude(const vector3_t *v);
vector3_t vector_normalize(const vector3_t *v);
vector3_t vector_add(const vector3_t *a, const vector3_t *b);
vector3_t vector_subtract(const vector3_t *a, const vector3_t *b);
vector3_t vector_scale(const vector3_t *v, double scalar);

/* Orbital mechanics */
double compute_orbital_energy(const state_vector_t *state, double mu);
double compute_semi_major_axis(double energy, double mu);
vector3_t compute_angular_momentum(const state_vector_t *state);

#endif /* GUIDANCE_H */
