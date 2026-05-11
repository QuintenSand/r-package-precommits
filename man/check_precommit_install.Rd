% Generated manually — keep in sync with R/use_precommits.R
\name{check_precommit_install}
\alias{check_precommit_install}
\title{Check whether the 'pre-commit' executable is on PATH}
\usage{
check_precommit_install(verbose = TRUE)
}
\arguments{
\item{verbose}{Print a status message. Default \code{TRUE}.}
}
\value{
\code{TRUE} if \code{pre-commit} is callable, \code{FALSE} otherwise.
}
\description{
Convenience wrapper that returns whether the system \code{pre-commit}
executable is available.
}
