args <- commandArgs(trailingOnly = TRUE)

option <- function(name) {
  value <- match(name, args)
  if (is.na(value) || value == length(args)) {
    stop(sprintf("Missing value for %s", name))
  }
  args[value + 1]
}

input <- option("--input")
expected.xdim <- as.integer(option("--xdim"))
expected.ydim <- as.integer(option("--ydim"))
expected.features <- strsplit(option("--features"), " ", fixed = TRUE)[[1]]

environment <- new.env(parent = emptyenv())
load(input, envir = environment)
if (!exists("train.som", envir = environment, inherits = FALSE)) {
  stop("Construct SOM unit test failed: train.som is missing from output")
}

train.som <- environment$train.som
if (train.som$grid$xdim != expected.xdim || train.som$grid$ydim != expected.ydim) {
  stop(
    sprintf(
      "Construct SOM unit test failed: grid is %dx%d, expected %dx%d",
      train.som$grid$xdim,
      train.som$grid$ydim,
      expected.xdim,
      expected.ydim
    )
  )
}

codes <- train.som$codes[[1]]
if (nrow(codes) != expected.xdim * expected.ydim) {
  stop("Construct SOM unit test failed: code count does not match grid size")
}
if (!setequal(colnames(codes), expected.features)) {
  stop("Construct SOM unit test failed: code features do not match SOMFEATURES")
}

cat("Construct SOM unit test passed.\n")
