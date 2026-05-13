## Hook: mixed-line-ending
## Normalises line endings to LF by stripping CR bytes.

files <- commandArgs(trailingOnly = TRUE)
modified <- character()

for (f in files) {
  if (!file.exists(f) || dir.exists(f)) next
  size <- file.info(f)$size
  if (is.na(size) || size == 0) next

  bytes <- readBin(f, what = "raw", n = size)
  if (any(bytes == as.raw(0x0d))) {
    bytes <- bytes[bytes != as.raw(0x0d)]
    con <- file(f, open = "wb")
    writeBin(bytes, con)
    close(con)
    modified <- c(modified, f)
  }
}

if (length(modified)) {
  cat("Normalised line endings to LF in:\n  ",
      paste(modified, collapse = "\n  "),
      "\nRe-stage the files and commit again.\n", sep = "")
  quit(status = 1)
}
