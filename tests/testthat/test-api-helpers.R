test_that("api_health returns ok", {
  h <- api_health()
  expect_equal(h$status, "ok")
  expect_equal(h$service, "bsv-api")
  expect_match(h$timestamp, "^\\d{4}-\\d{2}-\\d{2}T")
})

# The rest require a live PostgreSQL. We skip if it isn't reachable.
db_available <- function() {
  tryCatch({
    con <- db_connect()
    DBI::dbDisconnect(con)
    TRUE
  }, error = function(e) FALSE)
}

test_that("API helpers query a live DB end-to-end", {
  skip_if_not(db_available(), "PostgreSQL not reachable; skipping integration test.")

  pool <- db_pool()
  on.exit(db_disconnect(pool), add = TRUE)
  db_init_schema(pool)

  # Insert a sentinel row so /search has something to find
  DBI::dbExecute(
    pool,
    "INSERT INTO articles (arxiv_id, title, summary, published, link)
       VALUES ('test-0001', 'Phishing detection paper', 'study of phishing',
               NOW(), 'http://example.com/test')
       ON CONFLICT (arxiv_id) DO NOTHING"
  )

  out <- api_articles_list(pool, limit = 5L)
  expect_s3_class(out, "tbl_df")
  expect_gte(nrow(out), 1L)

  hits <- api_search(pool, "Phishing", limit = 5L)
  expect_gte(nrow(hits), 1L)
})
