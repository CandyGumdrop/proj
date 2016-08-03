#include <string.h>
#include <proj_api.h>
#include <erl_nif.h>

static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
static ERL_NIF_TERM from_def_nif(ErlNifEnv *env,
                                 int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM transform_nif(ErlNifEnv *env,
                                  int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM get_def_nif(ErlNifEnv *env,
                                int argc, const ERL_NIF_TERM argv[]);

static ErlNifFunc nif_funcs[] = {
    {"from_def", 1, from_def_nif, 0},
    {"transform", 3, transform_nif, 0},
    {"get_def", 1, get_def_nif, 0}
};

/* Generate relevant exports for NIFs */
ERL_NIF_INIT(Elixir.Proj, nif_funcs, load, NULL, NULL, NULL)

/* Resource type "proj" */
struct proj_resource {
    projPJ pj;
};

ErlNifResourceType *proj_resource_type;

/* Destructors for resource types */
static void proj_resource_dtor(ErlNifEnv *env, void *obj);

/* Run when the NIF is loaded.  Resource types are opened here. */
static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
    proj_resource_type
        = enif_open_resource_type(env, NULL, "proj", proj_resource_dtor,
                                  ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER, NULL);

    if (!proj_resource_type) {
        return 1;
    }

    return 0;
}

static void proj_resource_dtor(ErlNifEnv *env, void *obj)
{
    struct proj_resource *proj = (struct proj_resource *)obj;
    if (proj->pj) {
        pj_ctx_free(pj_get_ctx(proj->pj));
        pj_free(proj->pj);
    }
}

/**
 * Create an Erlang NIF binary term for a given pj_errno.
 */
static ERL_NIF_TERM make_pj_strerrno_binary(ErlNifEnv *env, int perrno)
{
    const char *error_str;
    int error_len;
    ErlNifBinary error_bin;

    error_str = pj_strerrno(perrno);
    error_len = strlen(error_str);
    enif_alloc_binary(error_len, &error_bin);
    memcpy(error_bin.data, error_str, error_len);

    return enif_make_binary(env, &error_bin);
}

/**
 * Get a double from an Erlang NIF term which is either a float or an int.
 *
 * Sets *result to the double value and returns true on success, or false on
 * failure.
 */
static int get_number(ErlNifEnv *env, ERL_NIF_TERM term, double *result)
{
    int result_int;

    if (enif_get_double(env, term, result)) {
        return 1;
    } else if (enif_get_int(env, term, &result_int)) {
        *result = result_int;
        return 1;
    } else {
        return 0;
    }
}

/**
 * Use pj_init_plus_ctx() to create a new projPJ.
 *
 * The projPJ is wrapped in a "proj" resource type and then a Proj Elixir struct
 * (Erlang map term) so it can easily be passed around in Elixir.
 */
static ERL_NIF_TERM from_def_nif(ErlNifEnv *env,
                                 int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary def_bin;
    char *def_string;

    projCtx pj_ctx;
    struct proj_resource *proj;

    ERL_NIF_TERM proj_ex_struct;

    if (argc != 1) {
        return enif_make_badarg(env);
    }

    if (!enif_inspect_binary(env, argv[0], &def_bin)) {
        return enif_make_badarg(env);
    }

    /* Copy the binary to a string to ensure it is NUL-terminated */
    def_string = enif_alloc(def_bin.size + 1);
    memcpy(def_string, def_bin.data, def_bin.size);
    def_string[def_bin.size] = '\0';

    proj = enif_alloc_resource(proj_resource_type, sizeof(struct proj_resource));

    pj_ctx = pj_ctx_alloc();

    /* Create the projPJ and return a {:error, "strerror"} tuple */
    if (!(proj->pj = pj_init_plus_ctx(pj_ctx, def_string))) {
        ERL_NIF_TERM error_term;

        error_term = make_pj_strerrno_binary(env, pj_ctx_get_errno(pj_ctx));

        pj_ctx_free(pj_ctx);
        enif_release_resource(proj);

        return enif_make_tuple2(env,
                                enif_make_atom(env, "error"),
                                error_term);
    }

    enif_free(def_string);

    proj_ex_struct = enif_make_new_map(env);

    /* Elixir structs are just maps with a :__struct__ field */
    enif_make_map_put(env, proj_ex_struct,
                      enif_make_atom(env, "__struct__"),
                      enif_make_atom(env, "Elixir.Proj"),
                      &proj_ex_struct);

    enif_make_map_put(env, proj_ex_struct,
                      enif_make_atom(env, "pj"),
                      enif_make_resource(env, proj),
                      &proj_ex_struct);

    /* Release our reference to proj as the env has been given a reference */
    enif_release_resource(proj);

    return enif_make_tuple2(env,
                            enif_make_atom(env, "ok"),
                            proj_ex_struct);
}

/**
 * Transform an {x, y, z} tuple from one projection to another using
 * pj_transform().
 */
static ERL_NIF_TERM transform_nif(ErlNifEnv *env,
                                  int argc, const ERL_NIF_TERM argv[])
{
    double x, y, z;

    int coords_arity;
    const ERL_NIF_TERM *coords_terms;
    ERL_NIF_TERM src_proj_term;
    ERL_NIF_TERM dst_proj_term;

    struct proj_resource *src_proj;
    struct proj_resource *dst_proj;

    int transform_errno;

    if (argc != 3) {
        return enif_make_badarg(env);
    }

    if (!enif_get_tuple(env, argv[0], &coords_arity, &coords_terms)
        || coords_arity != 3) {
        return enif_make_badarg(env);
    }

    if (!(get_number(env, coords_terms[0], &x) &&
          get_number(env, coords_terms[1], &y) &&
          get_number(env, coords_terms[2], &z))) {
        return enif_make_badarg(env);
    }

    if (!enif_get_map_value(env, argv[1], enif_make_atom(env, "pj"), &src_proj_term)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_map_value(env, argv[2], enif_make_atom(env, "pj"), &dst_proj_term)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, src_proj_term, proj_resource_type, (void **)&src_proj)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, dst_proj_term, proj_resource_type, (void **)&dst_proj)) {
        return enif_make_badarg(env);
    }

    if ((transform_errno = pj_transform(src_proj->pj, dst_proj->pj,
                                        1, 1, &x, &y, &z))) {
        return enif_make_tuple2(env,
                                enif_make_atom(env, "error"),
                                make_pj_strerrno_binary(env, transform_errno));
    }

    return enif_make_tuple2(env,
                            enif_make_atom(env, "ok"),
                            enif_make_tuple3(env,
                                             enif_make_double(env, x),
                                             enif_make_double(env, y),
                                             enif_make_double(env, z)));
}

static ERL_NIF_TERM get_def_nif(ErlNifEnv *env,
                                int argc, const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM proj_term;
    struct proj_resource *proj;

    char *def_str;
    int def_len;
    ErlNifBinary def_bin;

    if (!enif_get_map_value(env, argv[0], enif_make_atom(env, "pj"), &proj_term)) {
        return enif_make_badarg(env);
    }

    if (!enif_get_resource(env, proj_term, proj_resource_type, (void **)&proj)) {
        return enif_make_badarg(env);
    }

    def_str = pj_get_def(proj->pj, 0);
    def_len = strlen(def_str);
    enif_alloc_binary(def_len, &def_bin);
    memcpy(def_bin.data, def_str, def_len);

    pj_dalloc(def_str);

    return enif_make_binary(env, &def_bin);
}
