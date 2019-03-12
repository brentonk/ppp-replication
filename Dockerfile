FROM rocker/verse:3.4.3

# Install R packages
#
# Doing this separately from the other RUN statements to take advantage of
# Docker caching, otherwise this will rerun every time we want to change the
# filesystem structure
RUN install2.r --error \
    Amelia C50 RcppRoll car caret doMC doRNG foreach \
    ggtern glmx iterators kernlab mlogit multiwayvcov pscl \
    randomForest sqldf tikzDevice

# Base directory --- mirroring the ACCRE file system here
ARG base=/home/kenkelb/pppr

RUN mkdir -p ${base} ${base}/results \
    ${base}/results/latex ${base}/results/logs-models ${base}/results/predict \
    ${base}/results/replications ${base}/results/varimp ${base}/results/weights \
    ${base}/results/logs-weights \
    # To mirror ACCRE filesystem
    /scratch /data /gpfs21 /gpfs22 /gpfs23 \
    # LaTeX packages needed for tikzDevice
    && tlmgr install --force pgf xcolor preview

ENV HOME=${base}

WORKDIR ${base}
