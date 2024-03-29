% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/posthocfuns.R
\name{coefvimp.pcoxtime}
\alias{coefvimp.pcoxtime}
\title{Coefficient variable importance}
\usage{
coefvimp.pcoxtime(object, relative = TRUE, ...)
}
\arguments{
\item{object}{fitted \code{\link[pcoxtime]{pcoxtime}}.}

\item{relative}{logical. If \code{TRUE} the scores are divided by the absolute sum of the coefficients.}

\item{...}{for future implementation.}
}
\value{
a named vector of variable scores (\code{estimate = "mean"}) or a data frame (\code{estimate = "quantile"}).
}
\description{
Coefficient variable importance
}
\details{
Absolute value of the coefficients (parameters) corresponding the tuned pcoxtime object.
}
\keyword{internal}
