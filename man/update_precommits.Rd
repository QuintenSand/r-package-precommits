% Generated manually — keep in sync with R/use_precommits.R
\name{update_precommits}
\alias{update_precommits}
\title{Update the pre-commit hooks in the current repo to the latest pinned
versions shipped by 'precommitr'}
\usage{
update_precommits(path = ".", autoupdate = FALSE)
}
\arguments{
\item{path}{Path to the repo. Defaults to the working directory.}

\item{autoupdate}{Also run \code{pre-commit autoupdate} to pull new hook
revisions from upstream. Default \code{FALSE} (the bundled config is the
source of truth).}
}
\value{
Invisibly returns the path to the updated config.
}
\description{
Re-copies the bundled \code{.pre-commit-config.yaml} over the existing
one and optionally runs \code{pre-commit autoupdate}. This is the
recommended way to adopt new hook versions org-wide: bump \code{precommitr},
ask analysts to upgrade the package, then call this function.
}
