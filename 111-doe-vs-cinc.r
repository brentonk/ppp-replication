################################################################################
###
### Compare DOE scores with capability ratios
###
################################################################################

library("MASS")
library("caret")
library("dplyr")
library("foreach")
library("ggplot2")
library("ggtern")
library("RColorBrewer")
library("tidyr")
library("tikzDevice")

Sys.unsetenv("TEXINPUTS")

load("results/data-nmc.rda")
load("results/imputations-train.rda")
load("results/trained-weights.rda")

pred_dir_dyad <- read.csv("results/predict-dir-dyad.csv")
pred_dyad <- read.csv("results/predict-dyad.csv")


###-----------------------------------------------------------------------------
### Basic correlations
###-----------------------------------------------------------------------------

## Calculate capability ratios for all dyads
make_capratio <- function(pred) {
    pred %>%
        left_join(data_NMC %>% select(ccode, year, cinc_a = cinc),
                  by = c(ccode_a = "ccode", year = "year")) %>%
        left_join(data_NMC %>% select(ccode, year, cinc_b = cinc),
                  by = c(ccode_b = "ccode", year = "year")) %>%
        mutate(capratio = exp(cinc_a) / (exp(cinc_a) + exp(cinc_b)))
}

pred_dir_dyad <- make_capratio(pred_dir_dyad)
pred_dyad <- make_capratio(pred_dyad)

## Calculate correlations
with(pred_dir_dyad, cor(VictoryA, capratio, use = "complete"))
with(pred_dir_dyad, cor(VictoryB, capratio, use = "complete"))
with(pred_dyad, cor(VictoryA, capratio, use = "complete"))
with(pred_dyad, cor(VictoryB, capratio, use = "complete"))

## Calculate canonical correlations
with(pred_dir_dyad[!is.na(pred_dir_dyad$capratio), ],
     cancor(cbind(VictoryA, VictoryB), capratio))
with(pred_dyad[!is.na(pred_dyad$capratio), ],
     cancor(cbind(VictoryA, VictoryB), capratio))


###-----------------------------------------------------------------------------
### Out-of-fold predicted probabilities
###-----------------------------------------------------------------------------

dat <- imputations_train[[1]]

## Calculate out-of-fold predictions for the capability ratio model
set.seed(15)
capratio_folds <- createFolds(y = dat$Outcome,
                              k = 10,
                              list = TRUE,
                              returnTrain = TRUE)
pp_capratio <- foreach (fold = capratio_folds, .combine = "rbind") %do% {
    ## Fit the capability ratio model
    polr_capratio <- polr(Outcome ~ capratio,
                          data = dat[fold, , drop = FALSE])

    ## Calculate out-of-fold predictions
    pred <- predict(polr_capratio,
                    newdata = dat[-fold, , drop = FALSE],
                    type = "prob")

    ## Convert to data frame and include observed outcome
    pred <- data.frame(pred)
    pred$method <- "capratio"
    pred$Outcome <- dat$Outcome[-fold]

    pred
}

## Calculate out-of-fold predictions from the Super Learner
##
## This uses the tuning parameters that were trained by CV on the full sample,
## but the candidate model predictions being averaged are purely out-of-fold
pp_doe <- foreach (imp_weights = trained_weights) %do% {
    ## Extract the optimal weights for this imputation
    w <- imp_weights$weights$par
    w <- c(w, 1 - sum(w))

    ## Calculate weighted averages of predicted probabilities
    ##
    ## Uses the `all_probs` object, a list containing one data frame of
    ## out-of-fold predictions per model, each in the same order as the original
    ## data
    weighted_preds <- foreach (pred = imp_weights$all_probs) %do% {
        pred <- select(pred, -id)
        pred <- data.matrix(pred)
        pred
    }
    weighted_preds <- Map("*", weighted_preds, w)
    weighted_preds <- Reduce("+", weighted_preds)

    ## Sanity check
    stopifnot(all.equal(rowSums(weighted_preds),
                        rep(1, nrow(weighted_preds)),
                        check.attributes = FALSE))

    weighted_preds
}

## Average across imputations and validate
pp_doe <- Reduce("+", pp_doe)
pp_doe <- pp_doe / length(trained_weights)
stopifnot(all.equal(range(rowSums(pp_doe)), c(1, 1)))

## Convert to data frame
pp_doe <- pp_doe %>%
    data.frame() %>%
    mutate(method = "doe")
pp_doe$Outcome <- dat$Outcome

## Make data to pass to ggplot
pp_data <- rbind(pp_capratio, pp_doe) %>%
    mutate(Outcome = factor(
               Outcome,
               levels = c("VictoryA", "Stalemate", "VictoryB"),
               labels = c("Outcome: A Wins", "Outcome: Stalemate", "Outcome: B Wins")
           ),
           method = factor(
               method,
               levels = c("capratio", "doe"),
               labels = c("Ordered Logit on Capability Ratio",
                          "Super Learner")
           ))
pp_data <- rbind(
    pp_data[pp_data$Outcome == "Stalemate", ],
    pp_data[pp_data$Outcome != "Stalemate", ]
)

tikz(file = "results/latex/fig-oof-pred.tex",
     width = 5.25,
     height = 6.75)
ggtern(pp_data,
       aes(x = VictoryA,
           y = Stalemate,
           z = VictoryB)) +
    geom_point(alpha = 0.3) +
    labs(T = "$\\emptyset$",
         L = "$A$",
         R = "$B$") +
    facet_grid(Outcome ~ method) +
    theme_gray(base_size = 10) +
    theme(tern.axis.ticks = element_blank(),
          tern.axis.text = element_text(size = rel(0.8)),
          tern.axis.title = element_text(size = rel(1)))
dev.off()
