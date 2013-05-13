

JS_ALL := $(shell find src/js -type f -name \*.js)
JS_ROOTS := $(wildcard src/js/*.js)
JS_TARGET := $(patsubst src/js/%,static/js/%,$(JS_ROOTS))
PHP_ALL := $(shell find . -type f -name \*.php)
SASS_ROOTS := $(wildcard src/sass/[^_]*.scss)
CSS_TARGET := $(patsubst src/sass/%.scss,static/css/%.css,$(SASS_ROOTS))
PYTHON := python
SAXON := saxonb-xslt

all: test ucotd css js cachebust

.PHONY: all css js dist clean ucotd cachebust l10n test vendor db clearcache \
        test-sass

clean:
	-rm -fr dist src/vendor

dist: vendor all
	mkdir $@
	cp -r .htaccess humans.txt index.php lib opensearch.xml robots.txt static ucd.sqlite views $@
	sed -i 's/define(.CP_DEBUG., .);/define('"'CP_DEBUG'"', 0);/' $@/index.php

css: $(CSS_TARGET)

$(CSS_TARGET): static/css/%.css : src/sass/%.scss
	compass compile --force $<

js: static/js/build.txt static/js/html5shiv.js

static/js/build.txt: src/build.js $(JS_ALL)
	cd src && node vendor/r.js/dist/r.js -o build.js
	-rm -fr static/js/components

static/js/html5shiv.js: src/vendor/html5shiv/dist/html5shiv.js
	<$< uglifyjs >$@

cachebust: $(JS_ALL) $(CSS_TARGET)
	$(info * Update Cache Bust Constant)
	@sed -i '/^define(.CACHE_BUST., .\+.);$$/s/.*/define('"'CACHE_BUST', '"$$(cat $^ | sha1sum | awk '{ print $$1 }')"');/" index.php

db: ucd.sqlite

ucotd: tools/ucotd.*
	$(info * Add Codepoint of the Day)
	@cd tools; \
	$(PYTHON) ucotd.py

ucd.sqlite: ucotd tools/scripts.sql tools/scripts_wp.sql \
            tools/fonts/*_insert.sql tools/latex.sql
	sqlite3 $@ <tools/scripts.sql
	sqlite3 $@ <tools/scripts_wp.sql
	sqlite3 $@ <tools/fonts/*_insert.sql
	sqlite3 $@ <tools/latex.sql

l10n: locale/messages.pot locale/js.pot

l10n-finish:
	tools/my-po2json.js de

locale/messages.pot: index.php lib/*.php controllers/*.php views/*.php \
                     views/*/*.php
	$(info * Compile translation strings)
	@find index.php lib controllers views -name \*.php | \
		xargs xgettext -LPHP --from-code UTF-8 -k__ -k_e -k_n -kgettext -o $@

locale/js.pot: $(JS_ALL)
	#jsxgettext -k _ -o $@ $^
	xgettext -LPerl --from-code UTF-8 -k_ -o - $^ | \
		sed '/^#, perl-format$$/d' > $@

vendor: src/component.json
	bower install
	$(MAKE) -C src/vendor/d3 d3.v2.js JS_UGLIFY=uglifyjs2
	cd src/vendor/jquery.ui && npm install && grunt build
	cd src/vendor/webfontloader && rake

test: test-php test-sass test-js

test-php: $(PHP_ALL)
	$(info * Test PHP syntax)
	@! find . -name \*.php -exec php -l '{}' \; | \
		grep -v '^No syntax errors detected in '

test-js: $(JS_ALL)
	$(info * Test JS syntax)
	@jshint $^

test-sass: $(shell find src/sass -type f)
	$(info * Test Sass syntax)
	@sass --check $^

clearcache:
	rm -f cache/_cache_* cache/blog-preview*

tools/latex.sql: tools/latex.xsl tools/latex.xml
	$(SAXON) -xsl:tools/latex.xsl -s:tools/latex.xml -o:$@

tools/latex.xml:
	wget -O tools/latex.xml http://www.w3.org/Math/characters/unicode.xml
	wget -O tools/charlist.dtd http://www.w3.org/Math/characters/charlist.dtd
