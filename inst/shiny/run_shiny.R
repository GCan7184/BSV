host <- Sys.getenv("BSV_SHINY_HOST", "0.0.0.0")
port <- as.integer(Sys.getenv("BSV_SHINY_PORT", "3838"))
message(sprintf("Starting BSV Shiny on %s:%d (API: %s)",
                host, port, Sys.getenv("BSV_API_URL", "http://localhost:8000")))
shiny::runApp(
  system.file("shiny", package = "bsv"),
  host = host, port = port, launch.browser = FALSE
)
