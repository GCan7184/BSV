# ============================================================================
# BSV - shared image for api / shiny / mcp containers.
# ----------------------------------------------------------------------------
# Base: rocker/r2u -- ships R + apt-based CRAN binary repo.
# We install R packages as native .deb via apt-get (r2u maps every CRAN
# package to `r-cran-<name>`). This is the idiomatic r2u workflow and is
# the fastest, most reliable way: no R-side downloads at all.
# ============================================================================
FROM rocker/r2u:22.04

# All R packages we need as Ubuntu .deb packages from the r2u repo.
# Naming: CRAN 'dplyr' -> apt 'r-cran-dplyr' (lowercased).
RUN apt-get update && apt-get install -y --no-install-recommends \
        pandoc \
        git \
        wget \
        ca-certificates \
        r-cran-httr2 \
        r-cran-xml2 \
        r-cran-dplyr \
        r-cran-tibble \
        r-cran-tidyr \
        r-cran-purrr \
        r-cran-stringr \
        r-cran-lubridate \
        r-cran-dbi \
        r-cran-rpostgres \
        r-cran-pool \
        r-cran-jsonlite \
        r-cran-glue \
        r-cran-rlang \
        r-cran-plumber \
        r-cran-shiny \
        r-cran-shinydashboard \
        r-cran-dt \
        r-cran-plotly \
        r-cran-testthat \
        r-cran-knitr \
        r-cran-rmarkdown \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY DESCRIPTION NAMESPACE LICENSE ./
COPY R/         ./R/
COPY inst/      ./inst/
COPY man/       ./man/
COPY data/      ./data/
COPY tests/     ./tests/
COPY vignettes/ ./vignettes/

RUN R CMD INSTALL --no-multiarch --with-keep.source .

EXPOSE 8000 8001 3838
CMD ["R", "--no-save"]
