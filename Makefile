.POSIX:
.SUFFIXES:

all: clean public

.PHONY: clean
clean:
	rm -rf content
	rm -rf public
	rm -rf site.tar.gz

content:
	emacs $(pwd) --batch --load export.el

public: content
	hugo

.PHONY: run
run: content
	hugo serve

.PHONY: database
database:
	nix develop --impure .#postgres --command bash -c "devenv up"

.PHONY: clean_database
clean_database:
	-process-compose down --unix-socket .devenv/pc.sock
	rm -rf .devenv/state/postgres


