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
    quit(status = 2, save = "no")
  }

  # Hook scripts read their args via commandArgs(); override it inside the
  # hook's evaluation environment so each script sees its own file list.
  hook_env <- new.env(parent = globalenv())
  hook_env$commandArgs <- function(trailingOnly = FALSE) {
    if (isTRUE(trailingOnly)) files else c("Rscript", files)
  }

  sys.source(script, envir = hook_env)
  invisible(NULL)
}
