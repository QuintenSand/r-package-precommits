% Generated manually — keep in sync with R/run_hook.R
\name{run_hook}
\alias{run_hook}
\title{Run a packaged hook script}
\usage{
run_hook(name, files = commandArgs(trailingOnly = TRUE))
}
\arguments{
\item{name}{Character. Hook name (matches a file \code{inst/hooks/<name>.R}).}

\item{files}{Character vector of files to check. Defaults to
\code{commandArgs(trailingOnly = TRUE)}, which is what pre-commit passes.}
}
\value{
Invisibly \code{NULL}. Side effect: runs the hook, which may call
\code{quit()} and terminate the R session with a non-zero status.
}
\description{
Internal dispatcher used by entries in \code{.pre-commit-config.yaml}. Looks
up a hook script bundled with the package under \code{inst/hooks/} and
sources it, passing the list of files as
\code{commandArgs(trailingOnly = TRUE)}.
}
\details{
Each hook script under \code{inst/hooks/<name>.R} is expected to read
filenames from \code{commandArgs(trailingOnly = TRUE)}, print a useful
message on failure, and call \code{quit(status = 1)} to fail the hook
(or fall through to pass).
}
