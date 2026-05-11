% Generated manually — keep in sync with R/use_precommits.R
\name{use_precommits}
\alias{use_precommits}
\title{Copy the shared organisation pre-commit config into the current repo}
\usage{
use_precommits(path = ".", overwrite = FALSE, open = interactive())
}
\arguments{
\item{path}{Path to the git repository. Defaults to the current working directory.}

\item{overwrite}{Overwrite an existing \code{.pre-commit-config.yaml}?
Default \code{FALSE}; you'll be asked interactively if a file already exists.}

\item{open}{Open the freshly copied config in RStudio (if available).
Default \code{interactive()}.}
}
\value{
Invisibly returns the path to the written \code{.pre-commit-config.yaml}.
}
\description{
Drops the bundled \code{.pre-commit-config.yaml} (the one shared by the
whole team) into the root of the given git repository and runs
\code{pre-commit install} so the hooks fire on every \code{git commit}.
}
\examples{
\dontrun{
precommitr::use_precommits()
}
}
