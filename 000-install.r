################################################################################
### Install packages necessary to replicate "Predictions, Proxies, and Power" by
### Robert J. Carroll and Brenton Kenkel
################################################################################

.USING_DOCKER <- TRUE

if (.USING_DOCKER) {
    msg <- "\nThe scripts in this repository should be run via the included Docker image specification.  This ensures that the version of R and all packages are identical across computing environments.\n\nIf you do not have access to Docker (or Singularity, for which we have also included an image specification) and wish to run the replication using the most recent available packages, set `.USING_DOCKER <- FALSE` at the top of this script, `000-install.r`, and rerun this script to install the most recent versions of the packages used.  Because of changes in the package code, the results may vary from the published ones if you do this.  For exact replication, you must use the included Docker container or its Singularity equivalent.\n\n"
    msg <- strwrap(msg)
    dashes <- paste(rep("-", max(nchar(msg))), collapse = "")
    msg <- c("", dashes, "Replication of 'Predictions, Proxies, and Power'", dashes, "", msg, "")
    writeLines(msg)
} else {
    if (getRversion() < '3.2.0')
        stop("R version 3.2.0 or greater is required.")

    if (!require("packrat"))
        install.packages("packrat")

    ppp_packages <- packrat:::appDependencies(".")
    install.packages(ppp_packages, dependencies = TRUE)
}

## Create subdirectories to store output
make_dir <- function(x) {
    go <- !dir.exists(x)
    if (go)
        dir.create(x, recursive = TRUE)
    invisible(go)
}

make_dir("results")
make_dir("results/latex")
make_dir("results/logs-models")
make_dir("results/logs-predict")
make_dir("results/logs-replications")
make_dir("results/logs-varimp")
make_dir("results/logs-weights")
make_dir("results/predict")
make_dir("results/replications")
make_dir("results/varimp")
make_dir("results/weights")
