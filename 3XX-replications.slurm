#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --mem=24G
#SBATCH --array=300-317
#SBATCH --output=results/logs-replications/%a.out

# Get name of R script to run for the current array task
this_script=`ls | grep -m 1 "^${SLURM_ARRAY_TASK_ID}.*\.r"`
echo "Current script: " $this_script

# This is a *sample* SLURM submission script.  The wall time may need to be
# adjusted depending on your local resources.
#
# The following command assumes your cluster environment uses R 3.4.3 with the
# correct versions of the required packages, as described in the README.  If you
# have built our Singularity image into a file called pppr.simg and your cluster
# environment supports Singularity, replace the below command with:
#
#   singularity exec pppr.simg Rscript $this_script

Rscript $this_script
