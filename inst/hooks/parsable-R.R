## Hook: parsable-R
## Fails if any R file can't be parsed.

files <- commandArgs(trailingOnly = TRUE)
errors <- character()

for (f in files) {
  out <- tryCatch(parse(file = f), error = function(e) e)
  if (inherits(out, "error")) {
    errors <- c(errors, sprintf("  %s: %s", f, conditionMessage(out)))
  }
}

if (length(errors)) {
  cat("Unparsable R file(s):\n", paste(errors, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
