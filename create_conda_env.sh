#!/bin/bash
#######################################
# FILE: create_conda_env.sh
#
# ARGUMENTS:
#   $1: Name of the new Conda env
#   $2: Path to the requirements.txt file
# GLOBALS:
#   CONDA_DEFAULT_ENV
#   CONDA_PREFIX
#
# DESCRIPTION: Create Conda env from requirements.txt file.
#   1. Creates empty Conda env & installs mamba                                               
#   2. Determines proper channel to install packages from (i.e. pip, conda-forge, etc.) 
#   3. Installs conda packages                                              
#   4. Installs pip packages    
#   5. Clean up
# 
# AUTHOR: Noah Libby
# CREATED: 02-2024
# VERSION: 02-2024
#######################################

cat << "EOF"
  __  __         _       _           _  _           _    
 |  \/  |__ _ __| |___  | |__ _  _  | \| |___  __ _| |_  
 | |\/| / _` / _` / -_) | '_ \ || | | .` / _ \/ _` |   \ 
 |_|  |_\__,_\__,_\___| |_.__/\_, | |_|\_\___/\__,_|_||_|
                              |__/                       
EOF

# Create and activate new env
echo "----------"
echo "Creating new conda env: $1"
conda create --name $1 -y

## Source conda 
echo "Sourcing conda.sh"
source $CONDA_PREFIX/etc/profile.d/conda.sh

## Add conda-forge
conda config --add channels conda-forge

echo "Activating environment"
conda activate $1
echo "Active environment: $CONDA_DEFAULT_ENV"

## Install mamba in new env
echo "Installing mamba"
conda install "mamba==1.4.9" -c conda-forge -y

## Iterate through the requirements.txt file
while IFS= read -r package
do
    # Run mamba repoquery search for each package to find channel
    echo "Checking: $package"
    packages=$(mamba repoquery search "$package" --json | jq -e '.result.pkgs == []')
    # Add to pip_packages.txt if no match is found
    if $packages; then
        echo "$package // Not found in Conda channels. Adding to pip package list."
        echo "$package" >> pip_packages.txt  
    # Add to conda_packages.txt if a match is found
    else
        echo "$package // Found in conda channels."
        echo "$package" >> conda_packages.txt  
    fi
done < $2

## Install the conda packages
echo "Installing conda packages"
conda install -f conda_packages.txt
## Install the pip packages, using conda packages as constraints
pip freeze | tee constraints.txt
echo "Installing pip packages"
pip install -r pip_packages.txt -c constraints.txt

# Clean up
rm conda_packages.txt pip_packages.txt constraints.txt