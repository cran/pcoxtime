% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methodfuns.R
\name{print.pcoxtime}
\alias{print.pcoxtime}
\title{Print coefficients from a pcoxtime object}
\usage{
\method{print}{pcoxtime}(x, ..., nprint = 10)
}
\arguments{
\item{x}{fitted \code{\link[pcoxtime]{pcoxtime}} model object}

\item{...}{for future implementations}

\item{nprint}{number of coefficients to print out}
}
\value{
A two column output, the first column is the coefficient estimate and the second column is the exponent of the coefficient estimate. Additonal summary about the number of nonzero coefficents, the number of observations and the number of event of interest are also printed.
}
\description{
This function prints a summary of the pcoxtime object.
}
\details{
The call that produced \code{\link[pcoxtime]{pcoxtime}} is printed, followed by coefficient estimates with their corresponding exponentiated values. 
Depending on the number of coefficients, \code{nprint} can be used to specify the number of coefficients to print out.
}
