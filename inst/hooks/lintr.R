## Hook: lintr (warn-only)
## Runs lintr on each R file and prints results. Never blocks the commit;
## change `quit(status = 0)` to `quit(status = 1)` at the bottom if you
## want lint findings to block.
##
## The YAML entry for this hook sets `verbose: true` so pre-commit shows
## these warnings even when the hook passes (which it always does).

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
if (length(files) == 0L) {
  cat("lintr: no R files in this commit; skipping.\n")
  quit(status = 0)
}

if (!requireNamespace("lintr", quietly = TRUE)) {
  cat("lintr not installed; skipping. install.packages('lintr')\n",
      file = stderr())
  quit(status = 0)
}

cat(sprintf("lintr: linting %d R file(s) (warn-only) ...\n", length(files)))

total <- 0L
for (f in files) {
  lints <- lintr::lint(f)
  n <- length(lints)
  total <- total + n
  if (n > 0L) print(lints)
}

if (total == 0L) {
  cat(sprintf("lintr: %d file(s) clean.\n", length(files)))
} else {
  cat(sprintf("lintr: %d issue(s) found (warn-only, not blocking).\n", total))
}

quit(status = 0)
