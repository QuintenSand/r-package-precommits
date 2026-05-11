% Generated manually — keep in sync with R/use_precommits.R
\name{install_precommit}
\alias{install_precommit}
\title{Install the pre-commit framework on the user's machine}
\usage{
install_precommit(force = FALSE)
}
\arguments{
\item{force}{Re-install even if it appears to be installed already.}
}
\value{
Invisibly returns \code{TRUE} on success.
}
\description{
Wrapper around \code{precommit::install_precommit()}. The 'pre-commit'
framework is a Python tool, so this needs to be done once per machine.
After this succeeds, every analyst can run \code{\link{use_precommits}()}
in any repo.
}
