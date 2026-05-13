## Hook: style-files
## Runs styler::style_file() on each .R / .Rmd / .qmd file in the commit.
##
## Behaviour:
##   * Always exits 0 — never blocks the commit.
##   * After styler edits the working-tree files, the hook re-stages them
##     with `git add` so the commit includes the styled version (otherwise
##     git's staged content is unchanged and the styled version would only
##     land in the *next* commit).
##
## Trade-off: the analyst doesn't get a chance to eyeball styler's changes
## before they land. If you'd rather have the standard pre-commit
## fix -> fail -> re-stage pattern, swap this script back to a version that
## detects modifications and exits 1.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.(R|Rmd|qmd)$", files, ignore.case = TRUE)]
if (length(files) == 0L) {
  cat("styler: no R / Rmd / qmd files in this commit; skipping.\n")
  quit(status = 0)
}

if (!requireNamespace("styler", quietly = TRUE)) {
  cat("styler is not installed. Run: install.packages('styler')\n",
      file = stderr())
  quit(status = 1)
}

cat(sprintf("styler: running tidyverse_style on %d file(s) ...\n",
            length(files)))

for (f in files) {
  # styler 1.11 fails with 'object terminal not found' when style_file()
  # is called from inside this hook's sourced child environment -- its
  # internal NSE (data-masking) walks the call stack with caller_env()
  # / parent.frame() and lands in our wrapper env instead of globalenv,
  # which breaks a tibble-column lookup deep inside styler. Running the
  # call via eval(... envir = globalenv()) makes styler see the same
  # call-stack it would in an interactive `styler::style_file()` call.
  eval(
    bquote(suppressMessages(
      styler::style_file(.(f), transformers = styler::tidyverse_style())
    )),
    envir = globalenv()
  )
}

# Re-stage any modifications styler made so they're part of the commit.
# `git add --` is safe even if a file is unchanged: it just no-ops.
add_res <- system2(
  "git",
  args = c("add", "--", files),
  stdout = TRUE,
  stderr = TRUE
)
rc <- attr(add_res, "status")
if (!is.null(rc) && !identical(rc, 0L)) {
  cat("styler: warning, `git add` exited with status ", rc, ":\n",
      paste(add_res, collapse = "\n"), "\n", sep = "")
}

cat("styler: done.\n")
quit(status = 0)
