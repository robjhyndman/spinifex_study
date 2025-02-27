#### This is an old variant. See _sim_user_study.r for the latest simulations.
#' @example
#' file.edit("./apps_supplementary/data_simulation/_sim_user_study.r")
####

#' Creates a data frame containing clusters of multivariate data 
#'
#' @param means List, each element is a p-length vectors, the variable means 
#' of this cluster.
#' @param sigmas List, each element is a square (p, p) matrix, the 
#' variance-covariance matrix for this cluster. If any matrix is not 
#' positive definite, it will be coerced with `lqmm::make.positive.definite()`
#' @param cl_obs List, of number of observations within each cluster.
#' @param method String specifying the matrix decomposition used find the 
#' matrix root of `sigmas`. Expects, "eigen", the default, "svd", or "chol". 
#' Also see `?mvtnorm::rmvnorm()`.
#' @param do_shuffle Boolean specifying if order resampling should be applied 
#' to the rows and columns, Such that cluster rows are not all together and 
#' signal columns are not in the same order.
#' @examples
#' mns <- list(c(8, 2, rep(0, 3)), rep(0, 5))
#' covs <- list(diag(5), diag(5))
#' sim_pDim_kCl(means = mns, sigmas = covs)
#' 
#' sim_pDim_kCl(means = mns, sigmas = covs, cl_obs = list(200, 50),
#'              method = "svd", do_shuffle = FALSE)
#'              
#' x <- sim_pDim_kCl(means = mns, sigmas = covs)
#' clas <- attr(x, "class")
#' GGally::ggpairs(x, ggplot2::aes(color = clas))
#' 
#' ## making a non-trivial cov.
#' mns <- list(runif(5, 1, 5), rep(0, 5))
#' p <- length(mns[[1]])
#' A <- matrix(runif(p^2) * 2 - 1, ncol = p) 
#' cov1 <- t(A) %*% A
#' A2 <- matrix(runif(p^2) * 2 - 1, ncol = p) 
#' cov2 <- t(A) %*% A
#' covs <- list(cov1, cov2)
#' 
#' sim_pDim_kCl(means = mns, sigmas = covs)
sim_pDim_kCl <- function(means, 
                         sigmas,
                         cl_obs = rep(list(100), length(means)),
                         method = c("eigen", "svd", "chol"),
                         do_shuffle = TRUE
){
  if(length(cl_obs) == 1 & is.numeric(cl_obs) == TRUE)
    cl_obs <- rep(list(cl_obs), length(means))
  means  <- as.list(means)
  sigmas <- as.list(sigmas)
  cl_obs <- as.list(cl_obs)
  method <- match.arg(method)
  ## Initalize
  p <- length(means[[1]])
  k <- length(means)
  ## Means and covariances are both of length k, clusters
  stopifnot(all(k == c(length(means), length(sigmas)))) 
  ## Elements of means and elements covariances have length, rows/cols p, number of numeric variables.
  stopifnot(all(p == c(length(means[[1]]), nrow(sigmas[[1]]), ncol(sigmas[[1]]))))
  require("mvtnorm")
  require("lqmm")
  
  ## Simulate with checks
  df_sim <- NULL
  for(i in 1:k){
    cov <- as.matrix(sigmas[[i]])
    ## Check if this sigma is positive semi-definite, and a symmetric matrix .
    if(lqmm::is.positive.definite(cov) == FALSE){
      warning(paste0("sigmas[[", i, "]] wasn't a positive definite matrix. Applied lqmm::make.positive.definite()."))
      cov <- lqmm::make.positive.definite(cov)
    }
    if(base::isSymmetric.matrix(cov) == FALSE)
      stop(paste0("sigma[[", i, "]] is not a symetric matrix, all covariance metrices must be symetric and positive definate."))
    
    ## Sample
    this_cl <- mvtnorm::rmvnorm(n = cl_obs[[i]], 
                                mean = means[[i]], 
                                sigma = cov, 
                                method = method)
    df_sim <- rbind(df_sim, this_cl)
  }
  df_sim <- as.data.frame(df_sim)
  
  ## Init class
  class <- factor(paste0("cl ", rep(letters[1:k], unlist(cl_obs))))
  ## Reorder rows and columns if needed
  if(do_shuffle == TRUE){
    row_ord <- sample(1:nrow(df_sim))
    col_ord <- sample(1:p)
    ## Apply the shuffle reordering
    df_sim <- df_sim[row_ord, col_ord]
    class  <- class[row_ord]
  }
  
  ## Row/col names, after shuffle if required
  rownames(df_sim) <- 1:nrow(df_sim)
  colnames(df_sim) <- paste0("V", 1:ncol(df_sim))
  
  ## Capture attibutes
  args <- list(means = means, sigmas = sigmas, cl_obs = cl_obs,
               method = method, do_shuffle = do_shuffle)
  cl <- call("sim_pDim_kCl", args)
  ## Record attributes
  attr(df_sim, "cluster") <- class ## Cluster levels
  attr(df_sim, "args")    <- args  ## List of args
  attr(df_sim, "call")    <- cl    ## Stored call, use eval(attr(sim, "call")) to reproduce

  return(df_sim)
}


