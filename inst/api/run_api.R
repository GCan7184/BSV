# Entry point for the API container.
# Run with:   Rscript inst/api/run_api.R
host <- Sys.getenv("BSV_API_HOST", "0.0.0.0")
port <- as.integer(Sys.getenv("BSV_API_PORT", "8000"))

message(sprintf("Starting BSV API on %s:%d", host, port))
pr <- plumber::pr(system.file("api", "plumber.R", package = "bsv"))
plumber::pr_run(pr, host = host, port = port)
