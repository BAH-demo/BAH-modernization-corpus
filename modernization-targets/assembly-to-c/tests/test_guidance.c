/**
 * Tests for guidance and navigation routines.
 *
 * Verifies:
 * - Vector operations (cross product, dot product, magnitude, normalize)
 * - Orbital mechanics calculations
 * - Kepler propagation
 * - Navigation state updates
 */

#include "test_framework.h"
#include "../src/guidance.h"
#include "../src/navigation.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define VEC_TOL  1e-10
#define ORB_TOL  1e-6

/* ---- Vector Operation Tests ---- */

void test_cross_product_basic(void) {
    vector3_t a = {1.0, 0.0, 0.0};
    vector3_t b = {0.0, 1.0, 0.0};
    vector3_t result = cross_product(&a, &b);
    TEST_ASSERT_EQUAL_DOUBLE(0.0, result.x, VEC_TOL, "cross X");
    TEST_ASSERT_EQUAL_DOUBLE(0.0, result.y, VEC_TOL, "cross Y");
    TEST_ASSERT_EQUAL_DOUBLE(1.0, result.z, VEC_TOL, "cross Z = 1");
}

void test_cross_product_anticommutative(void) {
    vector3_t a = {1.0, 2.0, 3.0};
    vector3_t b = {4.0, 5.0, 6.0};
    vector3_t ab = cross_product(&a, &b);
    vector3_t ba = cross_product(&b, &a);
    TEST_ASSERT_EQUAL_DOUBLE(-ab.x, ba.x, VEC_TOL, "cross anti-commutative X");
    TEST_ASSERT_EQUAL_DOUBLE(-ab.y, ba.y, VEC_TOL, "cross anti-commutative Y");
    TEST_ASSERT_EQUAL_DOUBLE(-ab.z, ba.z, VEC_TOL, "cross anti-commutative Z");
}

void test_cross_product_self_is_zero(void) {
    vector3_t a = {3.0, 4.0, 5.0};
    vector3_t result = cross_product(&a, &a);
    TEST_ASSERT_EQUAL_DOUBLE(0.0, result.x, VEC_TOL, "self-cross X = 0");
    TEST_ASSERT_EQUAL_DOUBLE(0.0, result.y, VEC_TOL, "self-cross Y = 0");
    TEST_ASSERT_EQUAL_DOUBLE(0.0, result.z, VEC_TOL, "self-cross Z = 0");
}

void test_dot_product_basic(void) {
    vector3_t a = {1.0, 2.0, 3.0};
    vector3_t b = {4.0, 5.0, 6.0};
    double result = dot_product(&a, &b);
    TEST_ASSERT_EQUAL_DOUBLE(32.0, result, VEC_TOL, "dot product = 32");
}

void test_dot_product_perpendicular(void) {
    vector3_t a = {1.0, 0.0, 0.0};
    vector3_t b = {0.0, 1.0, 0.0};
    double result = dot_product(&a, &b);
    TEST_ASSERT_EQUAL_DOUBLE(0.0, result, VEC_TOL, "perpendicular dot = 0");
}

void test_vector_magnitude(void) {
    vector3_t v = {3.0, 4.0, 0.0};
    double mag = vector_magnitude(&v);
    TEST_ASSERT_EQUAL_DOUBLE(5.0, mag, VEC_TOL, "magnitude of (3,4,0) = 5");
}

void test_vector_magnitude_3d(void) {
    vector3_t v = {1.0, 2.0, 2.0};
    double mag = vector_magnitude(&v);
    TEST_ASSERT_EQUAL_DOUBLE(3.0, mag, VEC_TOL, "magnitude of (1,2,2) = 3");
}

void test_vector_normalize(void) {
    vector3_t v = {3.0, 4.0, 0.0};
    vector3_t unit = vector_normalize(&v);
    double mag = vector_magnitude(&unit);
    TEST_ASSERT_EQUAL_DOUBLE(1.0, mag, VEC_TOL, "normalized magnitude = 1");
    TEST_ASSERT_EQUAL_DOUBLE(0.6, unit.x, VEC_TOL, "normalized x = 0.6");
    TEST_ASSERT_EQUAL_DOUBLE(0.8, unit.y, VEC_TOL, "normalized y = 0.8");
}

void test_vector_normalize_zero(void) {
    vector3_t v = {0.0, 0.0, 0.0};
    vector3_t unit = vector_normalize(&v);
    TEST_ASSERT_EQUAL_DOUBLE(0.0, unit.x, VEC_TOL, "zero vec normalize x = 0");
    TEST_ASSERT_EQUAL_DOUBLE(0.0, unit.y, VEC_TOL, "zero vec normalize y = 0");
}