# ### Saving off simulations for the PoC app.
# mns <- list(c(4, 6, sample(1:3, size = 3)),
#             c(5, 4, sample(1:3, size = 3)))
# .p <- length(mns[[1]])
# covar <- diag(.p) 
# uppertri_ind <- upper.tri(covar)
# covar[uppertri_ind] <- sample(seq(-.2, .2, by = .1), sum(uppertri_ind), replace = T)
# covar[uppertri_ind] <- t(covar)[uppertri_ind]
# lqmm::make.positive.definite(covar)
# 
# covs <- list(covar, 
#              covar)
# mySim <- sim_pDim_kCl(means = mns, sigmas = covs)
# 
# ex3 <- mySim
# save(ex3, file = "../PoC_WebGL_shiny/_NicholasSpyrison_rgl/data/ex3_5var2Cl_noise.r")



#' Creates a data frame containing clusters of non-linear function segments. 
#'
#' @param p The number of dimensions to simulate 
#' @param cl_obs List, of number of observations within each cluster.
#' from this cluster.
#' @param do_shuffle Boolean specifying if order resampling should be applied 
#' to the rows and columns, Such that cluster rows are not all together and 
#' signal columns are not in the same order.
#' @examples )
#' sim_func_seg(p = 5)
#' 
#' sim_func_seg(p = 10, cl_obs = list(200, 50, 100),
#'              do_shuffle = FALSE)
#' 
#' x <-  sim_func_seg(p = 4)
#' clas <- attr(x, "class")
#' GGally::ggpairs(x, ggplot2::aes(color = clas))
sim_func_seg <- function(p,
                         cl_obs = rep(list(100), 2),
                         do_shuffle = TRUE
) {
  cl_obs <- as.list(cl_obs)
  require(magrittr)

  k <- length(cl_obs)
  ls_funcs <- list(function(x) x^2,
                   function(x) exp(x),
                   function(x) abs(x),
                   function(x) 1 / x,
                   function(x) sign(x) * log(abs(x)),
                   function(x) sign(x) * sqrt(abs(x))
  )
  
  ## Init for loops
  df_sim   <- NULL
  cl_means <- list()
  cl_sigmas <- list()
  last_rot <- matrix(rep(0, p^2), nrow = p, ncol = p)
  ## For each cluster
  for (i in 1:k){
    cl_n <- cl_obs[[i]]
    x <- seq(-5, 5, length.out = cl_n)
    this_cl <- data.frame(V1 = x + rnorm(cl_n, sd = 1))
    ## make V2:Vp
    for (j in 2:p){
      this_func <- ls_funcs[[sample(1:length(ls_funcs), size = 1)]]
      var <- .8 + rgamma(10, shape = .7)
      dim <- this_func(x) + rnorm(cl_n, sd = sqrt(var))
      dim[is.nan(dim)] <- 0
      dim[is.na(dim)] <- 0
      if(any(is.nan(dim))) browser()
      if(any(is.na(dim))) browser()
      
      this_cl <- cbind(this_cl, dim)
    }
    # ## Rotative if not the first cluster, each dim rotated between 45 and 135 degrees
    # if (i > 1){
    #   angs <- runif(n = p, min = .33 * pi, max = .66 * pi)
    #   init_rot <- diag(p)
    #   diag(init_rot) <- angs
    #   this_rot <- last_rot + init_rot
    #   this_cl <- (as.matrix(this_cl) %*% this_rot) %>% as.data.frame()
    #   last_rot <- this_rot
    # }
    colnames(this_cl) <- NULL
    ## Rescale within cluster, after rotation
    this_cl <- tourr::rescale(this_cl)
    
    cl_means[[i]]  <- as.vector(colMeans(this_cl))
    cl_sigmas[[i]] <- cov(this_cl)
    ## add to sim
    df_sim <- rbind(df_sim, this_cl)
  }
  df_sim <- df_sim %>% as.data.frame()
  
  ## Capture input args for attributed before anything could be reshuffled.
  input_args <- list(p = p, cl_obs = cl_obs,
                     do_shuffle = do_shuffle, sim_func = sim_func_seg)
  class <- paste0("cl ", rep(letters[1:k], unlist(cl_obs)))

  ## Reorder rows and columns if needed
  if(do_shuffle == TRUE) {
    row_ord <- sample(1:nrow(df_sim))
    col_ord <- sample(1:p)
    ## Apply the shuffle reordering
    df_sim <- df_sim[row_ord, col_ord]
    class <- class[row_ord]
    for (i in 1:k){
      cl_means[[i]]  <- cl_means[[i]][col_ord]
      cl_sigmas[[i]] <- cl_sigmas[[i]][col_ord, col_ord]
    }
  }
  
  ## Row/col names, after shuffle if required
  rownames(df_sim) <- 1:nrow(df_sim)
  colnames(df_sim) <- paste0("V", 1:ncol(df_sim))
  
  ## Record attributes
  attr(df_sim, "class")     <- class     ## Cluster levels
  attr(df_sim, "input_args") <- input_args ## List of parameters
  attr(df_sim, "cl_means")   <- cl_means   ## List of the simulations means, after shuffle applied if needed
  attr(df_sim, "cl_sigmas")  <- cl_sigmas  ## List of the simulations covariance matrices, after shuffle applied if needed
  
  return(df_sim)
}

