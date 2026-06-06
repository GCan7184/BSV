# ============================================================================
# data-raw/02-bootstrap-db.R
# ----------------------------------------------------------------------------
# End-to-end smoke test: fetch -> save to PostgreSQL -> enrich with MITRE.
# Requires a running PostgreSQL instance (e.g. `docker compose up db`).
#
#   Rscript data-raw/02-bootstrap-db.R
# ============================================================================

devtools::load_all(".")

con <- db_connect()
on.exit(db_disconnect(con), add = TRUE)

message("Initializing schema...")
db_init_schema(con)

message("Fetching 50 cs.CR papers...")
df <- fetch_arxiv("cs.CR", max_results = 50L)
message("Got ", nrow(df), " papers.")

message("Saving to DB (skipping duplicates)...")
n_new <- save_articles(con, df)
message("Inserted ", n_new, " new rows.")

message("Enriching with MITRE (method=auto)...")
res <- enrich_mitre(con, limit = 50L, method = "auto")
print(res)

message("Done.")
