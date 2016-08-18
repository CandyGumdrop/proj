#include <stdio.h>
#include <string.h>
#include <geodesic.h>
#include <erl_nif.h>
#include "utils.h"

static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
static void unload(ErlNifEnv *env, void *priv);
static ERL_NIF_TERM init_nif(ErlNifEnv *env,
                             int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM wgs84_nif(ErlNifEnv *env,
                              int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM direct_nif(ErlNifEnv *env,
                               int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM inverse_nif(ErlNifEnv *env,
                                int argc, const ERL_NIF_TERM argv[]);

static ErlNifFunc nif_funcs[] = {
    {"init", 2, init_nif, 0},
    {"wgs84", 0, wgs84_nif, 0},
    {"direct", 4, direct_nif, 0},
    {"inverse", 3, inverse_nif, 0}
};

/* Generate relevant exports for NIFs */
ERL_NIF_INIT(Elixir.Proj.Geodesic, nif_funcs, load, NULL, NULL, unload)

ErlNifResourceType *geodesic_resource_type;

/* Holds data for the module lifetime */
struct priv_data {
    struct geod_geodesic *wgs84; /* Convenient reference to WGS84 ellipsoid */
};

/* Run when the NIF is loaded.  Resource types are opened here. */
static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
    struct priv_data *data;

    geodesic_resource_type
        = enif_open_resource_type(env, NULL, "geodesic", NULL,
                                  ERL_NIF_RT_CREATE, NULL);

    if (!geodesic_resource_type) {
        return 1;
    }

    *priv = enif_alloc(sizeof(struct priv_data));
    data = (struct priv_data *)*priv;

    data->wgs84 = enif_alloc_resource(geodesic_resource_type,
                                      sizeof(struct geod_geodesic));
    enif_keep_resource(data->wgs84);

    geod_init(data->wgs84, WGS84_EQ_RADIUS, WGS84_FLATTENING);

    return 0;
}

/* Run when the NIF is unloaded.  Cleans up the priv data */
static void unload(ErlNifEnv *env, void *priv)
{
    struct priv_data *data;

    data = (struct priv_data *)priv;
    enif_release_resource(data->wgs84);
    enif_free(priv);
}

/**
 * Return an Erlang NIF term for an Elixir Proj.Geodesic struct.
 */
static ERL_NIF_TERM make_geodesic_struct(ErlNifEnv *env, struct geod_geodesic *geod)
{
    ERL_NIF_TERM geodesic_ex_struct;

    geodesic_ex_struct = enif_make_new_map(env);

    /* Elixir structs are just maps with a :__struct__ field */
    enif_make_map_put(env, geodesic_ex_struct,
                      enif_make_atom(env, "__struct__"),
                      enif_make_atom(env, "Elixir.Proj.Geodesic"),
                      &geodesic_ex_struct);

    enif_make_map_put(env, geodesic_ex_struct,
                      enif_make_atom(env, "geod"),
                      enif_make_resource(env, geod),
                      &geodesic_ex_struct);

    enif_make_map_put(env, geodesic_ex_struct,
                      enif_make_atom(env, "a"),
                      enif_make_double(env, geod->a),
                      &geodesic_ex_struct);

    enif_make_map_put(env, geodesic_ex_struct,
                      enif_make_atom(env, "f"),
                      enif_make_double(env, geod->f),
                      &geodesic_ex_struct);

    return geodesic_ex_struct;
}

/**
 * Use geod_init() to initialize a new geod_geodesic.
 *
 * The geod_geodesic is wrapped in a Proj.Geodesic Elixir struct
 * (Erlang map term) so it can easily be passed around in Elixir.
 */
static ERL_NIF_TERM init_nif(ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[])
{
    double a, f;
    struct geod_geodesic *geod;
    ERL_NIF_TERM geod_struct;

    if (argc != 2) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, argv[0], &a)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, argv[1], &f)) {
        return enif_make_badarg(env);
    }

    geod = enif_alloc_resource(geodesic_resource_type, sizeof(struct geod_geodesic));
    geod_init(geod, a, f);

    geod_struct = make_geodesic_struct(env, geod);

    /* Release our reference to geod as the env has been given a reference */
    enif_release_resource(geod);

    return geod_struct;
}

/**
 * Obtain a Proj.Geodesic struct for the WGS84 geoid parameters.
 */
static ERL_NIF_TERM wgs84_nif(ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[])
{
    struct priv_data *data;

    data = enif_priv_data(env);

    return make_geodesic_struct(env, data->wgs84);
}

/**
 * Use geod_direct() to calculate the resulting lat/lng + azimuth after
 * following a geodesic line for a given distance from a given lat/lng facing a
 * given azimuth.
 */
static ERL_NIF_TERM direct_nif(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM geod_term;
    struct geod_geodesic *geod;

    int coords_arity;
    const ERL_NIF_TERM *coords_terms;

    double lat, lng, azimuth, distance;
    double dest_lat, dest_lng, dest_azimuth;

    if (argc != 4) {
        return enif_make_badarg(env);
    }

    if (!enif_get_map_value(env, argv[0], enif_make_atom(env, "geod"), &geod_term)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, geod_term, geodesic_resource_type, (void **)&geod)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_tuple(env, argv[1], &coords_arity, &coords_terms)
        || coords_arity != 2) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, coords_terms[0], &lat)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, coords_terms[1], &lng)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, argv[2], &azimuth)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, argv[3], &distance)) {
        return enif_make_badarg(env);
    }

    geod_direct(geod, lat, lng, azimuth, distance,
                &dest_lat, &dest_lng, &dest_azimuth);

    if (dest_azimuth < 0.0) {
        dest_azimuth += 360.0;
    }

    return enif_make_tuple2(env,
                            enif_make_tuple2(env,
                                             enif_make_double(env, dest_lat),
                                             enif_make_double(env, dest_lng)),
                            enif_make_double(env, dest_azimuth));
}

/**
 * Use geod_inverse() to calculate the distance between two lat/lng pairs and
 * the azimuth from each end.
 */
static ERL_NIF_TERM inverse_nif(ErlNifEnv *env, int argc,
                                const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM geod_term;
    struct geod_geodesic *geod;

    int coords_1_arity, coords_2_arity;
    const ERL_NIF_TERM *coords_1_terms, *coords_2_terms;

    double lat1, lng1, lat2, lng2;
    double azimuth1, azimuth2, distance;

    if (argc != 3) {
        return enif_make_badarg(env);
    }

    if (!enif_get_map_value(env, argv[0], enif_make_atom(env, "geod"), &geod_term)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, geod_term, geodesic_resource_type, (void **)&geod)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_tuple(env, argv[1], &coords_1_arity, &coords_1_terms)
        || coords_1_arity != 2) {
        return enif_make_badarg(env);
    }

    if (!enif_get_tuple(env, argv[2], &coords_2_arity, &coords_2_terms)
        || coords_2_arity != 2) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, coords_1_terms[0], &lat1)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, coords_1_terms[1], &lng1)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, coords_2_terms[0], &lat2)) {
        return enif_make_badarg(env);
    }

    if (!get_number(env, coords_2_terms[1], &lng2)) {
        return enif_make_badarg(env);
    }

    geod_inverse(geod, lat1, lng1, lat2, lng2, &distance, &azimuth1, &azimuth2);

    if (azimuth1 < 0.0) {
        azimuth1 += 360.0;
    }
    if (azimuth2 < 0.0) {
        azimuth2 += 360.0;
    }

    return enif_make_tuple3(env,
                            enif_make_double(env, distance),
                            enif_make_double(env, azimuth1),
                            enif_make_double(env, azimuth2));
}
