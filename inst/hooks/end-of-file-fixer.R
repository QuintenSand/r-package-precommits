## Hook: end-of-file-fixer
## Ensures each file ends with exactly one LF.

files <- commandArgs(trailingOnly = TRUE)
modified <- character()

for (f in files) {
  if (!file.exists(f) || dir.exists(f)) next
  size <- file.info(f)$size
  if (is.na(size) || size == 0) next

  bytes <- readBin(f, what = "raw", n = size)

  # Trim trailing LF bytes, then add exactly one back.
  while (length(bytes) > 0L && bytes[length(bytes)] == as.raw(0x0a)) {
    bytes <- bytes[-length(bytes)]
  }
  new <- c(bytes, as.raw(0x0a))

  orig <- readBin(f, what = "raw", n = size)
  if (!identical(new, orig)) {
    con <- file(f, open = "wb")
    writeBin(new, con)
    close(con)
    modified <- c(modified, f)
  }
}

if (length(modified)) {
  cat("Fixed end-of-file in:\n  ", paste(modified, collapse = "\n  "),
      "\nRe-stage the files and commit again.\n", sep = "")
  quit(status = 1)
}