void test_vector_add(void) {
    vector3_t a = {1.0, 2.0, 3.0};
    vector3_t b = {4.0, 5.0, 6.0};
    vector3_t result = vector_add(&a, &b);
    TEST_ASSERT_EQUAL_DOUBLE(5.0, result.x, VEC_TOL, "add x");
    TEST_ASSERT_EQUAL_DOUBLE(7.0, result.y, VEC_TOL, "add y");
    TEST_ASSERT_EQUAL_DOUBLE(9.0, result.z, VEC_TOL, "add z");
}

void test_vector_subtract(void) {
    vector3_t a = {5.0, 7.0, 9.0};
    vector3_t b = {1.0, 2.0, 3.0};
    vector3_t result = vector_subtract(&a, &b);
    TEST_ASSERT_EQUAL_DOUBLE(4.0, result.x, VEC_TOL, "sub x");
    TEST_ASSERT_EQUAL_DOUBLE(5.0, result.y, VEC_TOL, "sub y");
    TEST_ASSERT_EQUAL_DOUBLE(6.0, result.z, VEC_TOL, "sub z");
}

void test_vector_scale(void) {
    vector3_t v = {1.0, 2.0, 3.0};
    vector3_t result = vector_scale(&v, 2.5);
    TEST_ASSERT_EQUAL_DOUBLE(2.5, result.x, VEC_TOL, "scale x");
    TEST_ASSERT_EQUAL_DOUBLE(5.0, result.y, VEC_TOL, "scale y");
    TEST_ASSERT_EQUAL_DOUBLE(7.5, result.z, VEC_TOL, "scale z");
}

/* ---- Orbital Mechanics Tests ---- */

void test_orbital_energy_circular(void) {
    /* ISS-like circular orbit at ~400km altitude */
    double r = 6771000.0;  /* 6371km + 400km */
    double mu = 3.986004418e14;
    double v_circular = sqrt(mu / r);  /* Circular velocity */

    state_vector_t state;
    state.position = (vector3_t){r, 0.0, 0.0};
    state.velocity = (vector3_t){0.0, v_circular, 0.0};

    double energy = compute_orbital_energy(&state, mu);
    double expected_energy = -mu / (2.0 * r);

    TEST_ASSERT_EQUAL_DOUBLE(expected_energy, energy, fabs(expected_energy * 1e-10),
                             "Circular orbit energy");
}

void test_semi_major_axis(void) {
    double mu = 3.986004418e14;
    double r = 6771000.0;
    double expected_a = r;  /* Circular orbit: a = r */
    double energy = -mu / (2.0 * r);
    double a = compute_semi_major_axis(energy, mu);
    TEST_ASSERT_EQUAL_DOUBLE(expected_a, a, expected_a * 1e-10,
                             "Semi-major axis of circular orbit");
}

void test_angular_momentum_circular(void) {
    double r = 6771000.0;
    double mu = 3.986004418e14;
    double v = sqrt(mu / r);

    state_vector_t state;
    state.position = (vector3_t){r, 0.0, 0.0};
    state.velocity = (vector3_t){0.0, v, 0.0};

    vector3_t h = compute_angular_momentum(&state);
    double h_mag = vector_magnitude(&h);
    double expected_h = r * v;

    TEST_ASSERT_EQUAL_DOUBLE(expected_h, h_mag, expected_h * 1e-10,
                             "Angular momentum magnitude");
    /* For equatorial prograde orbit, h should point +Z */
    TEST_ASSERT_EQUAL_DOUBLE(0.0, h.x, 1.0, "h_x = 0");
    TEST_ASSERT_EQUAL_DOUBLE(0.0, h.y, 1.0, "h_y = 0");
    TEST_ASSERT(h.z > 0, "h_z > 0 for prograde");
}

/* ---- Navigation Tests ---- */

void test_nav_initialize(void) {
    state_vector_t initial;
    initial.position = (vector3_t){6771000.0, 0.0, 0.0};
    initial.velocity = (vector3_t){0.0, 7670.0, 0.0};
    initial.mass = 1000.0;
    initial.time = 0.0;

    nav_state_t nav;
    nav_initialize(&nav, &initial);

    TEST_ASSERT_EQUAL_DOUBLE(6771000.0, nav.state.position.x, 0.1, "nav init pos x");
    TEST_ASSERT_EQUAL_DOUBLE(7670.0, nav.state.velocity.y, 0.1, "nav init vel y");
    TEST_ASSERT_EQUAL_INT(0, nav.coordinate_system, "nav init coord sys");
}

