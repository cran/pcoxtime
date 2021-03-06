# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

nloglik <- function(Y, X, beta0, lambda, alpha) {
    .Call(`_pcoxtime_nloglik`, Y, X, beta0, lambda, alpha)
}

gradient <- function(X, beta0, res_est, lambda, alpha) {
    .Call(`_pcoxtime_gradient`, X, beta0, res_est, lambda, alpha)
}

proxupdate <- function(beta0, grad, gamma, lambda, alpha) {
    .Call(`_pcoxtime_proxupdate`, beta0, grad, gamma, lambda, alpha)
}

bbstep <- function(beta, beta_prev, grad, grad_prev) {
    .Call(`_pcoxtime_bbstep`, beta, beta_prev, grad, grad_prev)
}

proxiterate <- function(Y, X, beta0, lambda, alpha, p, maxiter, tol, xnames, lambmax = FALSE) {
    .Call(`_pcoxtime_proxiterate`, Y, X, beta0, lambda, alpha, p, maxiter, tol, xnames, lambmax)
}

pcoxKKTcheck <- function(grad, beta0, lambda, alpha) {
    .Call(`_pcoxtime_pcoxKKTcheck`, grad, beta0, lambda, alpha)
}

lambdaiterate <- function(Y, X, beta0, lambdas, alpha, p, maxiter, tol, xnames, lambmax = FALSE) {
    .Call(`_pcoxtime_lambdaiterate`, Y, X, beta0, lambdas, alpha, p, maxiter, tol, xnames, lambmax)
}

