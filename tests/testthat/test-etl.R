test_that("clean_text strips line breaks and squishes whitespace", {
  expect_equal(clean_text("  hello\n world  "), "hello world")
  expect_equal(clean_text("a\t\tb\r\n\nc"), "a b c")
  expect_equal(clean_text(""), "")
  expect_length(clean_text(NULL), 0L)
})

test_that("clean_text is vectorised", {
  out <- clean_text(c("  a  ", "b\nb"))
  expect_equal(out, c("a", "b b"))
})

test_that("parse_arxiv_xml extracts expected fields", {
  # Minimal Atom feed with one entry
  xml <- xml2::read_xml(
    '<feed xmlns="http://www.w3.org/2005/Atom">
       <entry>
         <id>http://arxiv.org/abs/2401.01234v1</id>
         <title>Sample Paper on Phishing</title>
         <summary>We study phishing detection.</summary>
         <published>2024-01-15T10:00:00Z</published>
       </entry>
     </feed>'
  )
  df <- parse_arxiv_xml(xml)

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 1L)
  expect_equal(df$arxiv_id, "2401.01234")
  expect_equal(df$title, "Sample Paper on Phishing")
  expect_match(df$summary, "phishing")
  expect_s3_class(df$published, "POSIXct")
})

test_that("parse_arxiv_xml handles empty feed", {
  xml <- xml2::read_xml('<feed xmlns="http://www.w3.org/2005/Atom"></feed>')
  df  <- parse_arxiv_xml(xml)
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0L)
})

test_that("fetch_arxiv builds a sensible query (network test)", {
  # Skip on CRAN / offline environments. CI sets NOT_CRAN=true.
  skip_on_cran()
  skip_if_offline()

  df <- fetch_arxiv("cs.CR", max_results = 5L)
  expect_s3_class(df, "tbl_df")
  expect_gt(nrow(df), 0L)
  expect_true(all(c("arxiv_id", "title", "summary", "published", "link") %in% names(df)))
})
