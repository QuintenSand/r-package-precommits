## Hook: style-files
## Runs styler::style_file() on each .R / .Rmd / .qmd file in the commit.
##
## Behaviour:
##   * Always exits 0 -- never blocks the commit.
##   * After styler edits the working-tree files, the hook re-stages them
##     with `git add` so the commit includes the styled version.
##
## Implementation note: we shell out to a fresh `Rscript` subprocess to do
## the actual styling, rather than calling styler::style_file() in-process.
## Reason: styler 1.11's internal NSE silently fails with
##     "object 'terminal' not found"
## when style_file() is invoked from inside this hook's
## `sys.source(envir = hook_env)` wrapper, even when re-routed through
## eval(envir = globalenv()). The bug appears to depend on the call-stack
## depth (something inside styler reads `sys.call(n)`/`sys.frame(n)` at a
## fixed offset), so the only reliable fix is to run styler at the same
## stack depth as a standalone `Rscript -e 'styler::style_file(...)'`
## invocation -- i.e. in a fresh R process. Slower (~1-2s of R startup
## per commit), but bulletproof.

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

# All files processed in one subprocess so we pay R-startup cost once.
# Inside the subprocess, commandArgs(trailingOnly = TRUE) gives the file
# vector exactly as we pass it on the command line.
#
# IMPORTANT: system2() on Unix paste-joins its args into a single string
# and runs it through `sh -c`, only shell-quoting `command` itself. The
# raw `-e` expression contains parens, `<-`, `;`, `{}`, etc. which sh
# tries to interpret, so we must shQuote() every arg ourselves.
subprocess_expr <- paste(
  "args <- commandArgs(trailingOnly = TRUE);",
  "for (f in args) {",
  "  styler::style_file(f, transformers = styler::tidyverse_style())",
  "}"
)

status <- system2(
  "Rscript",
  args = shQuote(c("-e", subprocess_expr, files))
)

if (!identical(status, 0L)) {
  cat(sprintf(
    "styler: Rscript subprocess exited with status %d\n", status
  ))
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
