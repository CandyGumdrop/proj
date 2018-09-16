CFLAGS = -fPIC -Isrc -std=c99 -pedantic -Wall -Wextra -Wno-unused-parameter
CC ?= gcc

NIF_LDFLAGS = -shared

ERLANG_PATH := $(shell erl -eval 'io:format("~s~n", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
ERLANG_CFLAGS = -I$(ERLANG_PATH)

PROJ_LIBS = -lproj

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
NIF_LDFLAGS += -flat_namespace -undefined suppress
endif

all: proj_nif.so geodesic_nif.so

proj_nif.so: priv/proj_nif.so
geodesic_nif.so: priv/geodesic_nif.so

priv/proj_nif.so: src/proj_nif.o src/utils.o
	$(CC) $(CFLAGS) $^ -o $@ $(PROJ_LIBS) $(NIF_LDFLAGS)

priv/geodesic_nif.so: src/geodesic_nif.o src/utils.o
	$(CC) $(CFLAGS) $^ -o $@ $(PROJ_LIBS) $(NIF_LDFLAGS)

src/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@ $(ERLANG_CFLAGS)

src/proj_nif.o: src/utils.h
src/geodesic_nif.o: src/utils.h

clean:
	rm -rf src/*.o priv/*.so

.PHONY: all clean proj_nif.so geodesic_nif.so
