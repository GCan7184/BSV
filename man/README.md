# man/

`.Rd` files in this directory are GENERATED from roxygen comments in
`R/*.R`. To regenerate after editing R sources:

```r
devtools::document()
```

This package ships one hand-written stub (`bsv-package.Rd`) so the
package can be installed before `devtools::document()` is ever run.
Other `.Rd` files appear automatically after the first `document()` call.
