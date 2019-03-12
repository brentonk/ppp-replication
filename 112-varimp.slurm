#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --time=72:00:00
#SBATCH --mem=16G
#SBATCH --array=0-179
#SBATCH --output=results/logs-varimp/%a.out

# This is a *sample* SLURM submission script.  The wall time may need to be
# adjusted depending on your local resources.
#
# The following command assumes your cluster environment uses R 3.4.3 with the
# correct versions of the required packages, as described in the README.  If you
# have built our Singularity image into a file called pppr.simg and your cluster
# environment supports Singularity, replace the below command with:
#
#   singularity exec pppr.simg Rscript 112-varimp.r $SLURM_ARRAY_TASK_ID

Rscript 112-varimp.r $SLURM_ARRAY_TASK_ID
