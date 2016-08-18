#ifndef _UTILS_H
#define _UTILS_H

#define WGS84_EQ_RADIUS 6378137.0
#define WGS84_FLATTENING (1.0 / 298.257223563)

/**
 * Get a double from an Erlang NIF term which is either a float or an int.
 *
 * Sets *result to the double value and returns true on success, or false on
 * failure.
 */
int get_number(ErlNifEnv *env, ERL_NIF_TERM term, double *result);

#endif
