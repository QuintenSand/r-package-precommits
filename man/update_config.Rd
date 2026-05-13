% Generated manually — keep in sync with R/use_precommits.R
\name{update_config}
\alias{update_config}
\title{Refresh the pre-commit config in the current repo}
\usage{
update_config(path = ".")
}
\arguments{
\item{path}{Path to the repo. Defaults to the working directory.}
}
\value{
Invisibly returns the path to the updated config.
}
\description{
Re-copies the bundled \code{.pre-commit-config.yaml} over the existing
one. This is the recommended way to adopt new hook versions org-wide:
bump \code{precommitr}, ask analysts to upgrade the package, then call
this. Because all hooks are \code{repo: local}, there is nothing to
"autoupdate" -- upgrading the \code{precommitr} package is the only
thing that changes hook behaviour.
}
