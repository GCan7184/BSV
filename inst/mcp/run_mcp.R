host <- Sys.getenv("BSV_MCP_HOST", "0.0.0.0")
port <- as.integer(Sys.getenv("BSV_MCP_PORT", "8001"))

message(sprintf("Starting BSV MCP on %s:%d (API: %s)",
                host, port, Sys.getenv("BSV_API_URL", "http://api:8000")))

pr <- plumber::pr(system.file("mcp", "mcp_server.R", package = "bsv"))
plumber::pr_run(pr, host = host, port = port)
