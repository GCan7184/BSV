# ============================================================================
# BSV - MCP Server (HTTP transport, JSON-RPC 2.0)
# ============================================================================
# Minimal Model Context Protocol server. Exposes BSV search/list/mitre
# capabilities to AI agents. Talks to the data layer ONLY via the plumber2
# API at $BSV_API_URL.
# ============================================================================

library(plumber)
library(httr2)
library(jsonlite)

.api_url <- Sys.getenv("BSV_API_URL", "http://api:8000")

# ----- helpers ---------------------------------------------------------------

api_get <- function(path, query = list()) {
  req <- httr2::request(paste0(.api_url, path)) |>
    httr2::req_timeout(30)
  if (length(query) > 0L) {
    req <- do.call(httr2::req_url_query, c(list(.req = req), query))
  }
  resp <- httr2::req_perform(req)
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

jsonrpc_result <- function(id, result) {
  list(jsonrpc = "2.0", id = id, result = result)
}

jsonrpc_error <- function(id, code, message, data = NULL) {
  err <- list(code = code, message = message)
  if (!is.null(data)) err$data <- data
  list(jsonrpc = "2.0", id = id, error = err)
}

# ----- tool registry ---------------------------------------------------------
# Each tool follows the MCP spec: name, description, inputSchema (JSON Schema).

tools_registry <- list(
  list(
    name = "search_threat_intel",
    description = "Search BSV's arXiv corpus for cybersecurity papers by free-text query (matches title and abstract).",
    inputSchema = list(
      type = "object",
      properties = list(
        query = list(type = "string", description = "Search text"),
        limit = list(type = "integer", description = "Max results (default 20)", default = 20)
      ),
      required = list("query")
    )
  ),
  list(
    name = "list_articles",
    description = "List most recent articles with pagination.",
    inputSchema = list(
      type = "object",
      properties = list(
        limit  = list(type = "integer", default = 10),
        offset = list(type = "integer", default = 0)
      )
    )
  ),
  list(
    name = "get_article",
    description = "Get a single article by id, including its MITRE ATT&CK mappings.",
    inputSchema = list(
      type = "object",
      properties = list(
        id = list(type = "integer", description = "Article id from BSV DB")
      ),
      required = list("id")
    )
  ),
  list(
    name = "mitre_stats",
    description = "Aggregated counts of MITRE tactics or techniques across the corpus.",
    inputSchema = list(
      type = "object",
      properties = list(
        by    = list(type = "string", enum = list("tactic", "technique"), default = "tactic"),
        top_n = list(type = "integer", default = 20)
      )
    )
  )
)

# ----- dispatcher ------------------------------------------------------------

call_tool <- function(name, arguments) {
  arguments <- arguments %||% list()
  switch(
    name,
    "search_threat_intel" = api_get("/search", list(
      query = arguments$query %||% "",
      limit = arguments$limit %||% 20
    )),
    "list_articles" = api_get("/articles", list(
      limit  = arguments$limit  %||% 10,
      offset = arguments$offset %||% 0
    )),
    "get_article" = api_get(paste0("/articles/", as.integer(arguments$id))),
    "mitre_stats" = api_get("/mitre/stats", list(
      by    = arguments$by    %||% "tactic",
      top_n = arguments$top_n %||% 20
    )),
    stop(paste0("Unknown tool: ", name))
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ----- HTTP endpoint ---------------------------------------------------------

#* @apiTitle BSV MCP Server
#* @apiDescription Model Context Protocol server (JSON-RPC 2.0 over HTTP).

#* JSON-RPC endpoint
#* @post /rpc
#* @serializer unboxedJSON
function(req, res) {
  body <- tryCatch(
    jsonlite::fromJSON(req$postBody, simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (is.null(body)) {
    res$status <- 400
    return(jsonrpc_error(NULL, -32700, "Parse error"))
  }

  id     <- body$id
  method <- body$method
  params <- body$params %||% list()

  if (is.null(method)) {
    return(jsonrpc_error(id, -32600, "Invalid Request: missing method"))
  }

  result <- tryCatch({
    switch(
      method,
      "initialize" = list(
        protocolVersion = "2024-11-05",
        capabilities    = list(tools = list(listChanged = FALSE)),
        serverInfo      = list(name = "bsv-mcp", version = "0.1.0")
      ),
      "tools/list" = list(tools = tools_registry),
      "tools/call" = {
        tool_name <- params$name
        if (is.null(tool_name)) stop("tools/call: 'name' is required")
        content   <- call_tool(tool_name, params$arguments)
        list(
          content = list(
            list(type = "text", text = jsonlite::toJSON(content, auto_unbox = TRUE, null = "null"))
          ),
          isError = FALSE
        )
      },
      stop(paste0("Method not found: ", method))
    )
  }, error = function(e) {
    structure(list(message = conditionMessage(e)), class = "bsv_error")
  })

  if (inherits(result, "bsv_error")) {
    return(jsonrpc_error(id, -32000, result$message))
  }
  jsonrpc_result(id, result)
}

#* Health check
#* @get /health
function() {
  list(status = "ok", service = "bsv-mcp",
       timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
}
