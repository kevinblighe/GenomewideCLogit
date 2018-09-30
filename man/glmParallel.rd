\name{glmParallel}

\alias{glmParallel}

\title{Standard regression functions in R enabled for parallel processing over large data-frames - generalised linear model}

\description{This is a non-user function that is managed by RegParallel, the primary function.}

\usage{
glmParallel(
  data,
  formula.list,
  FUN,
  variables,
  terms,
  startIndex,
  blocksize,
  blocks,
  system,
  cl,
  nestedParallel,
  conflevel,
  excludeTerms,
  excludeIntercept)
}

\arguments{
  \item{data}{A data-frame that contains all model terms to be tested.
  Variables that have all zeros will, automatically, be removed. REQUIRED.}
  \item{formula.list}{A list containing formulae that can be coerced to
  formula class via as.formula(). REQUIRED.}
  \item{FUN}{Regression function. Must be of form, for example:
  function(formula, data) glm(formula = formula, family=binomial, data = data).
  REQUIRED.}
  \item{variables}{Vector of variable names in data to be tested
  independently. Each variable will have its own formula in formula.list.
  REQUIRED.}
  \item{terms}{Vector of terms used in the formulae in formula.list, excluding
  the primary variable of interest. REQUIRED.}
  \item{startIndex}{Starting column index in data object from which
  processing can commence. REQUIRED.}
  \item{blocksize}{Number of variables to test in each foreach loop.
  REQUIRED.}
  \item{blocks}{Total number of blocks required to complete analysis.
  REQUIRED.}
  \item{system}{The identified system on which the user is operating.
  REQUIRED.}
  \item{cl}{On Windows systems, the cluster object created by
  makeCluster() that enables parallelisation. On other systems, will be
  assigned NULL. REQUIRED.}
  \item{nestedParallel}{In RegParallel, parallelisation initially occurs at
  the block level, ie., multiple blocks of models are processed in parallel.
  If nestedParallel is enabled, a second level of parallelisation occurs
  within each block in addition. Warning! - this doubles the usage of cores.
  REQUIRED.}
  \item{conflevel}{Confidence level for calculating odds or hazard ratios.
  REQUIRED.}
  \item{excludeTerms}{Remove these terms from the final output. These will
  simply be grepped out. REQUIRED.}
  \item{excludeIntercept}{Remove intercept terms from the final output.
  REQUIRED.}
}

\details{
This is a non-user function that is managed by RegParallel, the
primary function.
}

\value{
A \code{\link{data.table}} object.
}

\author{
Kevin Blighe <kevin@clinicalbioinformatics.co.uk>
}

\examples{

  options(scipen=10)
  options(digits=6)

  col <- 20000
  row <- 20
  mat <- matrix(
    rexp(col*row, rate = .1),
    ncol = col)
  colnames(mat) <- paste0('gene', 1:ncol(mat))
  rownames(mat) <- paste0('sample', 1:nrow(mat))

  modelling <- data.frame(
    cell = rep(c('B', 'T'), nrow(mat) / 2),
    group = c(rep(c('treatment'), nrow(mat) / 2), rep(c('control'), nrow(mat) / 2)),
    dosage = t(data.frame(matrix(rexp(row, rate = 1), ncol = row))),
    mat,
    row.names = rownames(mat))

  data <- modelling[,1:2000]
  variables <- colnames(data)[4:ncol(data)]
  res1 <- RegParallel(
    data = data,
    formula = 'factor(group) ~ [*] + (cell:dosage) ^ 2',
    FUN = function(formula, data)
      glm(formula = formula,
        data = data,
        family = binomial(link = 'logit'),
        method = 'glm.fit'),
    FUNtype = 'glm',
    variables = variables,
    blocksize = 700,
    cores = 2,
    nestedParallel = TRUE,
    conflevel = 99,
    excludeTerms = NULL,
    excludeIntercept = TRUE
  )

  # spot checks
  m <- glm(factor(group) ~ gene265 + (cell:dosage) ^ 2, data=data, family=binomial)
  summary(m)$coefficients
  exp(cbind("Odds ratio" = coef(m), confint.default(m, level = 0.99)))
  res1[which(res1$Variable == 'gene265'),]

  m <- glm(factor(group) ~ gene1688 + (cell:dosage) ^ 2, data=data, family=binomial)
  summary(m)$coefficients
  exp(cbind("Odds ratio" = coef(m), confint.default(m, level = 0.99)))
  res1[which(res1$Variable == 'gene1688'),]


  ###


  data <- modelling[,1:500]
  variables <- colnames(data)[4:ncol(data)]
  res2 <- RegParallel(
    data = data,
    formula = '[*] ~ cell:dosage',
    FUN = function(formula, data)
      glm(formula = formula,
        data = data,
        family = gaussian,
        method = 'glm.fit'),
    FUNtype = 'glm',
    variables = variables,
    blocksize = 496,
    cores = 2,
    nestedParallel = TRUE,
    conflevel = 90,
    excludeTerms = NULL,
    excludeIntercept = FALSE
  )

  # spot checks
  m <- glm(gene29 ~ cell:dosage, data=data, family=gaussian)
  summary(m)$coefficients
  exp(cbind("Odds ratio" = coef(m), confint.default(m, level = 0.90)))
  res2[which(res2$Variable == 'gene29'),]
}
