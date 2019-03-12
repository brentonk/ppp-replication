################################################################################
###
### Replication of Arena and Palmer 2009, "Politics or the Economy?", replacing
### CINC ratios with DOE scores
###
### Replicating Table 3
###
################################################################################

library("car")
library("caret")
library("dplyr")
library("foreach")
library("foreign")
library("Formula")
library("glmx")

raw_arena_palmer_2009 <- read.csv("data-arena-palmer-2009.csv")
doe_dir_dyad <- read.csv("results/predict-dir-dyad.csv")

## Merge in DOE scores
data_arena_palmer_2009 <- left_join(raw_arena_palmer_2009,
                                    doe_dir_dyad,
                                    by = c(ccode1 = "ccode_a",
                                           ccode2 = "ccode_b",
                                           year = "year"))
stopifnot(with(data_arena_palmer_2009, !any(is.na(VictoryA))))

## Analogue of glm_and_cv() for hetglm() models
hetglm_and_cv <- function(form,
                          data,
                          hyp_main,
                          hyp_power,
                          number = 10,
                          repeats = 10)
{
    ## Fit the original model
    fit <- hetglm(formula = form,
                  data = data)

    ## Extract individual log-likelihoods
    pred_probs <- predict(fit, type = "response")
    pred_probs <- ifelse(fit$y == 1, pred_probs, 1 - pred_probs)
    log_lik <- log(pred_probs)

    ## Make single coefficient table
    tab <- data.frame(term = names(coef(fit)),
                      estimate = coef(fit),
                      std.error = sqrt(diag(vcov(fit))),
                      stringsAsFactors = FALSE)
    tab$statistic <- tab$estimate / tab$std.error
    tab$p.value <- 2 * pnorm(-abs(tab$statistic))
    rownames(tab) <- NULL    

    ## Run hypothesis tests
    test_main <- linearHypothesis(fit,
                                  hyp_main)
    test_power <- linearHypothesis(fit,
                                   hyp_power)

    ## Cross-validate manually
    fold_id <- createMultiFolds(y = fit$y, k = number, times = repeats)
    cv_loss <- foreach (idx = fold_id, .combine = "c") %do% {
        ## Split sample according to fold IDs
        dat_in <- fit$model[idx, , drop = FALSE]
        dat_out <- fit$model[-idx, , drop = FALSE]
        y_out <- fit$y[-idx]

        ## Refit model to fold
        fit_in <- update(fit, data = dat_in)

        ## Make out-of-fold predictions and calculate log loss
        p_out <- predict(fit_in, newdata = dat_out, type = "response")
        p_out <- ifelse(y_out == 1, p_out, 1 - p_out)
        -1 * mean(log(p_out))
    }

    list(log_lik = log_lik,
         summary = tab,
         cv = data.frame(parameter = "none",
                         logLoss = mean(cv_loss),
                         logLossSD = sd(cv_loss)),
         test_main = test_main,
         test_power = test_power,
         formula = form,
         y = fit$y)
}

## Set up model formulas for mean and variance
f_mean <-
    init ~ gov + d_un + d_inf + d_gro + du_gov + di_gov + dg_gov + cap_1 + ipeace
f_var <-
    ~ gov + d_inf + di_gov + d_un + du_gov + d_gro + dg_gov + cap_1
f_arena_palmer_2009 <- as.Formula(f_mean, f_var)

## Null hypothesis: no effect of government orientation on mean or variance
hyp_main <- c("gov = 0",
              "du_gov = 0",
              "di_gov = 0",
              "dg_gov = 0",
              "(scale)_gov = 0",
              "(scale)_di_gov = 0",
              "(scale)_du_gov = 0",
              "(scale)_dg_gov = 0")

## Reproduce original model
set.seed(109)
cr_arena_palmer_2009 <- hetglm_and_cv(
   form = f_arena_palmer_2009,
   data = data_arena_palmer_2009,
   hyp_main = hyp_main,
   hyp_power = c("cap_1 = 0", "(scale)_cap_1 = 0"),
   number = 10,
   repeats = 10
)
print(cr_arena_palmer_2009$summary)

## Replicate with DOE scores
doe_arena_palmer_2009 <- hetglm_and_cv(
    form = update(f_arena_palmer_2009,
                  . ~ . - cap_1 + VictoryA + VictoryB |
                      . - cap_1 + VictoryA + VictoryB),
    data = data_arena_palmer_2009,
    hyp_main = hyp_main,
    hyp_power = c("VictoryA = 0", "(scale)_VictoryA = 0",
                  "VictoryB = 0", "(scale)_VictoryB = 0"),
    number = 10,
    repeats = 10
)
print(doe_arena_palmer_2009$summary)

save(cr_arena_palmer_2009,
     doe_arena_palmer_2009,
     file = "results/replications/arena-palmer-2009.rda")