void test_nav_altitude(void) {
    state_vector_t initial;
    initial.position = (vector3_t){6771000.0, 0.0, 0.0};
    initial.velocity = (vector3_t){0.0, 7670.0, 0.0};
    initial.mass = 1000.0;
    initial.time = 0.0;

    nav_state_t nav;
    nav_initialize(&nav, &initial);

    double alt = nav_compute_altitude(&nav);
    TEST_ASSERT_EQUAL_DOUBLE(400000.0, alt, 1.0, "altitude = 400 km");
}

void test_nav_imu_update(void) {
    state_vector_t initial;
    initial.position = (vector3_t){6771000.0, 0.0, 0.0};
    initial.velocity = (vector3_t){0.0, 7670.0, 0.0};
    initial.mass = 1000.0;
    initial.time = 0.0;

    nav_state_t nav;
    nav_initialize(&nav, &initial);

    /* Apply a small delta-V */
    imu_reading_t reading;
    reading.delta_v_x = 0.0;
    reading.delta_v_y = 0.0;
    reading.delta_v_z = 10.0;  /* 10 m/s in Z */
    reading.delta_t = 1.0;     /* 1 second */

    nav_update_with_imu(&nav, &reading);

    TEST_ASSERT_EQUAL_DOUBLE(10.0, nav.state.velocity.z, 0.01, "velocity Z updated");
    TEST_ASSERT_EQUAL_DOUBLE(1.0, nav.state.time, 0.001, "time updated");
}

void test_kepler_propagation_circular(void) {
    /* Circular orbit should maintain constant radius */
    double r0 = 6771000.0;
    double mu = 3.986004418e14;
    double v0 = sqrt(mu / r0);

    state_vector_t state;
    state.position = (vector3_t){r0, 0.0, 0.0};
    state.velocity = (vector3_t){0.0, v0, 0.0};
    state.mass = 1000.0;
    state.time = 0.0;

    /* Propagate for quarter orbit */
    double period = 2.0 * M_PI * sqrt(r0 * r0 * r0 / mu);
    kepler_propagate(&state, period / 4.0, mu);

    /* Radius should be preserved */
    double r = vector_magnitude(&state.position);
    TEST_ASSERT_EQUAL_DOUBLE(r0, r, r0 * 1e-6, "circular orbit radius preserved");
}

void test_orbital_period(void) {
    double r = 6771000.0;
    double mu = 3.986004418e14;
    double v = sqrt(mu / r);

    state_vector_t initial;
    initial.position = (vector3_t){r, 0.0, 0.0};
    initial.velocity = (vector3_t){0.0, v, 0.0};
    initial.mass = 1000.0;
    initial.time = 0.0;

    nav_state_t nav;
    nav_initialize(&nav, &initial);

    double period = nav_compute_orbital_period(&nav, mu);
    double expected_period = 2.0 * M_PI * sqrt(r * r * r / mu);

    TEST_ASSERT_EQUAL_DOUBLE(expected_period, period, 0.01,
                             "Orbital period calculation");
}

/* ---- Main ---- */

int main(void) {
    printf("Guidance & Navigation Tests\n");
    printf("===========================\n\n");

    printf("Vector Operations:\n");
    RUN(test_cross_product_basic);
    RUN(test_cross_product_anticommutative);
    RUN(test_cross_product_self_is_zero);
    RUN(test_dot_product_basic);
    RUN(test_dot_product_perpendicular);
    RUN(test_vector_magnitude);
    RUN(test_vector_magnitude_3d);
    RUN(test_vector_normalize);
    RUN(test_vector_normalize_zero);
    RUN(test_vector_add);
    RUN(test_vector_subtract);
    RUN(test_vector_scale);

    printf("\nOrbital Mechanics:\n");
    RUN(test_orbital_energy_circular);
    RUN(test_semi_major_axis);
    RUN(test_angular_momentum_circular);

    printf("\nNavigation:\n");
    RUN(test_nav_initialize);
    RUN(test_nav_altitude);
    RUN(test_nav_imu_update);
    RUN(test_kepler_propagation_circular);
    RUN(test_orbital_period);

    TEST_SUMMARY();

    return tests_failed > 0 ? 1 : 0;
}
