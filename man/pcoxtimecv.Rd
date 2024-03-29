% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pcoxtimecv.R
\name{pcoxtimecv}
\alias{pcoxtimecv}
\title{Cross-validation for pcoxtime}
\usage{
pcoxtimecv(
  formula,
  data,
  alphas = 1,
  lambdas = NULL,
  nlambdas = 100,
  lammin_fract = NULL,
  lamfract = 0.6,
  nfolds = 10,
  foldids = NULL,
  devtype = "vv",
  refit = FALSE,
  maxiter = 1e+05,
  tol = 1e-08,
  quietly = FALSE,
  seed = NULL,
  nclusters = 1,
  na.action = na.omit,
  ...
)
}
\arguments{
\item{formula}{object of class formula describing
the model. The response is specified similar to
\code{\link[survival]{Surv}} function from package
\strong{survival}. The terms (predictors) are specified
on the right of "~" in the formula.}

\item{data}{optional data frame containing
variables specified in the formula.}

\item{alphas}{elasticnet mixing parameter, with
\code{0 <= alphas <= 1}. If a vector of  \code{alphas} is supplied, cross-validation will be performed for each of the \code{alphas} and optimal value returned. The default is \code{1}.}

\item{lambdas}{optional user-supplied sequence. If \code{lambdas = NULL} (default -- highly recommended), the algorithm chooses its own sequence.}

\item{nlambdas}{the default number of lambdas values. Default is \code{100}.}

\item{lammin_fract}{smallest value of \code{lambda}, as fraction of maximum \code{lambda}. If \code{NULL}, default, it depends on the number of observations (n) relative to the number of variables (p). If \code{n > p}, the default is \code{0.0001}, otherwise \code{0.01}. Increasing this value may lead to faster convergence.}

\item{lamfract}{proportion of regularization path to consider. If \code{lamfract = 1}, complete regularization path is considered. However, if \code{0.5 <= lamfract <1}, only a proportion of the \code{nlambdas} considered. Choosing a smaller \code{lamfract} reduces computational time and potentially stable estimates for model with large number of predictors. See details.}

\item{nfolds}{number of folds. Default is \code{10}. The smallest allowable is \code{nfolds = 3}.}

\item{foldids}{an optional sequence of values between \code{1} and {nfolds} specifying what fold each observation is in. This is important when comparing performance across models. If specified, \code{nfolds} can be missing.}

\item{devtype}{loss to use for cross-validation. Currently, two options are available but versions will implement \code{\link[pcoxtime]{concordScore.pcoxtime}} loss too. The two are, default \code{(devtype = "vv")} Verweij Van Houwelingen partial-likelihood deviance and basic cross-validated parial likelihood \code{devtype = "basic"}. See Dai, B., and Breheny, P. (2019) for details.}

\item{refit}{logical. Whether to return solution path based on optimal lambda and alpha picked by the model. Default is \code{refit = FALSE}.}

\item{maxiter}{maximum number of iterations to convergence. Default is \eqn{1e5}. Consider increasing it if the model does not converge.}

\item{tol}{convergence threshold for proximal gradient gradient descent. Each proximal update continues until the relative change in all the coefficients (i.e. \eqn{\sqrt{\sum(\beta_{k+1} - \beta_k)^2}}/stepsize) is less than tol. The default value is \eqn{1e-8}.}

\item{quietly}{logical. If TRUE, refit progress is printed.}

\item{seed}{random seed. Default is \code{NULL}, which generated the seed internally.}

\item{nclusters}{number of cores to use to run the cross-validation in parallel. Default is \code{nclusters = 1} which runs serial.}

\item{na.action}{a function which indicates what should happen when the data contain NAs.}

\item{...}{additional arguments not implemented.}
}
\value{
An S3 object of class \code{\link[pcoxtime]{pcoxtimecv}}:
\item{lambda.min}{the value of lambda that gives minimum cross-validated error.}
\item{lambda.1se}{largest value of lambda such that error is within \code{1} standard error of the minimum.}
\item{alpha.optimal}{optimal alpha corresponding to \code{lambda.min}.}
\item{lambdas.optimal}{the sequence of lambdas containing \code{lambda.min}.}
\item{foldids}{the fold assignment used.}
\item{dfs}{list of data frames containing mean cross-validated error summaries and estimated coefficients in each fold.}
\item{fit}{if \code{refit = TRUE}, summaries corresponding to the optimal \code{alpha} and \code{lambdas}. This is used to plot solution path}.
}
\description{
Performs \code{k}-fold cross-validation for pcoxtime, plots 
solution path plots, and returns optimal value of lambda
(and optimal alpha if more than one is given).
}
\details{
The function fits \code{\link[pcoxtime]{pcoxtime}} \code{folds + 1} (if \code{refit = FALSE}) or \code{folds + 2} times  (if \code{refit = FALSE}). In the former case, the solution path to display using \code{\link[pcoxtime]{plot.pcoxtimecv}} is randomly picked from all the cross-validation runs. However, in the later case, the solution path plot is based on the model refitted using the optimal parameters. In both cases, the function first runs  \code{\link[pcoxtime]{plot.pcoxtimecv}} to compute the lambda sequence and then perform cross-validation on \code{nfolds}.

If more than one \code{alphas} is specified, say code{(0.2, 0.5, 1)}, the \code{pcoxtimecv} will search (experimental) for optimal values for alpha with respect to the corresponding lambda values. In this case, optimal alpha and lambda sequence will be returned, i.e., the \code{(alphas, lambdas)} pair that corresponds to the lowest predicted cross-validated error (likelihood deviance).

For data sets with a very large number of predictors, it is recommended to only calculate partial paths by lowering the value of \code{lamfract}. In other words, for \code{p > n} problems, the near \code{lambda = 0} solution is poorly behaved and this may account for over \code{99\%} of the function's runtime. We therefore recommend always specifying \code{lamfract < 1} and increase if the optimal lambda suggests lower values.
}
\examples{

# Time-independent covariates
if (packageVersion("survival")>="3.2.9") {
   data(cancer, package="survival")
} else {
   data(veteran, package="survival")
}
\donttest{
cv1 <- pcoxtimecv(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
	, data = veteran
	, alphas = 1
	, refit = FALSE
	, lamfract = 0.6
)
print(cv1)

# Train model using optimal alpha and lambda
fit1 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
	, data = veteran
	, alpha = cv1$alpha.optimal
	, lambda = cv1$lambda.min
)
print(fit1)
# Time-varying covariates
data(heart, package="survival")
cv2 <- pcoxtimecv(Surv(start, stop, event) ~ age + year + surgery + transplant
	, data = heart
	, alphas = 1
	, refit = FALSE
	, lamfract = 0.6
)
print(cv2)

# Train model
fit2 <- pcoxtime(Surv(start, stop, event) ~ age + year + surgery + transplant
	, data = heart
	, alpha = cv2$alpha.optimal
	, lambda = cv2$lambda.min
)
print(fit2)
}
}
\references{
Dai, B., and Breheny, P. (2019). \emph{Cross validation approaches for penalized Cox regression}. \emph{arXiv preprint arXiv:1905.10432}.

Simon, N., Friedman, J., Hastie, T., Tibshirani, R. (2011) \emph{Regularization Paths for Cox's Proportional Hazards Model via Coordinate Descent, Journal of Statistical Software, Vol. 39(5) 1-13} \doi{https://doi.org/10.18637/jss.v039.i05}.
}
\seealso{
\code{\link[pcoxtime]{plot.pcoxtimecv}}, \code{\link[pcoxtime]{pcoxtime}}
}
