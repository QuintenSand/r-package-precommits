# =============================================================================
# Hook implementations dispatched from .pre-commit-config.yaml
#
# Each hook is a function named `hook_<id-with-underscores>` that:
#   * takes a character vector of file paths (passed by pre-commit)
#   * returns TRUE if the hook passed, FALSE otherwise
#   * may modify files in place (in which case it should still return FALSE
#     so the user re-stages and commits again — that's the pre-commit
#     convention for "auto-fix" hooks).
#
# run_hook() is the entry point called from each YAML hook via:
#   Rscript --no-init-file -e 'precommitr::run_hook("<id>", commandArgs(TRUE))'
# =============================================================================

#' Dispatch a precommitr hook
#'
#' Entry point invoked from `.pre-commit-config.yaml`. Looks up the
#' implementation by name, runs it, and exits with status 1 on failure so
#' pre-commit knows to block the commit.
#'
#' @param hook Hook id, e.g. `"style-files"` or `"no-browser-statement"`.
#' @param files Character vector of file paths to operate on. Defaults to
#'   the trailing command-line args, which is what pre-commit passes.
#' @return Invisibly returns `TRUE` on success. In non-interactive mode the
#'   process exits with status 1 on failure.
#' @export
run_hook <- function(hook, files = commandArgs(trailingOnly = TRUE)) {
  fname <- paste0("hook_", gsub("-", "_", hook))
  ns <- asNamespace("precommitr")
  if (!exists(fname, envir = ns, mode = "function", inherits = FALSE)) {
    msg <- sprintf("Unknown precommitr hook: '%s'", hook)
    if (interactive()) stop(msg, call. = FALSE)
    message(msg)
    quit(status = 1, save = "no")
  }
  fn <- get(fname, envir = ns, mode = "function", inherits = FALSE)

  ok <- tryCatch(
    isTRUE(fn(files)),
    error = function(e) {
      message(sprintf("Hook '%s' errored: %s", hook, conditionMessage(e)))
      FALSE
    }
  )

  if (!ok) {
    if (interactive()) return(invisible(FALSE))
    quit(status = 1, save = "no")
  }
  invisible(TRUE)
}

# ---- helpers ---------------------------------------------------------------

# Return parse data (token table) for an R file, or NULL on parse error.
.parse_tokens <- function(file) {
  tryCatch(
    {
      e <- parse(file = file, keep.source = TRUE)
      utils::getParseData(e)
    },
    error = function(e) NULL
  )
}

# Forbid one or more named function calls in R files using the parser.
# Robust against false positives in comments/strings.
.forbid_calls <- function(files, names, msg) {
  files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
  ok <- TRUE
  for (f in files) {
    pd <- .parse_tokens(f)
    if (is.null(pd) || nrow(pd) == 0L) next
    hits <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% names, , drop = FALSE]
    if (nrow(hits) > 0L) {
      for (i in seq_len(nrow(hits))) {
        cat(sprintf(
          "%s:%d:%d: %s: %s()\n",
          f, hits$line1[i], hits$col1[i], msg, hits$text[i]
        ))
      }
      ok <- FALSE
    }
  }
  ok
}

# Read a file as raw bytes (works for any encoding).
.read_bytes <- function(file) {
  n <- file.info(file)$size
  if (is.na(n) || n == 0) return(raw(0))
  readBin(file, what = "raw", n = n)
}

