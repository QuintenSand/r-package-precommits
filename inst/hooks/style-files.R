## Hook: style-files
## Auto-formats R / Rmd / qmd files with styler (tidyverse style).
## Fails (status 1) if anything was reformatted, so pre-commit re-stages
## the changes and the analyst can review + commit again.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.(R|Rmd|qmd)$", files, ignore.case = TRUE)]
if (length(files) == 0L) quit(status = 0)

if (!requireNamespace("styler", quietly = TRUE)) {
  cat("styler is not installed. Run: install.packages('styler')\n",
      file = stderr())
  quit(status = 1)
}

changed <- character()
for (f in files) {
  before <- readBin(f, what = "raw", n = file.info(f)$size)
  suppressMessages(
    styler::style_file(f, transformers = styler::tidyverse_style())
  )
  after <- readBin(f, what = "raw", n = file.info(f)$size)
  if (!identical(before, after)) changed <- c(changed, f)
}

if (length(changed)) {
  cat("styler reformatted:\n  ", paste(changed, collapse = "\n  "),
      "\nRe-stage the files and commit again.\n", sep = "")
  quit(status = 1)
}
