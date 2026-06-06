# ============================================================================
# BSV - Plumber2 API
# ============================================================================
# Wraps the PostgreSQL database in a REST/JSON interface. This is the ONLY
# component allowed to talk to the database; Shiny and MCP consume HTTP.
# ============================================================================

library(bsv)
library(plumber)
library(jsonlite)

# Pool is shared across requests and lives for the API process lifetime.
.pool <- bsv::db_pool()

# Ensure schema exists on startup (idempotent)
tryCatch(
  bsv::db_init_schema(.pool),
  error = function(e) message("Schema init warning: ", conditionMessage(e))
)

# Graceful shutdown -- closes the pool when the process exits.
reg.finalizer(environment(), function(e) {
  try(bsv::db_disconnect(.pool), silent = TRUE)
}, onexit = TRUE)

#* @apiTitle BSV API
#* @apiDescription REST interface over the BSV database. Consumed by the
#*   Shiny dashboard and the MCP server.
#* @apiVersion 0.1.0

#* Enable CORS so the Shiny app can call us from a different origin
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin",  "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  if (identical(req$REQUEST_METHOD, "OPTIONS")) {
    res$status <- 200
    return(list())
  }
  plumber::forward()
}

#* Health check
#* @get /health
function() {
  bsv::api_health()
}

#* List articles
#* @param limit:int Max items to return (default 10, max 200)
#* @param offset:int Items to skip
#* @param processed:bool Filter by processed flag (optional)
#* @get /articles
function(limit = 10, offset = 0, processed = NULL) {
  only_processed <- if (is.null(processed)) NULL else as.logical(processed)
  bsv::api_articles_list(.pool, limit = limit, offset = offset,
                         only_processed = only_processed)
}

#* Article by id (with MITRE mappings)
#* @param id:int Article id
#* @get /articles/<id:int>
function(id, res) {
  out <- bsv::api_articles_by_id(.pool, id)
  if (is.null(out)) {
    res$status <- 404
    return(list(error = "Article not found", id = id))
  }
  out
}

#* Search articles by title/summary
#* @param query:str Search query (ILIKE)
#* @param limit:int Max items
#* @get /search
function(query = "", limit = 20) {
  bsv::api_search(.pool, query, limit = limit)
}

#* MITRE statistics
#* @param by Either "tactic" or "technique"
#* @param top_n:int Top-N items
#* @get /mitre/stats
function(by = "tactic", top_n = 20) {
  bsv::api_mitre_stats(.pool, by = by, top_n = top_n)
}
