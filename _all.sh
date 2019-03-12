#!/bin/bash


# --------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------

# Change the path here to wherever the replication files are stored on
# your system
pppr_dir=/path/to/ppp/replication

# Set up command for running R scripts via Docker
#
# On Linux, you may need to prepend "sudo" to this command if you are
# running as a user who is not a member of the Docker group
docker_cmd="docker run --rm -it -v ${pppr_dir}:/home/kenkelb/pppr pppr"


# --------------------------------------------------------------------
# Startup message / warning to not actually do it this way
# --------------------------------------------------------------------

pppr_msg="
----------------------------------------------------------------------

DESCRIPTION:

This file contains the script for full replication of 'Prediction,
Proxies, and Power' by Robert J. Carroll and Brenton Kenkel.

REQUIREMENTS:

You must have Docker installed on your system.  We used Docker
18.09.1, build 4c52b90.

Make sure to edit this script so that the Docker volume points to
where you have stored the replication archive on your computer.
Hopefully that is the directory you are running this script in:

    `pwd`

INSTRUCTIONS:

You probably -- in fact, almost certainly -- should not simply run
this script.  Running everything here in sequence would take months.
Certain portions of the code should be run in parallel on a computing
cluster.  Specifically, the portions that should be parallelized are:

* Super learner weight training (104-train-weights.r)
* DOE score calculation (109-predict.r)
* Variable importance estimation (112-varimp.slurm)

The replication studies (R scripts 300 through 317) can also be run in
parallel; they do not depend on each other's output.

If you *insist* on running this script in sequence -- which you really
shouldn't! -- you must first comment out the line that says:

    echo \"\${pppr_msg}\" && exit 0

----------------------------------------------------------------------
"

# Save 
echo "${pppr_msg}" && exit 0


# --------------------------------------------------------------------
# Build Docker image from Dockerfile
# --------------------------------------------------------------------

# Again, Linux users may need to prepend "sudo"
docker build -t pppr .


# --------------------------------------------------------------------
# Set up necessary subdirectories for storing results
# --------------------------------------------------------------------

${docker_cmd} Rscript 000-install.r


# --------------------------------------------------------------------
# DOE score construction
# --------------------------------------------------------------------

${docker_cmd} Rscript 100-nmc.r
${docker_cmd} Rscript 101-mid.r
${docker_cmd} Rscript 102-outcomes-time.r
${docker_cmd} Rscript 103-train-models.r

# Should actually be done in parallel on a cluster
for i in {1..10}
do
    ${docker_cmd} Rscript 104-train-weights.r ${i}
done

${docker_cmd} Rscript 105-collect-weights.r
${docker_cmd} Rscript 106-summarize-weights.r
${docker_cmd} Rscript 107-capratio.r
${docker_cmd} Rscript 108-dir-dyad-year.r

# Should actually be done in parallel on a cluster
for year in {1816..2007}
do
    ${docker_cmd} Rscript 109-predict.r ${year}
done

${docker_cmd} Rscript 110-collect-predict.r
${docker_cmd} Rscript 111-doe-vs-cinc.r

# Should actually be done in parallel on a cluster
for i in {0..179}
do
    ${docker_cmd} Rscript 112-varimp.r ${i}
done

${docker_cmd} Rscript 113-collect-varimp.r
${docker_cmd} Rscript 114-summarize-varimp.r


# --------------------------------------------------------------------
# Replication of Reed et al
# --------------------------------------------------------------------

${docker_cmd} Rscript 200-reed-run-and-plot.r
${docker_cmd} Rscript 201-reed-cv-and-table.r


# --------------------------------------------------------------------
# Replication of 18 other studies
#
# These can (and should) be run simultaneously on a cluster rather
# than in sequence
# --------------------------------------------------------------------

${docker_cmd} Rscript 300-arena-palmer-2009.r
${docker_cmd} Rscript 301-bennett-2006.r
${docker_cmd} Rscript 302-dreyer-2010.r
${docker_cmd} Rscript 303-fordham-2008.r
${docker_cmd} Rscript 304-fuhrmann-sechser-2014.r
${docker_cmd} Rscript 305-gartzke-2007.r
${docker_cmd} Rscript 306-huth-2012.r
${docker_cmd} Rscript 307-jung-2014.r
${docker_cmd} Rscript 308-morrow-2007.r
${docker_cmd} Rscript 309-owsiak-2012.r
${docker_cmd} Rscript 310-park-colaresi-2014.r
${docker_cmd} Rscript 311-salehyan-2008-ajps.r
${docker_cmd} Rscript 312-salehyan-2008-jop.r
${docker_cmd} Rscript 313-sobek-abouharb-ingram-2006.r
${docker_cmd} Rscript 314-uzonyi-souva-golder-2012.r
${docker_cmd} Rscript 315-weeks-2008.r
${docker_cmd} Rscript 316-weeks-2012.r
${docker_cmd} Rscript 317-zawahri-mitchell-2011.r


# --------------------------------------------------------------------
# Collect and summarize replication results
# --------------------------------------------------------------------

${docker_cmd} Rscript 400-collect-replications.r
${docker_cmd} Rscript 401-describe-replications.r

exit 0
