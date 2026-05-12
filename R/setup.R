#' One-time setup on a new machine
#'
#' Checks that the `pre-commit` executable is available on PATH. Pre-commit is
#' a Python tool and must be installed separately (e.g. via your organization's
#' Posit Package Manager Python mirror, `pipx`, or `uv tool install pre-commit`).
#' This function does not attempt to install it, because in an air-gapped
#' environment the right install path is org-specific.
#'
#' @return Invisibly `TRUE` if pre-commit is available, otherwise stops with an
#'   informative message.
#' @export
setup <- function() {
  if (precommit_available()) {
    cli::cli_alert_success("pre-commit is installed and on PATH.")
    return(invisible(TRUE))
  }
  cli::cli_abort(c(
    "The {.code pre-commit} executable was not found on PATH.",
    "i" = "Pre-commit is a Python tool and must be installed separately.",
    "i" = "Ask your admin, or try {.code pipx install pre-commit} / {.code uv tool install pre-commit}.",
    "i" = "See the package README for organization-specific install instructions."
  ))
}

precommit_available <- function() {
  nzchar(Sys.which("pre-commit"))
}
