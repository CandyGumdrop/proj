CFLAGS = -fPIC -Isrc -std=c99 -pedantic -Wall -Wextra
CC ?= gcc

NIF_LDFLAGS = -shared

ERLANG_PATH := $(shell erl -eval 'io:format("~s~n", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
ERLANG_CFLAGS = -I$(ERLANG_PATH)

PROJ_LIBS = -lproj

all: proj_nif.so

proj_nif.so: priv/proj_nif.so

priv/proj_nif.so: src/proj_nif.o
	$(CC) $(CFLAGS) $^ -o $@ $(PROJ_LIBS) $(NIF_LDFLAGS)

src/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@ $(ERLANG_CFLAGS)

clean:
	rm -rf src/*.o priv/*.so

.PHONY: all clean
