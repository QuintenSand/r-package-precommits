## Hook: lintr (warn-only)
## Runs lintr on each R file and prints results. Never blocks the commit;
## change `quit(status = 0)` to `quit(status = 1)` below if you want it
## to block.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
if (length(files) == 0L) quit(status = 0)

if (!requireNamespace("lintr", quietly = TRUE)) {
  cat("lintr not installed; skipping. install.packages('lintr')\n",
      file = stderr())
  quit(status = 0)
}

for (f in files) {
  lints <- lintr::lint(f)
  if (length(lints) > 0L) print(lints)
}

# warn-only
quit(status = 0)
