################################################################################
###
### Collect the results of the variable importance re-runs into a single list
###
### Essentially an adapted version of the same code in 16-collect-weights.r,
### since both times we're dealing with trained weights objects
###
################################################################################

## Retrieve relevant filenames
varimp_files <- list.files(path = "results/varimp",
                           pattern = "\\.rda$",
                           full.names = TRUE)

## Sanity check
stopifnot(length(varimp_files) == 180)

## Retrieve and store each set of results
##
## Can't load all at once due to name collisions
results_varimp <- vector("list", length(varimp_files))
for (i in seq_along(varimp_files)) {
    loaded_objects <- load(varimp_files[i])

    if (length(loaded_objects) != 1)
        stop("Loaded data file should contain exactly one object")
    results_varimp[[i]] <- get(loaded_objects)
}

save(results_varimp, file = "results/varimp.rda")
