#include <erl_nif.h>
#include "utils.h"

int get_number(ErlNifEnv *env, ERL_NIF_TERM term, double *result)
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
