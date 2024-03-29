#' Compute survival curve and cumulative hazard from a pcoxtime model
#'
#' Compute the predicted survivor and cumulative hazard function for a penalized Cox proportional hazard model.
#'
#' @aliases pcoxsurvfit
#'
#' @details
#' \code{pcoxsurvfit} and \code{pcoxbasehaz} functions produce survival curves and estimated cumulative hazard, respectively, for the fitted \code{\link[pcoxtime]{pcoxtime}} model. They both return the estimated survival probability and the estimated cumulative hazard, which are both Breslow estimate.
#'
#' The \code{pcoxbasehaz} is an alias for \code{pcoxsurvfit} which simply computed the predicted survival estimates (baseline).
#'
#' If the \code{newdata} argument is missing, the "average" survival or cumulative hazard estimates are produced with the predictor values equal to means of the data set. See \code{\link[survival]{survfit.coxph}} for warning against this. If the \code{newdata} is specified, then the returned object will contain a matrix of both survival and cumulative hazard estimates with each column for each row in the \code{newdata}.
#'
#' @param fit fitted \code{\link[pcoxtime]{pcoxtime}} object
#' @param newdata a data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula.
#' @param ... for future implementations
#'
#' @return \code{pcoxsurvfit} and \code{pcoxbasehaz} return S3 objects of class \code{\link[pcoxtime]{pcoxsurvfit.pcoxtime}} and \code{\link[pcoxtime]{pcoxbasehaz.pcoxtime}}, respectively:
#' \item{n}{number of observations used in the fit.}
#' \item{events}{total number of events of interest in the fit.}
#' \item{time}{time points defined by the risk set.}
#' \item{n.risk}{the number of individuals at risk at time \code{t}.}
#' \item{n.event}{the number of events that occur at time \code{t}.}
#' \item{n.censor}{the number of subjects who exit the risk set, without an event, at time \code{t}.}
#' \item{surv}{a vector or a matrix of estimated survival function.}
#' \item{cumhaz, hazard}{a vector or a matrix of estimated cumulative hazard.}
#' \item{call}{the call that produced the object.}
#'
#' @seealso
#' \code{\link[pcoxtime]{pcoxtime}}, \code{\link[pcoxtime]{plot.pcoxsurvfit}}
#'
#' @rdname pcoxsurvfit.pcoxtime
#'
#' @examples
#'
#' data(heart, package="survival")
#' lam <- 0.1
#' alp <- 0.8
#' pfit <- pcoxtime(Surv(start, stop, event) ~ age + year + surgery + transplant
#' 	, data = heart
#' 	, lambda = lam
#'		, alpha = alp
#'	)
#'
#' # Survival estimate
#' psurv <- pcoxsurvfit(pfit)
#' print(psurv)
#'
#' # Baseline survival estimate
#' bsurv <- pcoxbasehaz(pfit, centered = FALSE)
#'
#' @export
#'

pcoxsurvfit.pcoxtime <- function(fit, newdata, ...){

	afit <- predictedHazard(fit)
	chaz <- afit$chaz
	surv.est <- exp(-chaz)
	if (!missing(newdata)){
		lp <- predict(fit, newdata = newdata, type = "lp")
		surv.est <- t(sapply(surv.est, function(x) x^exp(lp)))
		chaz <- -log(surv.est)
	}

	out <- list(n = afit$n
		, events = sum(afit$n.event)
		, time = afit$time
		, n.risk = afit$n.risk
		, n.event = afit$n.event
		, n.censor = afit$n.censor
		, surv = surv.est
		, cumhaz = chaz
	)
	out$call <- match.call()
	class(out) <- "pcoxsurvfit"
	out
}

#' Compute baseline survival and cumulative hazard
#'
#' @aliases pcoxbasehaz
#'
#' @param centered if \code{TRUE} (default), return data from a predicted survival function at the mean values of the predictors, if \code{FALSE} returns prediction for all predictors equal to zero (baseline hazard).
#'
#' @rdname pcoxsurvfit.pcoxtime
#' @export
#'

