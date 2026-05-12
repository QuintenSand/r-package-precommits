#' Run a packaged hook script
#'
#' Internal dispatcher used by entries in `.pre-commit-config.yaml`. Looks up a
#' hook script bundled with the package under `inst/hooks/` and sources it,
#' passing the list of files as `commandArgs(trailingOnly = TRUE)`.
#'
#' The hook script is expected to:
#' * Read filenames from `commandArgs(trailingOnly = TRUE)`
#' * Print a useful message on failure
#' * Call `quit(status = 1)` to fail the hook, or fall through to pass
#'
#' @param name Character. Hook name (matches a file `inst/hooks/<name>.R`).
#' @param files Character vector of files to check (typically `commandArgs(TRUE)`).
#'
#' @return Invisibly `NULL`. Side effect: runs the hook, which may call
#'   `quit()` and terminate the R session with a non-zero status.
#' @export
run_hook <- function(name, files) {
  script <- system.file("hooks", paste0(name, ".R"), package = "yourorg.precommit")
  if (!nzchar(script)) {
    cat("Unknown hook:", name, "\n", file = stderr())
    quit(status = 2)
  }
  # The hook script reads its own args via commandArgs(); we expose them by
  # overriding commandArgs inside the eval environment.
  hook_env <- new.env(parent = globalenv())
  hook_env$commandArgs <- function(trailingOnly = FALSE) {
    if (trailingOnly) files else c("Rscript", files)
  }
  sys.source(script, envir = hook_env)
  invisible(NULL)
}
