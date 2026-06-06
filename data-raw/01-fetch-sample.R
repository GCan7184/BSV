# ============================================================================
# data-raw/01-fetch-sample.R
# ----------------------------------------------------------------------------
# Run this once to populate `data/arxiv_sample.rda`. The resulting dataset is
# exported as `bsv::arxiv_sample` and used by the vignette + tests.
#
#   Rscript data-raw/01-fetch-sample.R
# ============================================================================

devtools::load_all(".")

message("Fetching 20 recent cs.CR papers from arXiv...")
arxiv_sample <- fetch_arxiv(category = "cs.CR", max_results = 20L)

message("Got ", nrow(arxiv_sample), " papers. First titles:")
print(head(arxiv_sample$title, 3))

usethis::use_data(arxiv_sample, overwrite = TRUE)
message("Saved to data/arxiv_sample.rda")
