# Replication Archive for "Prediction, Proxies, and Power"

Article by Robert J. Carroll and Brenton Kenkel.  Corresponding author for replication materials: Brenton Kenkel (<brenton.kenkel@gmail.com>).  We thank James Martherus for help assembling the replication materials.


## Overview of Files

Specific descriptions of R scripts appear in the last section of this file.

* `_all.sh`: Bash script containing instructions for running the full analysis.

* `[###]-[description].r`: R scripts used to run the analysis.  Numbered in the order that they should be run.

* `codebook.pdf`: PDF containing descriptions for the DOE score data files, all data used to construct DOE scores, all data used in the replication analyses, and metadata required to run our R scripts.

* `data-[description].csv` and `data-[description].dta`: Data files in CSV or Stata format used in the analysis.

* `Dockerfile`: Recipe for Docker image for replication of the full computing environment.

* `fn-[description].r`: R scripts containing helper functions.  These are called by other scripts and should not be run on their own.

* `metadata-[description].yml`: Metadata files in YAML format describing components of the analysis.

* `predict-dyad.csv` and `predict-dir-dyad.csv`: Data files in CSV containing the Dispute Outcome Expectations scores constructed in the course of the analysis.

* `README.pdf`: This file.

* `Singularity`: Recipe for Singularity image for replication of the full computing environment.  (Equivalent to the `Dockerfile`.)


## Installation

The analysis was performed using R version 3.4.3 in a Debian GNU/Linux 9 (stretch) environment.  We have provided a Dockerfile for exact replication of this environment, including the R package versions used in the analysis.

To run our code in a Docker container:

1.  Install Docker from <https://www.docker.com/>.  We used Docker version 18.09.1, build 4c52b90.

2.  At the command line, build the `pppr` Docker image by running:

        cd /path/to/ppp/replication/directory
        docker build -t pppr .

    Linux users may need to use `sudo` for Docker commands.

If you are using a computing cluster with access to Singularity but not Docker, we have provided an equivalent Singularity file.

If you choose not to use the provided Docker environment, then you must install the same version of R and the required packages that we used in order to obtain the same results.

1.  Install R version 3.4.3 from <http://cran.r-project.org>.

2.  Install the following R package versions:

    *   Amelia (1.7.4)
    *   broom (0.4.3)
    *   C50 (0.1.1)
    *   car (2.1-6)
    *   caret (6.0-78)
    *   doMC (1.3.5)
    *   doRNG (1.6.6)
    *   dplyr (0.7.4)
    *   foreach (1.4.4)
    *   foreign (0.8-69)
    *   Formula (1.2-2)
    *   ggplot2 (2.2.1)
    *   ggtern (2.2.1)
    *   glmx (0.1-1)
    *   iterators (1.0.9)
    *   kernlab (0.9-25)
    *   magrittr (1.5)
    *   MASS (7.3-47)
    *   mlogit (0.2-4)
    *   multiwayvcov (1.2.3)
    *   nnet (7.3-12)
    *   plyr (1.8.4)
    *   pscl (1.5.2)
    *   randomForest (4.6-12)
    *   RColorBrewer (1.1-2)
    *   RcppRoll (0.2.2)
    *   reshape2 (1.4.3)
    *   rpart (4.1-11)
    *   sandwich (2.4-0)
    *   sqldf (0.4-11)
    *   stringr (1.3.0)
    *   tidyr (0.8.0)
    *   tikzDevice (0.10-1.2)
    *   xtable (1.8-2)
    *   yaml (2.1.18)

Some portions of the analysis are computationally intensive and are designed to be run in parallel.  You should have access to a computing cluster if you want to replicate the analysis in a reasonable amount of time.


## R Scripts

The R scripts should be run in the order they are numbered.  Some of the scripts should be run multiple times with different command line arguments; these can be run in parallel.  The file `_all.sh` provides the exact commands to run.

All scripts should be run at the command line using `Rscript`.  Some require command line arguments, as specified in the instructions below.

To ensure exact replication, or if you cannot install the correct version of R and the specified packages on your system, you should use the Docker image, as specified in the instructions above and in `_all.sh`.  When running in Docker, make sure there is a volume that points from the location of the replication files on your system to the directory `/home/kenkelb/pppr` within the container.  For example, if the files live on your machine in `/Users/yourname/Downloads/pppr`, the command to run the first script is

    docker run --rm -it \
      -v /Users/yourname/Downloads/pppr:/home/kenkelb/pppr \
      pppr Rscript 000-install.r

Linux users without root access may need to use `sudo docker ...` instead.

### Setup

1.  `000-install.r`: Sets up the `results/` subfolder and the necessary subdirectories to store all results.

    This script can also be used to install the *most recent* versions of the required R packages, which are unlikely to coincide with the ones we used in the analysis.  We instead recommend (best choice) using the supplied Docker image or (second-best) manually installing the required package versions.

### DOE Score Calculations

1.  `100-nmc.r`: Cleaning and multiple imputation of the material capabilities data.  Output:

    *   `results/data-nmc.rda`: Cleaned data.

    *   `results/impute-nmc.rda` and `results/impute-nmc-new.rda`: Multiple imputation results.

    *   `results/latex/tab-summary.tex`: Table 1 of the online appendix.

2.  `101-mid.r`: Merge material capabilities data into dispute data.  Output:

    *   `results/imputations-train.rda`: Imputed datasets used for model training.

    *   `results/latex/tab-mid.tex`: Table 1 of the manuscript.

3.  `102-outcomes-time.r`: Plot distribution of outcomes over time.  Output:

    *   `results/latex/fig-outcomes-time.tex`: Figure 1 of the manuscript.

