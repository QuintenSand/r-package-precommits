#' Install the pre-commit framework on the user's machine
#'
#' The 'pre-commit' framework is a small Python binary that needs to be on
#' PATH for the hooks to run. On a network-restricted VM you likely need to
#' install it yourself (via your internal pip mirror, `pipx`, `conda` or
#' `brew`); this function prints those instructions. If the optional
#' `precommit` R package is installed, it will be used to install pre-commit
#' into an isolated conda env.
#'
#' @param force Re-install even if it appears to be installed already.
#' @return Invisibly returns `TRUE` if installed, `FALSE` otherwise.
#' @export
install_precommit <- function(force = FALSE) {
  if (!force && isTRUE(check_precommit_install(verbose = FALSE))) {
    cli::cli_alert_success("pre-commit is already installed on this machine.")
    return(invisible(TRUE))
  }

  if (requireNamespace("precommit", quietly = TRUE)) {
    cli::cli_alert_info("Installing pre-commit via {.pkg precommit}...")
    precommit::install_precommit()
    cli::cli_alert_success("pre-commit installed.")
    return(invisible(TRUE))
  }

  cli::cli_alert_warning("The {.code pre-commit} binary is not on PATH.")
  cli::cli_text("Install it with ONE of:")
  cli::cli_ul(c(
    "{.code pip install --user pre-commit}",
    "{.code pipx install pre-commit}",
    "{.code brew install pre-commit}      (macOS)",
    "{.code conda install -c conda-forge pre-commit}"
  ))
  cli::cli_text(
    "Then re-run {.run precommitr::check_precommit_install()} to verify."
  )
  invisible(FALSE)
}

#' Copy the shared organisation pre-commit config into the current repo
#'
#' Drops the bundled `.pre-commit-config.yaml` (the one shared by the whole
#' team) into the root of the given git repository and runs
#' `pre-commit install` so the hooks fire on every `git commit`.
#'
#' The bundled config uses only `repo: local` hooks dispatched through
#' [run_hook()], so no network access is required at install time.
#'
#' @param path Path to the git repository. Defaults to the current working
#'   directory.
#' @param overwrite Overwrite an existing `.pre-commit-config.yaml`? Default
#'   `FALSE`; you'll be asked interactively if a file already exists.
#' @param open Open the freshly copied config in RStudio (if available).
#'   Default `interactive()`.
#' @return Invisibly returns the path to the written
#'   `.pre-commit-config.yaml`.
#' @export
#' @examples
#' \dontrun{
#' # From inside an R project that is also a git repo:
#' precommitr::use_precommits()
#' }
use_precommits <- function(path = ".",
                           overwrite = FALSE,
                           open = interactive()) {
  path <- normalizePath(path, mustWork = TRUE)
  if (!dir.exists(file.path(path, ".git"))) {
    stop(
      "'", path, "' is not a git repository. ",
      "Run `git init` first, then try again.",
      call. = FALSE
    )
  }

  target <- file.path(path, ".pre-commit-config.yaml")
  template <- system.file(
    "templates", "pre-commit-config.yaml",
    package = "precommitr",
    mustWork = TRUE
  )

  if (file.exists(target) && !overwrite) {
    if (interactive()) {
      answer <- utils::menu(
        choices = c("Yes, overwrite", "No, keep existing"),
        title = paste0(
          ".pre-commit-config.yaml already exists in:\n  ",
          path,
          "\nOverwrite with the shared org config?"
        )
      )
      if (answer != 1L) {
        cli::cli_alert_info("Keeping existing config; nothing copied.")
        return(invisible(target))
      }
    } else {
      stop(
        ".pre-commit-config.yaml already exists at '", target,
        "'. Re-run with overwrite = TRUE to replace it.",
        call. = FALSE
      )
    }
  }

  fs::file_copy(template, target, overwrite = TRUE)
  cli::cli_alert_success("Copied shared config to {.file {target}}.")

  # Run `pre-commit install` so the hook is active on git commits.
  if (!isTRUE(check_precommit_install(verbose = FALSE))) {
    cli::cli_alert_warning(
      "pre-commit is not on PATH; run {.run precommitr::install_precommit()} first."
    )
  } else {
    cli::cli_alert_info("Activating git hooks via {.code pre-commit install}...")
    status <- system2(
      "pre-commit",
      args = c("install", "--install-hooks"),
      stdout = TRUE,
      stderr = TRUE
    )
    rc <- attr(status, "status")
    if (is.null(rc) || identical(rc, 0L)) {
      cli::cli_alert_success("Git hooks installed in {.file {path}}.")
    } else {
      cli::cli_alert_danger(
        "pre-commit install failed:\n{paste(status, collapse = '\n')}"
      )
    }
  }

  if (isTRUE(open) && rstudioapi_available()) {
    rstudioapi::navigateToFile(target)
  }

  invisible(target)
}

#' Refresh the pre-commit config in the current repo
#'
#' Re-copies the bundled `.pre-commit-config.yaml` over the existing one.
#' This is the recommended way to adopt new hook versions org-wide: bump
#' `precommitr`, ask analysts to upgrade the package, then call this.
#'
#' Because all hooks are `repo: local`, there is nothing to "autoupdate" --
#' upgrading the `precommitr` package is the only thing that changes hook
#' behaviour.
#'
#' @param path Path to the repo. Defaults to the working directory.
#' @return Invisibly returns the path to the updated config.
#' @export
update_config <- function(path = ".") {
  use_precommits(path = path, overwrite = TRUE, open = FALSE)
}

#' Check whether the 'pre-commit' executable is on PATH
#'
#' @param verbose Print a status message. Default `TRUE`.
#' @return `TRUE` if `pre-commit` is callable, `FALSE` otherwise.
#' @export
check_precommit_install <- function(verbose = TRUE) {
  found <- nzchar(Sys.which("pre-commit"))
  if (isTRUE(verbose)) {
    if (found) {
      cli::cli_alert_success("pre-commit is installed.")
    } else {
      cli::cli_alert_danger(
        "pre-commit not found on PATH. Run {.run precommitr::install_precommit()}."
      )
    }
  }
  invisible(found)
}

# ---- internal helpers ------------------------------------------------------

rstudioapi_available <- function() {
  requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()
}
