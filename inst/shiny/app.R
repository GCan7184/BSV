# ============================================================================
# BSV - Shiny dashboard
# ============================================================================
# Three tabs:
#   1. Feed         - latest articles (DT::datatable)
#   2. MITRE        - bar chart of tactics / techniques (plotly)
#   3. Article card - title, summary, links to abstract, list of MITRE TTPs
# ============================================================================

library(bsv)
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(httr2)
library(jsonlite)
library(dplyr)

API_URL <- Sys.getenv("BSV_API_URL", "http://localhost:8000")

# ---------- API client helpers ----------------------------------------------

api_call <- function(path, query = list()) {
  req <- httr2::request(paste0(API_URL, path)) |>
    httr2::req_timeout(15)
  if (length(query) > 0L) {
    req <- do.call(httr2::req_url_query, c(list(.req = req), query))
  }
  resp <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
  if (is.null(resp)) return(NULL)
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

# ---------- UI ---------------------------------------------------------------

ui <- shinydashboard::dashboardPage(
  skin = "purple",
  shinydashboard::dashboardHeader(title = "BSV — Base of Security Vectors"),
  shinydashboard::dashboardSidebar(
    shinydashboard::sidebarMenu(
      shinydashboard::menuItem("Лента статей", tabName = "feed",    icon = icon("newspaper")),
      shinydashboard::menuItem("Анализ MITRE", tabName = "mitre",   icon = icon("chart-bar")),
      shinydashboard::menuItem("Карточка",     tabName = "article", icon = icon("file-lines"))
    ),
    hr(),
    div(style = "padding: 0 15px; color: #aaa; font-size: 12px;",
        "API:", textOutput("api_status", inline = TRUE))
  ),
  shinydashboard::dashboardBody(
    shinydashboard::tabItems(

      # ---- Tab 1: feed -------------------------------------------------------
      shinydashboard::tabItem(
        tabName = "feed",
        fluidRow(
          shinydashboard::box(
            width = 12, title = "Свежие статьи (arXiv cs.CR)", status = "primary",
            solidHeader = TRUE,
            fluidRow(
              column(6, textInput("search", "Поиск по тексту:", placeholder = "phishing, ransomware...")),
              column(3, numericInput("limit", "Показать:", value = 25, min = 1, max = 200)),
              column(3, br(), actionButton("refresh", "Обновить", icon = icon("rotate"),
                                            class = "btn-primary"))
            ),
            DT::DTOutput("articles_table")
          )
        )
      ),

      # ---- Tab 2: MITRE analytics --------------------------------------------
      shinydashboard::tabItem(
        tabName = "mitre",
        fluidRow(
          shinydashboard::box(
            width = 4, title = "Параметры", status = "info", solidHeader = TRUE,
            radioButtons("group_by", "Группировать по:",
                         choices  = c("Тактика" = "tactic", "Техника" = "technique"),
                         selected = "tactic"),
            sliderInput("top_n", "Top-N:", min = 5, max = 30, value = 15)
          ),
          shinydashboard::box(
            width = 8, title = "Распределение MITRE TTP в корпусе", status = "primary",
            solidHeader = TRUE, plotly::plotlyOutput("mitre_chart", height = 460)
          )
        )
      ),

      # ---- Tab 3: article card -----------------------------------------------
      shinydashboard::tabItem(
        tabName = "article",
        fluidRow(
          shinydashboard::box(
            width = 12, title = "Карточка статьи", status = "primary", solidHeader = TRUE,
            numericInput("article_id", "ID статьи:", value = 1, min = 1, width = "200px"),
            actionButton("load_article", "Загрузить", icon = icon("download")),
            hr(),
            uiOutput("article_card")
          )
        )
      )
    )
  )
)

# ---------- server -----------------------------------------------------------

server <- function(input, output, session) {

  # ---- API status indicator ------------------------------------------------
  output$api_status <- renderText({
    invalidateLater(15000, session)
    h <- api_call("/health")
    if (is.null(h)) "OFFLINE" else h$status
  })

  # ---- Reactive: articles list --------------------------------------------
  articles <- reactive({
    input$refresh
    q <- isolate(input$search)
    if (!is.null(q) && nzchar(trimws(q))) {
      api_call("/search", list(query = q, limit = isolate(input$limit)))
    } else {
      api_call("/articles", list(limit = isolate(input$limit), offset = 0))
    }
  })

  output$articles_table <- DT::renderDT({
    df <- articles()
    if (is.null(df) || length(df) == 0L) {
      return(DT::datatable(data.frame(Message = "Нет данных или API недоступен")))
    }
    df <- as.data.frame(df)
    if ("summary" %in% names(df)) df$summary <- substr(df$summary, 1, 200)
    if ("link" %in% names(df)) {
      df$link <- paste0("<a href='", df$link, "' target='_blank'>arXiv</a>")
    }
    DT::datatable(
      df,
      escape    = FALSE,
      rownames  = FALSE,
      options   = list(pageLength = 10, scrollX = TRUE, dom = "tip"),
      selection = "single"
    )
  })

  # When a row is clicked, jump to the Article tab
  observeEvent(input$articles_table_rows_selected, {
    sel <- input$articles_table_rows_selected
    df  <- articles()
    if (!is.null(sel) && !is.null(df) && length(df) > 0L) {
      updateNumericInput(session, "article_id", value = df$id[sel])
      shinydashboard::updateTabItems(session, "tabs", "article")
    }
  })

  # ---- MITRE chart ---------------------------------------------------------
  output$mitre_chart <- plotly::renderPlotly({
    stats <- api_call("/mitre/stats", list(by = input$group_by, top_n = input$top_n))
    if (is.null(stats) || length(stats) == 0L) {
      return(plotly::plot_ly() |> plotly::add_annotations(
        text = "Нет данных. Запустите enrich_mitre().",
        showarrow = FALSE, font = list(size = 16)
      ))
    }
    df <- as.data.frame(stats)
    df <- df[order(df$n_articles), ]
    df$label <- factor(df$label, levels = df$label)

    plotly::plot_ly(
      df, x = ~n_articles, y = ~label, type = "bar", orientation = "h",
      marker = list(color = "#605ca8")
    ) |>
      plotly::layout(
        xaxis = list(title = "Число статей"),
        yaxis = list(title = "", automargin = TRUE),
        margin = list(l = 200)
      )
  })

  # ---- Article card --------------------------------------------------------
  observeEvent(input$load_article, {
    output$article_card <- renderUI({
      data <- api_call(paste0("/articles/", as.integer(input$article_id)))
      if (is.null(data) || is.null(data$article) || length(data$article) == 0L) {
        return(div(class = "alert alert-warning", "Статья не найдена."))
      }
      a <- data$article
      m <- data$mitre

      mitre_ui <- if (is.null(m) || length(m) == 0L) {
        tags$em("MITRE-маппинг не сделан. Запустите enrich_mitre().")
      } else {
        m <- as.data.frame(m)
        tagList(lapply(seq_len(nrow(m)), function(i) {
          div(class = "panel panel-default", style = "margin-top: 10px;",
              div(class = "panel-heading",
                  tags$strong(paste0(m$technique_id[i], " — ", m$technique_name[i])),
                  tags$span(class = "label label-info", style = "margin-left: 8px;",
                            m$tactic[i])),
              div(class = "panel-body", m$explanation[i]))
        }))
      }

      tagList(
        h3(a$title),
        tags$p(tags$strong("arXiv ID: "), a$arxiv_id,
               " | ",
               tags$strong("Опубликовано: "), a$published),
        tags$p(tags$a(href = a$link, target = "_blank", "Открыть на arXiv →")),
        hr(),
        h4("Аннотация"),
        tags$p(a$summary),
        hr(),
        h4("MITRE ATT&CK"),
        mitre_ui
      )
    })
  })
}

shinyApp(ui = ui, server = server)
