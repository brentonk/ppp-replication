Bootstrap: docker
From: rocker/verse:3.4.3

# Edit the first line to point to wherever the replication
# directory is stored on your system
%post
    base=/home/kenkelb/pppr
    PATH=${PATH}:/usr/lib/rstudio-server/bin:/opt/TinyTeX/bin/x86_64-linux/
    install2.r --error \
      Amelia C50 RcppRoll car caret doMC doRNG foreach \
      ggtern glmx iterators kernlab mlogit multiwayvcov plyr \
      pscl randomForest sqldf tikzDevice
    mkdir -p ${base} ${base}/results \
      ${base}/results/latex ${base}/results/logs-models ${base}/results/predict \
      ${base}/results/replications ${base}/results/varimp ${base}/results/weights \
      ${base}/results/logs-weights \
      /scratch /data /gpfs21 /gpfs22 /gpfs23
    tlmgr install -repository ctan --force pgf xcolor preview