pcoxbasehaz.pcoxtime <- function(fit, centered = TRUE){
	
	sfit <- pcoxsurvfit.pcoxtime(fit)

	## Expected cummulative hazard rate sum of hazard s.t y(t)<=t
	chaz <- sfit$cumhaz
	surv.est <- exp(-chaz)

	## Compute the cumhaz with the mean of the covariates otherwise set
	## all covariates to 0 (above)
	if (!centered) {
		beta.hat <- drop(fit$coef)
		## Centered estimates
		X.mean <- fit$means
		offset <- drop(X.mean %*% beta.hat)
		chaz <- chaz * exp(-offset)
		surv.est <- exp(-chaz)
	}
	out <- list(time = sfit$time, hazard = chaz, surv = surv.est)
	out$call <- match.call()
	class(out) <- c("pcoxbasehaz", "pcoxsurvfit")
	out
}

#' Prediction for pcoxtime model
#'
#' Compute fitted values and model terms for the pcoxtime model.
#'
#' @details
#' The computation of these predictions similar to those in \code{\link[survival]{predict.coxph}}. Our current implementation does not incorporate stratification.
#'
#' @param object fitted \code{\link[pcoxtime]{pcoxtime}} object
#' @param ... for future implementations.
#' @param newdata optional data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula. If absent, the predictions are for the data frame used in the original fit.
#' @param type the type of predicted value. Either linear predictor (\code{"lp"}), the risk score (\code{"risk"} equivalently \code{exp(lp)}), the expected number of events given the covariates and follow-up time (\code{"expected"}), the terms of linear predictor (\code{"terms"}) and the survival probability for each individual (\code{"survival"}).
#' @param terms if \code{type = "terms"}, this argument can be used to specify which terms to be return. Default is all.
#' @param na.action defines the missing value action for the \code{newdata}. If \code{newdata} is absent, then the behavior of missing is dictated by the \code{na.action} option of the original fit.
#'
#' @return a vector of predictions, depending on the \code{type}.
#'
#' @examples
#'
#' data(heart, package="survival")
#' lam <- 0.1
#' alp <- 0.8
#' pfit <- pcoxtime(Surv(start, stop, event) ~ age + year + surgery + transplant
#' 	, data = heart
#' 	, lambda = lam
#'		, alpha = alp
#'	)
#'
#' predict(pfit, type = "lp")
#' predict(pfit, type = "expected")
#' predict(pfit, type = "risk")
#' predict(pfit, type = "survival")
#' predict(pfit, type = "terms")
#'
#' @export

predict.pcoxtime <- function(object, ..., newdata = NULL, type = c("lp", "risk", "expected", "terms", "survival"), terms = object$predictors, na.action = na.pass){

	if (!missing(terms)){
		if (any(is.na(match(terms, object$predictors))))
			stop("a name given in the terms argument not found in the model")
	}

	type <- match.arg(type)
	if (type == "survival") {
		survival <- TRUE
		type <- "expected"
    } else {
	 	survival <- FALSE
	 }

	beta.hat <- drop(object$coef)
	timevar <- object$timevarlabel
	eventvar <- object$eventvarlabel
	all_terms <- object$predictors

	if (!is.null(newdata)) {
		if(type == "expected"){
			new_form <- object$terms
			m <- model.frame(new_form, data = newdata
				, xlev = object$xlevels, na.action = na.action
				, drop.unused.levels = TRUE
			)
			newY <- model.extract(m, "response")
		} else{
			new_form <- delete.response(object$terms)
			m <- model.frame(new_form, data = newdata
				, xlev = object$xlevels, na.action = na.action
				, drop.unused.levels = TRUE
			)
		}
		newX <- model.matrix(new_form, m, contr = object$contrasts, xlev = object$xlevels)
		xnames <- colnames(newX)
		assign <- setNames(attr(newX, "assign"), xnames)[-1]
		xnames <- names(assign)
		newX <- newX[ , xnames, drop=FALSE]
	} else {
		df <- object$data
		newY <- object$Y
		events <- df[, eventvar]
		times <- df[, timevar]
		assign <- object$assign
		xnames <- names(assign)
		newX <- df[, xnames, drop = FALSE]
	}

	## Linear predictors
	### Centered estimates
	xmeans <- object$means[xnames]
	newX.centered <- newX - rep(xmeans, each = NROW(newX))
	lp <- unname(drop(newX.centered %*% beta.hat))

	## Terms
	if (type == "terms"){
		term_list <- list()
		tvals <- unique(assign)
		for (i in seq_along(tvals)){
			w <- assign == tvals[i]
			term_list[[i]] <- newX.centered[, w, drop = FALSE] %*% beta.hat[w]
		}
		terms_df <- do.call("cbind", term_list)
		colnames(terms_df) <- all_terms
		if(!missing(terms)){	terms_df <- terms_df[, terms, drop = FALSE]}
	}

	## Borrowed from survival::predict
	if (type == "expected"){
		afit <- predictedHazard(object)
		times <- afit$time
		afit.n <- length(times)
		newrisk <- drop(exp(newX.centered %*% beta.hat))
		j1 <- approx(times, 1:afit.n, newY[,1], method = "constant", f = 0, yleft = 0, yright = afit.n)$y
		chaz <- c(0, afit$chaz)[j1 + 1]
		if (NCOL(newY)==2){
			expected <- unname(chaz * newrisk)
		} else {
		j2 <- approx(times, 1:afit.n, newY[,2], method = "constant", f = 0, yleft = 0, yright = afit.n)$y
			chaz2 <- c(0, afit$chaz)[j2 + 1]
			expected <- unname((chaz2 - chaz) * newrisk)
		}
		if (survival){
			survival <- exp(-expected)
			type <- "survival"
		}
	}

	out <- switch(type
		, lp = lp
		, risk = exp(lp)
		, terms = terms_df
		, expected = expected
		, survival = survival
	)
	return(out)
}

