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
#' blank line after the hook finishes (whether the hook quits explicitly or
#' falls through). It does this by shadowing `quit()` inside the hook's
#' evaluation environment with a wrapper that prints `"\n"` first, then
#' delegates to `base::quit()`. A plain `on.exit` wouldn't work because
#' `quit()` terminates R before exit handlers fire.
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

  # Each hook gets its own evaluation environment. We override:
  #   * commandArgs() so the hook sees its file list
  #   * quit() / q() so they print a trailing blank line before R exits,
  #     keeping per-hook output visually separated in pre-commit's display.
  hook_env <- new.env(parent = globalenv())

  hook_env$commandArgs <- function(trailingOnly = FALSE) {
    if (isTRUE(trailingOnly)) files else c("Rscript", files)
  }

  end_with_newline_quit <- function(save = "default", status = 0,
                                    runLast = TRUE) {
    cat("\n")
    base::quit(save = save, status = status, runLast = runLast)
  }
  hook_env$quit <- end_with_newline_quit
  hook_env$q    <- end_with_newline_quit

  sys.source(script, envir = hook_env)

  # If the script fell through without calling quit(), still emit the
  # trailing newline so the next hook's header isn't glued to this hook's
  # last line of output.
  cat("\n")
  invisible(NULL)
}
