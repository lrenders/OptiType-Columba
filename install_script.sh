#!/bin/bash
set -e

# First install the environment using mamba or conda
if command -v mamba &>/dev/null; then
    echo "Using mamba to create the environment..."
    mamba env create -f optitype-env.yml
elif command -v conda &>/dev/null; then
    echo "Using conda to create the environment..."
    conda env create -f optitype-env.yml
else
    echo "Neither conda nor mamba is installed. Please install one of them to proceed."
    exit 1
fi

# pull the latest Columba image
echo "Installing Columba..."
git clone https://github.com/biointec/columba.git columba-src \
    && cd columba-src \
    && git checkout v2.0.2 \
    && bash build_script.sh Vanilla \
    && build_Vanilla/columba_build -f ../data/hla_reference_dna.fasta \
    && build_Vanilla/columba_build -f ../data/hla_reference_rna.fasta  \
    && mv build_Vanilla/columba ../columba \
    && cd .. \
    && rm -rf columba-src

# 