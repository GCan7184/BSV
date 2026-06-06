test_that("mitre_rules_dict has expected shape", {
  d <- mitre_rules_dict()
  expect_s3_class(d, "tbl_df")
  expect_true(all(c("keyword", "tactic", "technique_id", "technique_name") %in% names(d)))
  expect_gt(nrow(d), 10L)
  expect_true(all(grepl("^T\\d", d$technique_id)))
})

test_that("enrich_mitre_rules detects phishing", {
  out <- enrich_mitre_rules(
    title   = "Detecting Phishing URLs",
    summary = "We propose an LSTM model to detect phishing pages."
  )
  expect_s3_class(out, "tbl_df")
  expect_gte(nrow(out), 1L)
  expect_true("T1566" %in% out$technique_id)
})

test_that("enrich_mitre_rules respects max_hits", {
  out <- enrich_mitre_rules(
    title   = "Phishing, ransomware, and DDoS in modern threats",
    summary = "We discuss phishing, ransomware and ddos at length, plus c2.",
    max_hits = 2L
  )
  expect_lte(nrow(out), 2L)
})

test_that("enrich_mitre_rules returns empty on no match", {
  out <- enrich_mitre_rules("Cooking recipes", "Bake a delicious cake.")
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
})

test_that("enrich_mitre_rules deduplicates by technique_id", {
  # 'sql injection', 'xss', 'exploit' all map to T1190 in our dict
  out <- enrich_mitre_rules(
    title   = "Web attacks survey",
    summary = "We study SQL injection, XSS, and exploit techniques.",
    max_hits = 5L
  )
  expect_equal(length(unique(out$technique_id)), nrow(out))
})