.write_bytes <- function(file, bytes) {
  con <- file(file, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(bytes, con)
}

# ---- individual hooks ------------------------------------------------------

hook_parsable_R <- function(files) {
  files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
  ok <- TRUE
  for (f in files) {
    out <- tryCatch(parse(file = f), error = function(e) e)
    if (inherits(out, "error")) {
      cat(sprintf("%s: parse error: %s\n", f, conditionMessage(out)))
      ok <- FALSE
    }
  }
  ok
}

hook_style_files <- function(files) {
  files <- files[grepl("\\.(R|Rmd|qmd)$", files, ignore.case = TRUE)]
  if (length(files) == 0L) return(TRUE)
  if (!requireNamespace("styler", quietly = TRUE)) {
    message("styler is not installed. Run: install.packages('styler')")
    return(FALSE)
  }
  changed <- FALSE
  for (f in files) {
    before <- .read_bytes(f)
    suppressMessages(
      styler::style_file(f, transformers = styler::tidyverse_style())
    )
    after <- .read_bytes(f)
    if (!identical(before, after)) {
      cat(sprintf("styler: reformatted %s\n", f))
      changed <- TRUE
    }
  }
  !changed
}

hook_lintr <- function(files) {
  files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
  if (length(files) == 0L) return(TRUE)
  if (!requireNamespace("lintr", quietly = TRUE)) {
    message("lintr not installed; skipping. Run: install.packages('lintr')")
    return(TRUE)
  }
  for (f in files) {
    lints <- lintr::lint(f)
    if (length(lints) > 0L) print(lints)
  }
  # warn-only: never block the commit
  TRUE
}

hook_no_browser_statement <- function(files) {
  .forbid_calls(files, "browser", "forbidden call (remove before committing)")
}

hook_no_debug_statement <- function(files) {
  .forbid_calls(
    files,
    c("debug", "debugonce", "undebug"),
    "forbidden debug call (remove before committing)"
  )
}

hook_no_print_statement <- function(files) {
  # Excluded by default for tests/, inst/, vignettes/ — analysts may want
  # print() there. Caller can filter further via `files:`/`exclude:` in YAML.
  files <- files[!grepl("(^|/)(tests|inst|vignettes)/", files)]
  .forbid_calls(files, "print", "use cli/message instead of print()")
}

hook_trailing_whitespace <- function(files) {
  changed <- FALSE
  for (f in files) {
    if (!file.exists(f) || dir.exists(f)) next
    lines <- tryCatch(
      readLines(f, warn = FALSE, encoding = "UTF-8"),
      error = function(e) NULL
    )
    if (is.null(lines)) next
    stripped <- sub("[ \t]+$", "", lines)
    if (!identical(lines, stripped)) {
      writeLines(stripped, f)
      cat(sprintf("trailing-whitespace: fixed %s\n", f))
      changed <- TRUE
    }
  }
  !changed
}

hook_end_of_file_fixer <- function(files) {
  changed <- FALSE
  for (f in files) {
    if (!file.exists(f) || dir.exists(f)) next
    bytes <- .read_bytes(f)
    if (length(bytes) == 0L) next
    # Trim trailing blank-line bytes (LF only), then ensure exactly one LF.
    while (length(bytes) > 0L && bytes[length(bytes)] == as.raw(0x0a)) {
      bytes <- bytes[-length(bytes)]
    }
    new <- c(bytes, as.raw(0x0a))
    orig <- .read_bytes(f)
    if (!identical(new, orig)) {
      .write_bytes(f, new)
      cat(sprintf("end-of-file-fixer: fixed %s\n", f))
      changed <- TRUE
    }
  }
  !changed
}

hook_mixed_line_ending <- function(files) {
  changed <- FALSE
  for (f in files) {
    if (!file.exists(f) || dir.exists(f)) next
    bytes <- .read_bytes(f)
    if (length(bytes) == 0L) next
    if (any(bytes == as.raw(0x0d))) {
      bytes <- bytes[bytes != as.raw(0x0d)]
      .write_bytes(f, bytes)
      cat(sprintf("mixed-line-ending: normalised %s to LF\n", f))
      changed <- TRUE
    }
  }
  !changed
}

hook_check_merge_conflict <- function(files) {
  ok <- TRUE
  for (f in files) {
    if (!file.exists(f) || dir.exists(f)) next
    lines <- tryCatch(
      readLines(f, warn = FALSE, encoding = "UTF-8"),
      error = function(e) NULL
    )
    if (is.null(lines)) next
    hits <- grep("^(<{7}|={7}|>{7})( |$)", lines)
    if (length(hits) > 0L) {
      for (h in hits) {
        cat(sprintf("%s:%d: merge-conflict marker: %s\n", f, h, lines[h]))
      }
      ok <- FALSE
    }
  }
  ok
}

hook_check_yaml <- function(files) {
  files <- files[grepl("\\.(ya?ml)$", files, ignore.case = TRUE)]
  if (length(files) == 0L) return(TRUE)
  if (!requireNamespace("yaml", quietly = TRUE)) {
    message("yaml package not installed; skipping check-yaml. ",
            "Install with: install.packages('yaml')")
    return(TRUE)
  }
  ok <- TRUE
  for (f in files) {
    out <- tryCatch(
      yaml::yaml.load_file(f),
      error = function(e) e
    )
    if (inherits(out, "error")) {
      cat(sprintf("%s: invalid YAML: %s\n", f, conditionMessage(out)))
      ok <- FALSE
    }
  }
  ok
}

hook_check_added_large_files <- function(files, max_kb = 2048L) {
  ok <- TRUE
  for (f in files) {
    if (!file.exists(f) || dir.exists(f)) next
    size_kb <- file.info(f)$size / 1024
    if (isTRUE(size_kb > max_kb)) {
      cat(sprintf(
        "%s is %.1f KB (> %d KB limit). Use git-lfs or .gitignore.\n",
        f, size_kb, max_kb
      ))
      ok <- FALSE
    }
  }
  ok
}
