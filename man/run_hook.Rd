% Generated manually — keep in sync with R/hooks.R
\name{run_hook}
\alias{run_hook}
\title{Dispatch a precommitr hook}
\usage{
run_hook(hook, files = commandArgs(trailingOnly = TRUE))
}
\arguments{
\item{hook}{Hook id, e.g. \code{"style-files"} or \code{"no-browser-statement"}.}

\item{files}{Character vector of file paths to operate on. Defaults to the
trailing command-line args, which is what pre-commit passes.}
}
\value{
Invisibly returns \code{TRUE} on success. In non-interactive mode the
process exits with status 1 on failure.
}
\description{
Entry point invoked from \code{.pre-commit-config.yaml}. Looks up the
implementation by name, runs it, and exits with status 1 on failure so
pre-commit knows to block the commit.
}
\details{
Each hook is implemented as a function named \verb{hook_<id-with-underscores>}
inside \pkg{precommitr}. The following hooks ship by default:
\code{parsable-R}, \code{style-files}, \code{lintr},
\code{no-browser-statement}, \code{no-debug-statement},
\code{no-print-statement}, \code{trailing-whitespace},
\code{end-of-file-fixer}, \code{mixed-line-ending},
\code{check-merge-conflict}, \code{check-yaml},
\code{check-added-large-files}.
}