#' Compute predicted hazard
#'
#' This code is borrowed from internal function agsurv from survival package.
#'
#' @param fit fitted \code{\link[pcoxtime]{pcoxtime}}
#' @return A list of S3 objects.
#' \item{n}{number of observations used in the fit.}
#' \item{events}{total number of events of interest in the fit.}
#' \item{time}{time points defined by the risk set.}
#' \item{n.risk}{the number of individuals at risk at time \code{t}.}
#' \item{n.event}{the number of events that occur at time \code{t}.}
#' \item{n.censor}{the number of subjects who exit the risk set, without an event, at time \code{t}.}
#' \item{surv}{a vector or a matrix of estimated survival function.}
#' \item{chaz, hazard}{a vector or a matrix of estimated cumulative hazard.}
#' @keywords internal

predictedHazard <- function(fit){
	oldY <- fit$Y
	wt <- rep(1, NROW(oldY))
	assign <- fit$assign
	xnames <- names(assign)
	oldX <- fit$data[, xnames, drop = FALSE]
	beta.hat <- fit$coef
	xmeans <- fit$means
	oldX.centered <- oldX - rep(xmeans, each = NROW(oldX))
	oldlp <- unname(drop(oldX.centered %*% beta.hat))
	oldrisk <- exp(oldlp)
	status <- oldY[, ncol(oldY)]
	dtime <- oldY[, ncol(oldY) - 1]
	death <- (status == 1)
	time <- sort(unique(dtime))
	nevent <- as.vector(rowsum(wt * death, dtime))
	ncens <- as.vector(rowsum(wt * (!death), dtime))
	wrisk <- wt * oldrisk
	rcumsum <- function(x) rev(cumsum(rev(x)))
	nrisk <- rcumsum(rowsum(wrisk, dtime))
	irisk <- rcumsum(rowsum(wt, dtime))
	if (NCOL(oldY) != 2){
		delta <- min(diff(time))/2
		etime <- c(sort(unique(oldY[, 1])), max(oldY[, 1]) + delta)
		indx <- approx(etime, 1:length(etime), time, method = "constant", rule = 2, f = 1)$y
		esum <- rcumsum(rowsum(wrisk, oldY[, 1]))
		nrisk <- nrisk - c(esum, 0)[indx]
		irisk <- irisk - c(rcumsum(rowsum(wt, oldY[, 1])), 0)[indx]
	}
	haz <- nevent/nrisk
	result <- list(n = NROW(oldY), time = time, n.event = nevent
		, n.risk = irisk, n.censor = ncens, hazard = haz, chaz = cumsum(haz)
	)
	return(result)
}

