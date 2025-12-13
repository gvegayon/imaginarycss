
install: 
	Rscript --vanilla -e 'devtools::install()'

README.md: README.qmd
	quarto render README.qmd

check: build
	R CMD check --as-cran ${PKGNAME}_${VERSION}.tar.gz

# Once running, we can set a debug point using 'break [filename].hpp:[linenumber]
# and then type 'run'
debug:
	R -d gdb switch
profile: install
	R --debugger=valgrind --debugger-args='--tool=cachegrind --cachegrind-out-file=test.cache.out'

update:
	rsync -av ../../barry/include/barry inst/include && \
	rm -rf inst/include/barry/models

update-css:
	rsync -av ../../barry/include/barry/counters/network-css.hpp inst/include/barry/counters

docs:
	Rscript --vanilla -e 'devtools::document()'

.PHONY: install check debug profile update update-css docs README.md
