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
Invisibly returns \code{TRUE} if installed, \code{FALSE} otherwise.
}
\description{
The 'pre-commit' framework is a small Python binary that needs to be on
PATH for the hooks to run. On a network-restricted VM you likely need to
install it yourself (via your internal pip mirror, \code{pipx},
\code{conda} or \code{brew}); this function prints those instructions.
If the optional \pkg{precommit} R package is installed, it will be used
to install pre-commit into an isolated conda env.
}
