# Agent Instructions for imaginarycss

## Package Overview

`imaginarycss` is an R package for analyzing Cognitive Social Structures
(CSS). It implements the methods described in Tanaka and Vega Yon (2023),
"Imaginary Structures as Evidence of Social Cognition"
(doi: [10.1016/j.socnet.2023.11.005](https://doi.org/10.1016/j.socnet.2023.11.005)).

## Development Principles

- **Minimal dependencies**: keep the package lightweight. The only runtime
  imports should be `Rcpp` and `stats`. Avoid adding tidyverse packages
  (ggplot2, dplyr, tidyr, etc.) as dependencies or even as Suggests.
- **Base R first**: all visualizations in vignettes and examples should use
  base R graphics (`plot()`, `barplot()`, `boxplot()`, `hist()`), not ggplot2.
- **Data management**: if external data wrangling is truly needed, prefer
  `data.table` (zero dependencies, fast) over tidyverse. But base R is
  preferred when possible.
- **Vignette guidelines**: vignettes should be concise (3--4 pages), balance
  code with explanatory text, and focus on demonstrating the package's
  functions rather than auxiliary visualization code.

## Validation

Before submitting changes for review, always run:

```r
devtools::check()
```

This ensures that vignettes build without errors, examples run correctly, and
tests pass. Pay particular attention to vignette build errors since they
execute R code that must work with the package's exported functions.

## Testing

The package uses `tinytest` for unit tests. Tests live in `inst/tinytest/`.
Run tests with:

```r
tinytest::test_package("imaginarycss")
```

## Common Pitfalls

- `tapply()` returns a named 1-d array, not a plain vector. When using its
  result in matrix arithmetic or comparisons, wrap it in `as.numeric()` first.
- `replicate(..., simplify = TRUE)` returns a matrix; make sure row names
  are consistent across iterations when indexing by name.
- The `barry_graph` objects are created via C++ (`Rcpp`/`barry`). Always pass
  integer matrices (`0L`/`1L`) to `new_barry_graph()`.
