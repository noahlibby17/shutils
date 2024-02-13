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
#   1. Creates empty Conda env & installs mamba/jq                                               
#   2. Determines proper channel to install packages from (i.e. pip, conda-forge, etc.) 
#   3. Installs conda packages                                              
#   4. Installs pip packages   
#   5. Export environment.yml file 
#   6. Clean up
# 
# AUTHOR: Noah Libby
# CREATED: 2024-02
# VERSION: 2024-02
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
source ${CONDA_PREFIX}/etc/profile.d/conda.sh

## Add conda-forge
conda config --add channels conda-forge

echo "Activating environment"
if ! command -v conda activate $1 &> /dev/null; then
    echo "Conda activate command not found. Shell could not be initialized. Exiting..."
    exit 1
else
    conda activate $1
    echo "Active environment: $CONDA_DEFAULT_ENV"
fi

## Install mamba in new env
echo "Installing mamba"
conda install "mamba==1.4.9" -c conda-forge -y

## Make sure jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Trying to install..."

    # Determine correct package manager
    if command -v apt-get &> /dev/null; then
        package_manager="apt-get"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v brew &> /dev/null; then
        package_manager="brew"
    else
        echo "Error: Unsupported package manager"
    fi 

    # Install jq
    case $package_manager in
        "apt-get")
            #sudo apt-get update
            sudo apt-get install -y jq
            ;;
        "yum")
            #sudo yum update -y
            sudo yum install -y jq
            ;;
        "brew")
            brew install jq
            ;;
    esac

else
    echo "jq is already installed."
fi

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
conda install --file conda_packages.txt
## Install the pip packages, using conda packages as constraints
pip freeze | tee constraints.txt
echo "Installing pip packages"
pip install -r pip_packages.txt -c constraints.txt

## Save as environment.yaml file
echo "Adding conda packages to environment.yml"
conda env export --name $1 --no-build > ${1}_environment.yml

echo "Adding pip packages to environment.yml"
prefix_line=$(grep "^prefix:" ${1}_environment.yml)
awk '!/^prefix:/' "${1}_environment.yml" > "environment_temp.yml" && mv "environment_temp.yml" "${1}_environment.yml"
awk 'BEGIN {print "  - pip:"} {print "    - " $0}' pip_packages.txt >> ${1}_environment.yml
echo "$prefix_line" >> ${1}_environment.yml

# Clean up
rm conda_packages.txt pip_packages.txt constraints.txt