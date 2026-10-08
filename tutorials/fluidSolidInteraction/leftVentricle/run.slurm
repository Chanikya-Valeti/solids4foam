#!/bin/bash -l
#SBATCH --job-name=test
#SBATCH --output=log.%x_%j.out
#SBATCH --error=log.%x_%j.err
#SBATCH --partition=long
#SBATCH --time=64:00:00
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1

cd "$SLURM_SUBMIT_DIR"

# Must be sourced before "set -u".
source /usr/lib/openfoam/openfoam2512/etc/bashrc

set -Eeo pipefail
IFS=$'\n\t'

echo "OpenFOAM: $WM_PROJECT_VERSION"
echo "solids4Foam: $(command -v solids4Foam)"
echo "MPI: $(command -v mpirun)"
echo "Allocated tasks: $SLURM_NTASKS"

./Allrun 
