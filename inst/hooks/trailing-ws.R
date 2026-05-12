## Hook: trailing-whitespace
## Strips trailing whitespace from each line. Fails (with status 1) if any
## file was modified, so pre-commit re-stages and the analyst sees the change.

files <- commandArgs(trailingOnly = TRUE)
modified <- character()

for (f in files) {
  if (!file.exists(f)) next
  lines <- readLines(f, warn = FALSE)
  cleaned <- sub("[ \t]+$", "", lines)
  if (!identical(lines, cleaned)) {
    writeLines(cleaned, f)
    modified <- c(modified, f)
  }
}

if (length(modified)) {
  cat("Stripped trailing whitespace from:\n  ", paste(modified, collapse = "\n  "),
      "\nRe-stage the files and commit again.\n", sep = "")
  quit(status = 1)
}
