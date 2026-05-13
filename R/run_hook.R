#' Run a packaged hook script
#'
#' Internal dispatcher used by entries in `.pre-commit-config.yaml`. Looks up
#' a hook script bundled with the package under `inst/hooks/` and sources it,
#' passing the list of files as `commandArgs(trailingOnly = TRUE)`.
#'
#' Each hook script under `inst/hooks/<name>.R` is expected to:
#'   * read filenames from `commandArgs(trailingOnly = TRUE)`,
#'   * print a useful message on failure,
#'   * call `quit(status = 1)` to fail the hook (or fall through to pass).
#'
#' This makes every hook a small, standalone R script that can be read and
#' edited without touching the rest of the package.
#'
#' For readability in `git commit` output, the dispatcher emits a trailing
#' blank line after each hook finishes (whether the hook quits explicitly
#' or falls through). It does this by shadowing `quit()` with a wrapper
#' that prints `"\n"` first, then delegates to `base::quit()`.
#'
#' Implementation note: the script is sourced into `globalenv()` rather than
#' a custom child env. That matters because some packages -- notably styler
#' 1.11+ -- use non-standard evaluation that walks the call stack looking
#' for "the user's environment". Sourcing into a child env adds an extra
#' frame between styler and `globalenv()`, which causes styler's NSE
#' lookups to land in our wrapper env instead of `globalenv()` and fail
#' with "object 'terminal' not found" (a column name in styler's parse
#' tibble). Sourcing into `globalenv()` makes the call stack look
#' identical to an interactive `styler::style_file()` call.
#'
#' @param name Character. Hook name (matches a file `inst/hooks/<name>.R`).
#' @param files Character vector of files to check. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`, which is what pre-commit passes.
#'
#' @return Invisibly `NULL`. Side effect: runs the hook, which may call
#'   `quit()` and terminate the R session with a non-zero status.
#' @export
run_hook <- function(name, files = commandArgs(trailingOnly = TRUE)) {
  script <- system.file("hooks", paste0(name, ".R"), package = "precommitr")
  if (!nzchar(script)) {
    cat("Unknown precommitr hook: '", name, "'\n", sep = "", file = stderr())
    cat("\n")
    base::quit(status = 2, save = "no")
  }

  ge <- globalenv()

  # Snapshot anything we're about to clobber so we can restore on fall-
  # through. (When the hook script calls quit(), R exits and we never
  # reach the restore -- which is fine because the process is dying.)
  prev_cmdargs <- if (exists("commandArgs", envir = ge, inherits = FALSE)) {
    get("commandArgs", envir = ge, inherits = FALSE)
  } else NULL
  prev_quit <- if (exists("quit", envir = ge, inherits = FALSE)) {
    get("quit", envir = ge, inherits = FALSE)
  } else NULL
  prev_q <- if (exists("q", envir = ge, inherits = FALSE)) {
    get("q", envir = ge, inherits = FALSE)
  } else NULL

  # Override commandArgs() so the hook script sees its file list, even
  # when run_hook() is called interactively with explicit `files`.
  assign(
    "commandArgs",
    function(trailingOnly = FALSE) {
      if (isTRUE(trailingOnly)) files else c("Rscript", files)
    },
    envir = ge
  )

  # Override quit() / q() so each hook ends with a trailing blank line
  # for readability in pre-commit's combined output.
  end_with_newline_quit <- function(save = "default", status = 0,
                                    runLast = TRUE) {
    cat("\n")
    base::quit(save = save, status = status, runLast = runLast)
  }
  assign("quit", end_with_newline_quit, envir = ge)
  assign("q",    end_with_newline_quit, envir = ge)

  # Source into globalenv() so styler / dplyr NSE see the same call stack
  # they would in an interactive session.
  sys.source(script, envir = ge)

  # Fall-through path: the script returned without quit(). Restore the
  # overrides and emit the trailing newline ourselves.
  if (is.null(prev_cmdargs)) {
    rm("commandArgs", envir = ge)
  } else {
    assign("commandArgs", prev_cmdargs, envir = ge)
  }
  if (is.null(prev_quit)) rm("quit", envir = ge) else assign("quit", prev_quit, envir = ge)
  if (is.null(prev_q))    rm("q",    envir = ge) else assign("q",    prev_q,    envir = ge)

  cat("\n")
  invisible(NULL)
}
