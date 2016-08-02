#include <string.h>
#include <proj_api.h>
#include <erl_nif.h>

static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
static ERL_NIF_TERM from_def_nif(ErlNifEnv *env,
                                 int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM transform_nif(ErlNifEnv *env,
                                  int argc, const ERL_NIF_TERM argv[]);

static ErlNifFunc nif_funcs[] = {
    {"from_def", 1, from_def_nif, 0},
    {"transform", 3, transform_nif, 0}
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
        const char *error_str;
        int error_len;
        ErlNifBinary error_bin;

        error_str = pj_strerrno(pj_ctx_get_errno(pj_ctx));
        error_len = strlen(error_str);
        enif_alloc_binary(error_len, &error_bin);
        memcpy(error_bin.data, error_str, error_len);

        pj_ctx_free(pj_ctx);
        enif_release_resource(proj);

        return enif_make_tuple2(env,
                                enif_make_atom(env, "error"),
                                enif_make_binary(env, &error_bin));
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

static ERL_NIF_TERM transform_nif(ErlNifEnv *env,
                                  int argc, const ERL_NIF_TERM argv[])
{
    return enif_make_tuple2(env,
                            enif_make_atom(env, "error"),
                            enif_make_atom(env, "not_implemented"));
}
