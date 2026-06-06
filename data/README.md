# data/

This folder is intentionally (almost) empty in the repository.

To populate `arxiv_sample.rda`, run from the package root:

```bash
Rscript data-raw/01-fetch-sample.R
```

The script downloads 20 recent cs.CR papers from arXiv and saves them
through `usethis::use_data()` so the dataset is exported as
`bsv::arxiv_sample`.

This separation keeps the repository small and makes the data-collection
step part of the documented, reproducible pipeline (see PDF §"Воспроизводимость").
