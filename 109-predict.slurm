#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --time=12:00:00
#SBATCH --mem=8G
#SBATCH --array=1816-2007
#SBATCH --output=results/logs-predict/%a.out

# This is a *sample* SLURM submission script.  The wall time may need to be
# adjusted depending on your local resources.
#
# The following command assumes your cluster environment uses R 3.4.3 with the
# correct versions of the required packages, as described in the README.  If you
# have built our Singularity image into a file called pppr.simg and your cluster
# environment supports Singularity, replace the below command with:
#
#   singularity exec pppr.simg Rscript 109-predict.r $SLURM_ARRAY_TASK_ID 1

Rscript 109-predict.r $SLURM_ARRAY_TASK_ID 1