#' Predict survival probabilities at various time points
#'
#' The function extracts the survival probability predictions from a \code{pcoxtime} model.
#'
#' @aliases predictSurvProb
#'
#' @param object fitted \code{\link[pcoxtime]{pcoxtime}}.
#' @param newdata a data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula.
#' @param times a vector of times in the range of the response, at which to return the survival probabilities.
#' @param ... for future implementations.
#'
#' @return a matrix of probabilities with as many rows as the rows of the \code{newdata} and as many columns as number of time points (\code{times}).
#'
#' @examples
#'
#' if (packageVersion("survival")>="3.2.9") {
#'    data(cancer, package="survival")
#' } else {
#'    data(veteran, package="survival")
#' }
#' # Penalized
#' lam <- 0.1
#' alp <- 0.5
#' pfit1 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' p1 <- predictSurvProb(pfit1, newdata = veteran[1:80,], times = 10)
#'
#' # Unpenalized
#' lam <- 0
#' alp <- 1
#' pfit2 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' p2 <- predictSurvProb(pfit2, newdata = veteran[1:80,], times = 10)
#' plot(p1, p2, xlim=c(0,1), ylim=c(0,1)
#' 	, xlab = "Penalized predicted survival chance at 10"
#' 	, ylab="Unpenalized predicted survival chance at 10"
#' )
#'
#' @importFrom prodlim sindex
#' @importFrom pec predictSurvProb
#' @export predictSurvProb
#' @export

predictSurvProb.pcoxtime <- function(object, newdata, times, ...){
	N <- NROW(newdata)
	sfit <- pcoxsurvfit(object, newdata = newdata)
	S <- t(sfit$surv)
	Time <- sfit$time
	if(N == 1) S <- matrix(S, nrow = 1)
	p <-  cbind(1, S)[, 1 + prodlim::sindex(Time, times),drop = FALSE]
	p
}

#' Extract predictions from pcoxtime model
#'
#' Extract event probabilities from the fitted model.
#'
#' @aliases predictRisk
#'
#' @details
#' For survival outcome, the function predicts the risk, \eqn{1 - S(t|x)}, where \eqn{S(t|x)} is the survival chance of an individual characterized by \eqn{x}.
#'
#' @param object fitted \code{\link[pcoxtime]{pcoxtime}}.
#' @param newdata a data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula.
#' @param times a vector of times in the range of the response, at which to return the survival probabilities.
#' @param ... for future implementations.
#'
#' @return a matrix of probabilities with as many rows as the rows of the \code{newdata} and as many columns as number of time points (\code{times}).
#'
#' @examples
#'
#' if (packageVersion("survival")>="3.2.9") {
#'    data(cancer, package="survival")
#' } else {
#'    data(veteran, package="survival")
#' }
#' # Penalized
#' lam <- 0.1
#' alp <- 0.5
#' pfit1 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' r1 <- predictRisk(pfit1, newdata = veteran[1:80,], times = 10)
#'
#' # Unpenalized
#' lam <- 0
#' alp <- 1
#' pfit2 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' r2 <- predictRisk(pfit2, newdata = veteran[1:80,], times = 10)
#' plot(r1, r2, xlim=c(0,1), ylim=c(0,1)
#' 	, xlab = "Penalized predicted survival chance at 10"
#' 	, ylab="Unpenalized predicted survival chance at 10"
#' )
#'
#' @importFrom riskRegression predictRisk
#' @export predictRisk
#' @export
predictRisk.pcoxtime <- function(object, newdata, times, ...){
	p <- 1 - predictSurvProb.pcoxtime(object, newdata, times)
	p
}

