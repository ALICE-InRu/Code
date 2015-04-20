#!/bin/bash
#Copy environment, join output and error, medium queue:
#PBS -V
#PBS -j oe
#PBS -q long
#PBS -l cput=2800:00:00
#PBS -m n
#PBS -N JSPrndGLOBAL 
# Go to the directory where the job was submitted from
cd $PBS_O_WORKDIR
/share/apps/opt/matlab/bin/matlab -nojvm -r "tic; [xmin,esWeights]=bruteforceGlobalESapproach('jrnd'), toc; exit"

