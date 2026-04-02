/**
 * Navigation Routines - Header
 *
 * Modernized from AGC navigation assembly routines.
 */

#ifndef NAVIGATION_H
#define NAVIGATION_H

#include "guidance.h"

/**
 * Navigation state maintained by the navigation computer.
 */
typedef struct {
    state_vector_t state;       /* Current state vector */
    double epoch;               /* Reference epoch (seconds) */
    int coordinate_system;      /* 0=Earth-centered, 1=Moon-centered */
    double last_update_time;    /* Time of last state update */
} nav_state_t;

/**
 * IMU (Inertial Measurement Unit) readings.
 */
typedef struct {
    double delta_v_x;   /* Sensed velocity change X (m/s) */
    double delta_v_y;   /* Sensed velocity change Y (m/s) */
    double delta_v_z;   /* Sensed velocity change Z (m/s) */
    double delta_t;     /* Time interval (seconds) */
} imu_reading_t;

/* Navigation functions */
void nav_initialize(nav_state_t *nav, const state_vector_t *initial_state);
void nav_propagate(nav_state_t *nav, double dt);
void nav_update_with_imu(nav_state_t *nav, const imu_reading_t *reading);
double nav_compute_altitude(const nav_state_t *nav);
double nav_compute_velocity_magnitude(const nav_state_t *nav);
double nav_compute_orbital_period(const nav_state_t *nav, double mu);

/* Coordinate transforms */
vector3_t eci_to_ecef(const vector3_t *eci_pos, double gmst);
double compute_gmst(double julian_date);

/* Kepler propagation */
void kepler_propagate(state_vector_t *state, double dt, double mu);

#endif /* NAVIGATION_H */
