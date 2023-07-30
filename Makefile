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


# empty
