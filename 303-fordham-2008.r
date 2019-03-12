################################################################################
###
### Replication of Fordham 2008, "Power or Plenty?", replacing CINC scores with
### DOE scores
###
### Replicating Table 2, third column (alliance onset with full set of controls)
###
################################################################################

library("caret")
library("dplyr")
library("foreign")

source("fn-glm-and-cv.r")

raw_fordham_2008 <- read.csv("data-fordham-2008.csv")
doe_dyad <- read.csv("results/predict-dyad.csv")

## Convert response to factor and remove unused cases
data_fordham_2008 <- raw_fordham_2008 %>%
    mutate(atopdo = factor(
               atopdo,
               levels = 0:1,
               labels = c("No", "Yes")
           )) %>%
    filter(ccode < 1000)

## To prevent spurious missingness in DOE scores, recode Germany 1992-2001 as
## Germany (255) instead of West Germany (260)
data_fordham_2008 <- within(data_fordham_2008,
                            ccode[ccode == 260 & year >= 1992] <- 255)

## Merge in DOE scores
##
## Using undirected form since CINC is used more as a proxy for raw power than
## as expectations about a specific conflict
data_fordham_2008 <- left_join(data_fordham_2008,
                               doe_dyad %>% filter(ccode_a == 2),
                               by = c(ccode = "ccode_b",
                                      year = "year"))
stopifnot(with(data_fordham_2008,
               sum(is.na(VictoryA) & !is.na(lncap_2)) == 0))

## Eliminate cases where CINC is missing but not DOE
##
## TODO: What's going on here?  Almost all of 2002 seems to fall into this
## category, for starters
data_fordham_2008 <- data_fordham_2008 %>%
    filter(!is.na(lncap_1),
           !is.na(lncap_2))

## Replicating Table 2, third column
f_fordham_2008 <-
    atopdo ~ lnexports1 + lndistance + lntotmids10_1 + lntotmids10_2 +
        lndyadmid10 + lncap_1 + lncap_2 + polity22 + coldwar + noallyrs +
        X_prefail + X_spline1 + X_spline2 + X_spline3

## Null hypothesis: no effect of previous year's exports
hyp_main <- "lnexports1 = 0"

## Reproduce original model and cross-validate
set.seed(608)
cr_fordham_2008 <- glm_and_cv(
    form = f_fordham_2008,
    data = data_fordham_2008,
    se_cluster = data_fordham_2008$ccode,
    hyp_main = hyp_main,
    hyp_power = c("lncap_1 = 0", "lncap_2 = 0"),
    number = 10,
    repeats = 100,
    probit = TRUE
)
print(cr_fordham_2008$summary)

## Replicate, replacing CINC scores with DOE scores
doe_fordham_2008 <- glm_and_cv(
    form = update(f_fordham_2008,
                  . ~ . - lncap_1 - lncap_2 + log(VictoryA) + log(VictoryB)),
    data = data_fordham_2008,
    se_cluster = data_fordham_2008$ccode,
    hyp_main = hyp_main,
    hyp_power = c("log(VictoryA) = 0", "log(VictoryB) = 0"),
    number = 10,
    repeats = 100,
    probit = TRUE
)
print(doe_fordham_2008$summary)

## Check that response is identical across runs
stopifnot(identical(as.vector(cr_fordham_2008$y),
                    as.vector(doe_fordham_2008$y)))

save(cr_fordham_2008,
     doe_fordham_2008,
     file = "results/replications/fordham-2008.rda")
