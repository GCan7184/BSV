# BSV
BSV — Base of Security Vectors  R-пакет для автоматического сбора и обогащения научных публикаций с arXiv.org по кибербезопасности. ETL, тематическое моделирование, Shiny-дашборд для визуализации трендов и MCP-сервер для доступа AI-агентов. Контейнеризация через Docker. Разрабатывается в рамках учебного курса.
# Архитектура проекта

```mermaid
graph TB
    subgraph "Docker Host"
        subgraph "Docker Network"
            subgraph "Container: ETL"
                ETL1[etl_job.R] -->|Сбор данных| API[arXiv API]
                ETL1 -->|Запись| VOL1[(Volume: raw_data)]
            end

            subgraph "Container: Database"
                DB[(DuckDB/PostgreSQL<br>Volume: db_data)]
            end

            subgraph "Container: Processing"
                PROC[analysis_job.R] -->|Читает| VOL1
                PROC -->|Анализ/ML| DB
            end

            subgraph "Container: Shiny App"
                SHINY[Shiny Server] -->|Читает| DB
                SHINY -->|Порт 3838| USER[Пользователь<br>Браузер]
            end

            subgraph "Container: MCP Server"
                MCP[MCP Server R/plumber] -->|Читает| DB
                MCP -->|Порт 8080| AI[AI Агент]
            end
        end
        
        subgraph "Orchestration"
            COMPOSE[docker-compose.yml] -->|Управляет| ETL1
            COMPOSE -->|Управляет| DB
            COMPOSE -->|Управляет| PROC
            COMPOSE -->|Управляет| SHINY
            COMPOSE -->|Управляет| MCP
        end
    end

    style ETL1 fill:#f9f,stroke:#333,stroke-width:2px
    style SHINY fill:#ccf,stroke:#333,stroke-width:2px
    style MCP fill:#cfc,stroke:#333,stroke-width:2px
    style DB fill:#ffc,stroke:#333,stroke-width:2px
    style COMPOSE fill:#ddd,stroke:#333,stroke-width:2px
```