4.  `103-train-models.r`: For each multiply imputed dataset, train the candidate models for the super learner.  Output:

    *   `results/trained-models.rda`: Model training output.

5.  `104-train-weights.r`: Cross-validation for super learner weights.  Must be run with command line argument `i` for each `i` from 1 to 10, as in

        Rscript 104-train-weights.r 1
        Rscript 104-train-weights.r 2
        ...
        Rscript 104-train-weights.r 10

    These can be run in parallel on a cluster.  Output stored in `results/weights`.

6.  `105-collect-weights.r`: Collect results from the previous step.  Output:

    *   `results/trained-weights.rda`: Weight training output.

7.  `106-summarize-weights.r`: Summarize the results of the super learner training.  Output:

    *   `results/ensemble-loss.rda`: Model loss values used later in calculating variable importance.

    *   `results/latex/tab-ensemble.tex`: Table 3 of the manuscript.

8.  `107-capratio.r`: Ordered logit of dispute outcomes on the capability ratio.  Output:

    *   `results/latex/tab-capratio.tex`: Table 2 of the manuscript.

9.  `108-dir-dyad-year.r`: Make dataset of all directed dyad-years.  Output:

    *   `results/dir-dyad-year.rda`: Data frame of all directed dyad-years.

10. `109-predict.r`: Calculate predicted probabilities of dispute outcomes in the year specified as a command line argument.  Must be run with command line argument `i` for each `i` from 1816 to 2007, as in

        Rscript 109-predict.r 1816
        Rscript 109-predict.r 1817
        ...
        Rscript 109-predict.r 2007

    These can be run in parallel on a cluster.  Output stored in `results/predict`.

11. `110-collect-predict.r`: Collect predicted probabilities across years into unified files: the DOE scores.  Output:

    *    `results/predict-dir-dyad.csv`: DOE scores for directed dyads.

    *    `results/predict-dyad.csv`: DOE scores for undirected dyads.

12. `111-doe-vs-cinc.r`: Compare predictive performance of DOE scores to that of the capability ratio.  Output:

    *   `results/latex/fig-oof-pred.tex`: Figure 2 of the manuscript.

13. `112-varimp.r`: Estimate importance of individual variables in the predictive analysis.  Must be run with command line argument `i` for each `i` from 0 to 179, as in

        Rscript 112-varimp.r 0
        Rscript 112-varimp.r 1
        ...
        Rscript 112-varimp.r 179

    These can be run in parallel on a cluster.  Output stored in `results/varimp`.

14. `113-collect-varimp.r`: Collect results of variable importance analysis into a single file.  Output:

    *   `results/varimp.rda`: Variable importance analysis output.

15. `114-summarize-varimp.rda`: Summarize results of variable importance analysis.  Output:

    *   `results/latex/tab-varimp.tex`: Table 4 of the manuscript.

### Replication Studies

1.  `200-reed-run-and-plot.r`: Run main models in replication of Reed et al. (2008).  Output:

    *   `results/reed-et-al.rda`: Fitted models to pass to cross-validation script.

    *   `results/latex/fig-rcnw-gull.tex`: Figure 4 of the manuscript.

2.  `201-reed-cv-and-table.r`: Cross-validation of the Reed et. al (2008) replication analysis.  Output:

    *   `results/latex/tab-rcnw.tex`: Table 5 of the manuscript.

3.  Replications of 18 additional international conflict studies using DOE scores in place of the capability ratio.  Consists of the following scripts:

    *   `300-arena-palmer-2009.r`
    *   `301-bennett-2006.r`
    *   `302-dreyer-2010.r`
    *   `303-fordham-2008.r`
    *   `304-fuhrmann-sechser-2014.r`
    *   `305-gartzke-2007.r`
    *   `306-huth-2012.r`
    *   `307-jung-2014.r`
    *   `308-morrow-2007.r`
    *   `309-owsiak-2012.r`
    *   `310-park-colaresi-2014.r`
    *   `311-salehyan-2008-ajps.r`
    *   `312-salehyan-2008-jop.r`
    *   `313-sobek-abouharb-ingram-2006.r`
    *   `314-uzonyi-souva-golder-2012.r`
    *   `315-weeks-2008.r`
    *   `316-weeks-2012.r`
    *   `317-zawahri-mitchell-2011.r`

    Each of these can be run simultaneously, in parallel on a cluster.  Output of each containing model fit and cross-validation results stored in `results/replications`.

4.  `400-collect-replications.r`: Collect replication results into a single file.  Output:

    *   `results/latex/tab-replications.tex`: Table 6 of the manuscript.

    *   `results/latex/tab-replications-appendix.tex`: Table 2 of the online appendix.

5.  `401-describe-replications.r`: Print basic information about each replication for the online appendix.  Output:

    *   `results/latex/list-replications.tex`: Itemized list in Section 6 of the online appendix.

### Helper Scripts

These scripts are not meant to be run on their own, but instead are called within the scripts listed above.

*   `fn-collect.r`: Functions for collecting replication study results.

*   `fn-defs-train.r`: Specification for candidate models used in the super learner.

*   `fn-glm-and-cv.r`: Functions for cross-validating a logit/probit regression, used in many of the replication scripts.

*   `fn-merge-nmc-dyad.r`: Functions for merging material capabilities and militarized dispute data.

*   `fn-predict-from-ensemble.r`: Functions for calculating model predictions from the super learner ensemble.

*   `fn-train.r`: Functions for individual model training.

*   `fn-varimp.r`: Functions for estimating variable importance.