#' Compute the concordance statistic for the pcoxtime model
#'
#' The function computes the agreement between the observed response and the predictor.
#'
#' @aliases concordScore
#'
#' @details
#' Computes Harrell's C index for predictions for \code{\link[pcoxtime]{pcoxtime}} object and takes into account censoring. See \code{\link[survival]{concordance}}.
#'
#' @param fit fitted \code{\link[pcoxtime]{pcoxtime}}.
#' @param newdata optional data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula.
#' @param stats logical. If \code{TRUE} all the related concordance statistics are returned.
#' @param reverse if TRUE (default) then assume that larger x values predict smaller response values y; a proportional hazards model is the common example of this.
#' @param ... additional arguments passed to \code{\link[survival]{concordance}}.
#'
#' @return an object containing the concordance, followed by the number of pairs that agree, disagree, are tied, and are not comparable.
#'
#' @examples
#'
#' if (packageVersion("survival")>="3.2.9") {
#'    data(cancer, package="survival")
#' } else {
#'    data(veteran, package="survival")
#' }
#' # Penalized
#' lam <- 0.1
#' alp <- 0.5
#' pfit1 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' c1 <- concordScore(pfit1)
#' c1
#'
#' # Unpenalized
#' lam <- 0
#' alp <- 1
#' pfit2 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' c2 <- concordScore(pfit2)
#' c2
#'
#' @export

concordScore.pcoxtime <- function(fit, newdata = NULL, stats = FALSE, reverse = TRUE, ...){
	if (is.null(newdata)) {
		risk <- predict(fit, type = "risk")
		y <- model.extract(model.frame(fit), "response")
	} else {
		risk <- predict(fit, newdata = newdata, type = "risk")
		y <- model.extract(model.frame(fit$terms, data = newdata), "response")
	}

	conindex <- survival::concordance(y ~ risk, reverse = reverse, ...)
	if (!stats){
		conindex <- conindex$concordance
	}
	return(conindex)
}

#' Extract optimal parameter values
#'
#' Extract cross-validation summaries and data frames.
#'
#' @aliases extractoptimal
#'
#' @details
#' Extract cross-validation summaries based on the optimal parameters or data frames containing all the summaries for all the parameter values.
#'
#' @param object \code{\link[pcoxtime]{pcoxtimecv}} object
#' @param what the summary or data frame to extract. Currently, three options are available: \code{what = "optimal"} extracts a data frame showing optimal parameter values, \code{what = "cvm"} extracts the data frame containing the mean cross-validation error for various lambda-alpha combination, and \code{what = "coef"}, requires \code{refit = TRUE} in \code{\link[pcoxtime]{pcoxtimecv}},  extracts a data frame containing the coefficient estimates for various lambda-alpha combination.
#' @param ... for future implementations
#'
#' @return A data frame depending on the specification described above.
#'
#' @export

extractoptimal.pcoxtimecv <- function(object, what=c("optimal", "cvm", "coefs"), ...) {
	what <- match.arg(what)
	if (what=="optimal") {
		out <- object$dfs$min_metrics_df
	} else if (what=="cvm") {
		out <- object$dfs$cvm
	} else {
		out <- object$fit$beta
		if (is.null(out)) warning("Run the model with refit=TRUE to extract cross-validation coefficients.")
	}
	return(out)
}


#' Permutation variable importance
#'
#' Computes the relative importance based on random permutation of focal variable for pcoxtime model.
#'
#' @details
#' Given predictors \code{x_1, x_2, ..., x_n} used to predict the survival outcome, \code{y}. Suppose, for example, \code{x_1} has low predictive power for the response. Then, if we randomly permute the observed values for \code{x_1}, then the prediction for \code{y} will not change much. Conversely, if any of the predictors highly predicts the response, the permutation of that specific predictor will lead to a considerable change in the predictive measure of the model. In this case, we conclude that this predictor is important. In our implementation, Harrel's concordance index is used to measure the prediction accuracy.
#'
#' @param object fitted \code{\link[pcoxtime]{pcoxtime}}.
#' @param newdata data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula.
#' @param nrep number of replicates for permutations. Default is \code{nrep = 50}.
#' @param parallelize whether to run in parallel. Default is \code{FALSE}.
#' @param nclusters number of cores to use if \code{parallelize = TRUE}.
#' @param estimate character string specify which summary statistic to use for the estimates. Default is \code{"mean"}.
#' @param probs numeric vector of probabilities with values in \code{[0,1]}.
#' @param seed a single value for for random number generation.
#' @param ... for future implementation.
#'
#' @return a named vector of variable scores (\code{estimate = "mean"}) or a data frame (\code{estimate = "quantile"}).
#'
#' @keywords internal

