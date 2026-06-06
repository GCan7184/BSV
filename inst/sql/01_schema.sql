-- BSV — initial schema. Idempotent.

CREATE TABLE IF NOT EXISTS articles (
  id         SERIAL PRIMARY KEY,
  arxiv_id   VARCHAR(64) UNIQUE NOT NULL,
  title      TEXT NOT NULL,
  summary    TEXT,
  published  TIMESTAMP,
  link       TEXT,
  processed  BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mitre_mappings (
  id              SERIAL PRIMARY KEY,
  article_id      INTEGER NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  tactic          VARCHAR(128),
  technique_id    VARCHAR(32),
  technique_name  VARCHAR(256),
  explanation     TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_articles_published ON articles(published DESC);
CREATE INDEX IF NOT EXISTS idx_articles_processed ON articles(processed);
CREATE INDEX IF NOT EXISTS idx_mitre_article      ON mitre_mappings(article_id);
CREATE INDEX IF NOT EXISTS idx_mitre_technique    ON mitre_mappings(technique_id);
