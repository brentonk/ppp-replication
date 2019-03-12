################################################################################
###
### Replication of Weeks 2008, "Autocratic Audience Costs," replacing CINC ratio
### with DOE scores
###
### Replicating Model 3 (bilateral disputes only)
###
################################################################################

library("caret")
library("dplyr")
library("foreign")

source("fn-glm-and-cv.r")

raw_weeks_2008 <- read.csv("data-weeks-2008.csv")
doe_dir_dyad <- read.csv("results/predict-dir-dyad.csv")

## Transform data
##
## Same as in the .do file provided (and edited by Bryan)
data_weeks_2008 <- raw_weeks_2008 %>%
    mutate(recip = ifelse(cwhost2 > 1, 1, 0),
           recip = factor(
               recip,
               levels = 0:1,
               labels = c("No", "Yes")
           ),
           capshare1 = cap_1 / (cap_1 + cap_2),
           alliance = ifelse(alliance == -9, NA, alliance),
           ally = ifelse(alliance == 4, 0, 1),
           revtype = factor(
               cwrevt11,
               levels = 0:4,
               labels = c("None", "Territory", "Policy", "Government", "Other")
           ),
           contig = ifelse(contig < 6, 1, 0),
           bilateral = ifelse(cwnumst1 == 1 & cwnumst2 == 1, 1, 0),
           regimetype1 = factor(
               regimetype1,
               levels = 1:11,
               labels = c("Democracy",
                          "Personalist",
                          "Military",
                          "Single",
                          "Hybrid",
                          "DynasticMon",
                          "NonDynasticMon",
                          "Interregna",
                          "NoInfo",
                          "Other",
                          "InterregnaDem")
           ))

## Remove cases dropped from analysis
data_weeks_2008 <- data_weeks_2008 %>%
    filter(year != 1947 | abbrev1 != "IND",
           year != 1965 | abbrev1 != "ZIM",
           year != 1969 | abbrev1 != "ZIM",
           year > 1945,
           year < 2000) %>%
    droplevels()                        # Prevent spurious singularity warnings

## Merge in DOE scores
data_weeks_2008 <- left_join(data_weeks_2008,
                             doe_dir_dyad,
                             by = c(ccodecow = "ccode_a",
                                    ccodecow2 = "ccode_b",
                                    year = "year"))

## Check for dyad-years covered by CINC but not DOE
data_weeks_2008 %>%
    filter(!is.na(capshare1) & is.na(VictoryA)) %>%
    select(ccodecow, ccodecow2, year)
                                        # None

## Replicating Model 2
f_weeks_2008 <-
    recip ~ regimetype1 + majpow1*majpow2 + capshare1 + contig +
        ally + s_wt_glo + s_ld_1 + s_ld_2 + revtype

## Null hypothesis: equal coefficients for all regime types besides consolidated
## democracies (the base category)
hyp_main <- c("regimetype1Military = regimetype1Personalist",
              "regimetype1Single = regimetype1Personalist",
              "regimetype1Hybrid = regimetype1Personalist",
              "regimetype1DynasticMon = regimetype1Personalist",
              "regimetype1NonDynasticMon = regimetype1Personalist",
              "regimetype1Interregna = regimetype1Personalist",
              "regimetype1Other = regimetype1Personalist",
              "regimetype1InterregnaDem = regimetype1Personalist")

## Original model
set.seed(2308)
cr_weeks_2008 <- glm_and_cv(
    form = f_weeks_2008,
    data = data_weeks_2008,
    se_cluster = data_weeks_2008$cwkeynum,
    hyp_main = hyp_main,
    hyp_power = "capshare1 = 0",
    number = 10,
    repeats = 100
)
print(cr_weeks_2008$summary)

## Replace capability ratio with DOE scores
doe_weeks_2008 <- glm_and_cv(
    form = update(f_weeks_2008,
                  . ~ . - capshare1 + VictoryA + VictoryB),
    data = data_weeks_2008,
    se_cluster = data_weeks_2008$cwkeynum,
    hyp_main = hyp_main,
    hyp_power = c("VictoryA = 0", "VictoryB = 0"),
    number = 10,
    repeats = 100
)
print(doe_weeks_2008$summary)

save(cr_weeks_2008,
     doe_weeks_2008,
     file = "results/replications/weeks-2008.rda")