pvimp.pcoxtime <- function(object, newdata, nrep=50
	, parallelize=FALSE, nclusters=1, estimate=c("mean", "quantile")
	, probs=c(0.025, 0.5, 0.975), seed=NULL, ...) {
	if (is.null(seed) || !is.numeric(seed)) {
		seed <- 911
		set.seed(seed)
	}

	estimate <- match.arg(estimate)
	# Overall score
	overall_c <- concordScore.pcoxtime(object, newdata=newdata, stats=FALSE, reverse=TRUE, ...)
	xvars <- all.vars(formula(delete.response(terms(object))))
	N <- NROW(newdata)
	if (parallelize) {
		## Setup parallel because serial takes a lot of time. Otherwise you can turn it off
		nn <- min(parallel::detectCores(), nclusters)
		if (nn < 2){
			foreach::registerDoSEQ()
		} else{
			cl <-  parallel::makeCluster(nn)
			doParallel::registerDoParallel(cl)
			on.exit(parallel::stopCluster(cl))
		}
		x <- NULL
		vi <- foreach(x = xvars, .export="concordScore.pcoxtime") %dopar% {
			permute_df <- newdata[rep(seq(N), nrep), ]
			if (is.factor(permute_df[,x])) {
				permute_var <- as.vector(replicate(nrep, sample(newdata[,x], N, replace = FALSE)))
				permute_var <- factor(permute_var, levels = levels(permute_df[,x]))
			} else {
				permute_var <- as.vector(replicate(nrep, sample(newdata[,x], N, replace = FALSE)))
			}
			index <- rep(1:nrep, each = N)
			permute_df[, x] <- permute_var
			perm_c <- unlist(lapply(split(permute_df, index), function(d){
				concordScore.pcoxtime(object, newdata = d, stats = FALSE, reverse=TRUE, ...)
			}))
			est <- (overall_c - perm_c)/overall_c
			out <- switch(estimate
				, mean={
					out2 <- mean(est)
					names(out2) <- x
					out2
				}
				, quantile={
					out2 <- cbind.data.frame(...xx=x, t(quantile(est, probs = probs, na.rm = TRUE)))
					colnames(out2) <- c("terms", "lower", "estimate", "upper")
					out2
				}
			)
			out
		}
	} else {
		vi <- sapply(xvars, function(x){
			permute_df <- newdata[rep(seq(N), nrep), ]
			if (is.factor(permute_df[,x])) {
				permute_var <- as.vector(replicate(nrep, sample(newdata[,x], N, replace = FALSE)))
				permute_var <- factor(permute_var, levels = levels(permute_df[,x]))
			} else {
				permute_var <- as.vector(replicate(nrep, sample(newdata[,x], N, replace = FALSE)))
			}
			index <- rep(1:nrep, each = N)
			permute_df[, x] <- permute_var
			perm_c <- unlist(lapply(split(permute_df, index), function(d){
				concordScore.pcoxtime(object, newdata = d, stats = FALSE, reverse=TRUE, ...)
			}))
			est <- (overall_c - perm_c)/overall_c
			out <- switch(estimate
				, mean={
					out2 <- mean(est)
					out2
				}
				, quantile={
					out2 <- cbind.data.frame(...xx=x, t(quantile(est, probs = probs, na.rm = TRUE)))
					colnames(out2) <- c("terms", "lower", "estimate", "upper")
					out2
				}
			)
			out
		}, simplify = FALSE)
	}
	out <- switch(estimate
		, mean={
			unlist(vi)
		}
		, quantile={
			est <- do.call("rbind", vi)
			rownames(est) <- NULL
			est
		}
	)
	return(out)
}


#' Coefficient variable importance 
#'
#' @details
#' Absolute value of the coefficients (parameters) corresponding the tuned pcoxtime object.
#'
#' @param object fitted \code{\link[pcoxtime]{pcoxtime}}.
#' @param relative logical. If \code{TRUE} the scores are divided by the absolute sum of the coefficients.
#' @param ... for future implementation.
#'
#' @return a named vector of variable scores (\code{estimate = "mean"}) or a data frame (\code{estimate = "quantile"}).
#'
#' @keywords internal

