.PHONY: build clean test

lib/%.json: src/%.json
	mkdir -p lib
	cat "$<" | jq -c '.' > "$@"

lib/%.js: src/%.coffee
	mkdir -p $(dir $@)
	echo "'use_strict'" \
	| cat - "$<" \
	| ./node_modules/.bin/coffee -b -c -s > "$@.tmp"
	./node_modules/.bin/standard --fix --stdin < "$@.tmp" > "$@" || true
	rm "$@.tmp"

build: $(patsubst src/%.coffee, lib/%.js, $(wildcard src/*.coffee src/**/*.coffee)) \
       $(patsubst src/%, lib/%, $(wildcard src/*.json src/**/*.json))

clean:
	rm -rf lib

test: build
	./node_modules/.bin/mocha ./test/*.coffee
