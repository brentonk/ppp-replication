################################################################################
###
### Merge imputed NMC data into COW data
###
################################################################################

library("caret")
library("dplyr")
library("stringr")
library("tidyr")
library("xtable")

source("fn-merge-nmc-dyad.r")


###-----------------------------------------------------------------------------
### Load and clean the MID dispute-level data
###-----------------------------------------------------------------------------

raw_MID_dispute <- read.csv("data-mida-4.01.csv", na.strings = "-9")

## We only need a few variables:
##   * Dispute number (version 3, since version 4 is mostly missing)
##   * Starting and ending years
##   * Number of states on each side
##   * Outcome
data_MID_dispute <- select(raw_MID_dispute,
                           DispNum3,
                           year = StYear,
                           NumA,
                           NumB,
                           Outcome)

## Only want disputes with exactly one state on each side
data_MID_dispute <- filter(data_MID_dispute,
                           NumA == 1,
                           NumB == 1)
dim(data_MID_dispute)                   # 2209 cases

## Only want those that end in victory, yield, or stalemate
data_MID_dispute <- filter(data_MID_dispute,
                           Outcome %in% 1:5)
dim(data_MID_dispute)                   # 1799 cases

## Exclude disputes starting after 2007, the endpoint of the NMC data
##
## Previously, we'd excluded those *ending* after 2007, but if we're using
## start-year values of the capability components, there's no need to exclude
## those that begin early enough
data_MID_dispute <- filter(data_MID_dispute,
                           year <= 2007)
dim(data_MID_dispute)                   # 1740 cases

## Treat yields like victories
##   Yield by Side A -> Victory by Side B
##   Yield by Side B -> Victory by Side A
data_MID_dispute <- mutate(data_MID_dispute,
                           Outcome = ifelse(Outcome == 3,  # A yields
                                            2,             # B wins
                                            Outcome),
                           Outcome = ifelse(Outcome == 4,  # B yields
                                            1,             # A wins
                                            Outcome),
                           Outcome = factor(Outcome,
                                            levels = c(2, 5, 1),
                                            labels = c("VictoryB",
                                                       "Stalemate",
                                                       "VictoryA"),
                                            ordered = TRUE))
with(data_MID_dispute, table(Outcome))  # VictoryA: 201
                                        # VictoryB: 79
                                        # Stalemate: 1460


###-----------------------------------------------------------------------------
### Merge in the MID participant-level data
###-----------------------------------------------------------------------------

raw_MID_participant <- read.csv("data-midb-4.01.csv")

## Variables we need:
##   * Dispute number
##   * "Side A" indicator
##   * Country code
data_MID_participant <- select(raw_MID_participant,
                               DispNum3,
                               SideA,
                               ccode)

## Pare down to same set of MIDs as in the dispute-level data
data_MID_participant <- filter(data_MID_participant,
                               DispNum3 %in% data_MID_dispute$DispNum3)

## If we've done everything right, there should be 1740 each of 1s and 0s for
## the SideA indicator
with(data_MID_participant, table(SideA))
                                        # Yes

## Convert from "long" to "wide"
data_MID_participant <- data_MID_participant %>%
  mutate(SideA = factor(SideA,
                        levels = 1:0,
                        labels = c("ccode_a", "ccode_b"))) %>%
  spread(SideA, ccode)

## And now we should have 1740 rows, same as the dispute-level data
dim(data_MID_participant)               # Yes

## Merge country codes into the dispute-level data
data_MID <- left_join(data_MID_dispute,
                      data_MID_participant,
                      by = "DispNum3")

## Drop the variables we don't need anymore:
##   * Dispute number (not merging with any more MID data)
##   * Number of states on each side
data_MID <- select(data_MID,
                   -DispNum3,
                   -NumA,
                   -NumB)


###-----------------------------------------------------------------------------
### Merge with imputed NMC data
###-----------------------------------------------------------------------------

load("results/data-nmc.rda")
load("results/impute-nmc.rda")

## Create 10 imputed training sets by merging imputations of COW components into
## training data
imputations_train <- lapply(imputations_NMC,
                            merge_NMC_dyad,
                            dyad = data_MID)
lapply(imputations_train, dim)
lapply(imputations_train, head)

save(imputations_train,
     file = "results/imputations-train.rda")


###-----------------------------------------------------------------------------
### Make table of MID outcome distributions
###-----------------------------------------------------------------------------

table_MID <- table(data_MID$Outcome)
table_MID <- cbind(Count = table_MID,
                   Proportion = prop.table(table_MID))
table_MID <- data.frame(table_MID)

## Reorganize and clean up names
table_MID <- table_MID[3:1, ]
rownames(table_MID) <- c("A Wins",
                         "Stalemate",
                         "B Wins")

xtable_MID <- xtable(table_MID,
                     align = c("l", "r", "r"),
                     display = c("s", "d", "f"))

print(xtable_MID,
      file = "results/latex/tab-mid.tex",
      floating = FALSE,
      include.rownames = TRUE)