coefvimp.pcoxtime <- function(object, relative=TRUE, ...) {
	out <- data.frame(Overall=coef(object))
	out$sign <- sign(out$Overall)
	out$Overall <- abs(out$Overall)
	if (relative){
		out$Overall <- out$Overall/sum(out$Overall, na.rm = TRUE)
	}
	out$terms <- rownames(out)
	rownames(out) <- NULL
	out <- out[, c("terms", "Overall", "sign")]
	return(out)
}

#' Compute variable or coefficient importance score
#'
#' @aliases varimp
#'
#' @details
#' Absolute value of the coefficients (parameters) corresponding the \code{\link[pcoxtime]{pcoxtime}} object (\code{type = "coef"}). Otherwise, variable level importance is computed using permutation (\code{type = "perm"}).
#' In the case of permutation: given predictors \code{x_1, x_2, ..., x_n} used to predict the survival outcome, \code{y}. Suppose, for example, \code{x_1} has low predictive power for the response. Then, if we randomly permute the observed values for \code{x_1}, then the prediction for \code{y} will not change much. Conversely, if any of the predictors highly predicts the response, the permutation of that specific predictor will lead to a considerable change in the predictive measure of the model. In this case, we conclude that this predictor is important. In our implementation, Harrel's concordance index is used to measure the prediction accuracy.
#'
#' @param object fitted \code{\link[pcoxtime]{pcoxtime}}.
#' @param newdata data frame containing the variables appearing on the right hand side of \code{\link[pcoxtime]{pcoxtime}} formula.
#' @param type if \code{type = "coef"} or \code{type = "model"} absolute value of estimated coefficients is computed. If \code{type = "perm"} variable level importance is computed using permutation.
#' @param relative logical. If \code{TRUE} the scores are divided by the absolute sum of the coefficients.
#' @param nrep number of replicates for permutations. Default is \code{nrep = 50}.
#' @param parallelize whether to run in parallel. Default is \code{FALSE}.
#' @param nclusters number of cores to use if \code{parallelize = TRUE}.
#' @param estimate character string specify which summary statistic to use for the estimates. Default is \code{"mean"}.
#' @param probs numeric vector of probabilities with values in \code{[0,1]}.
#' @param seed a single value for for random number generation.
#' @param ... for future implementation.
#'
#' @return a named vector of variable scores (\code{estimate = "mean"}) or a data frame (\code{estimate = "quantile"}).
#'
#' @examples
#'
#' if (packageVersion("survival")>="3.2.9") {
#'    data(cancer, package="survival")
#' } else {
#'    data(veteran, package="survival")
#' }
#' # Penalized
#' lam <- 0.1
#' alp <- 0.5
#' pfit1 <- pcoxtime(Surv(time, status) ~ factor(trt) + karno + diagtime + age + prior
#'		, data = veteran
#'		, lambda = lam
#'		, alpha = alp
#'	)
#' imp1 <- varimp(pfit1, veteran)
#' plot(imp1)
#' @export

varimp.pcoxtime <- function(object, newdata, type=c("coef", "perm", "model")
	, relative=TRUE, nrep=50, parallelize=FALSE, nclusters=1
	, estimate=c("mean", "quantile"), probs=c(0.025, 0.5, 0.975), seed=NULL, ...) {
	type <- match.arg(type)
	estimate <- match.arg(estimate)
	if (type=="model") {
		type <- "coef"
	}
	if (type=="coef") {
		out <- coefvimp.pcoxtime(object, relative=relative)
	} else if (type=="perm") {
		out <- pvimp.pcoxtime(object=object, newdata=newdata, nrep=nrep
			, parallelize=parallelize, nclusters=nclusters, estimate=estimate
			, probs=probs
		)
		if (estimate=="mean") {
			out <- data.frame(Overall=out)
			out$sign <- sign(out$Overall)
			out$Overall <- abs(out$Overall)
			if (relative) {
				out$Overall <- out$Overall/sum(out$Overall, na.rm = TRUE)
			}
			out$terms <- rownames(out)
			rownames(out) <- NULL
			out <- out[, c("terms", "Overall", "sign")]
		}
	}
	if (type=="coef") estimate <- "mean"
	attr(out, "estimate") <- estimate
	class(out) <- c("varimp", class(out)) 
	return(out)
}
