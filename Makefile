OPAM_ENV  := $(shell opam env --switch=default 2>/dev/null)

BREW_ZLIB := $(shell brew --prefix zlib 2>/dev/null)
ifneq ($(BREW_ZLIB),)
  LIB_PATH_EXPORT := LIBRARY_PATH="$(BREW_ZLIB)/lib:$$LIBRARY_PATH" \
                     LDFLAGS="-L$(BREW_ZLIB)/lib $$LDFLAGS" \
                     CPATH="$(BREW_ZLIB)/include:$$CPATH"
else
  LIB_PATH_EXPORT :=
endif

DUNE := eval "$(OPAM_ENV)"; $(LIB_PATH_EXPORT) dune

.PHONY: all build test clean run

all: build

build:
	@$(DUNE) build

test:
	@$(DUNE) runtest --force --no-buffer

clean:
	@$(DUNE) clean

PROG ?= test/program.hex

run:
	@$(DUNE) exec my_rv32 -- $(PROG)
