#################################################################
# Dockerfile
#
# Version:          1.0
# Software:         OptiType-Columba
# Software Version: 1.3
# Description:      Accurate NGS-based 4-digit HLA typing boosted by Columba
# Website:          https://github.com/lrenders/OptiType-Columba
# Tags:             Genomics
# Provides:         OptiType-Columba 1.0
# Base Image:       biodckr/biodocker
# Build Cmd:        docker build --rm -t fred2/opitype .
# Pull Cmd:         docker pull fred2/optitype
# Run Cmd:          docker run -v /path/to/file/dir:/data fred2/optitype
#################################################################

# Source Image
FROM ubuntu:22.04

################## BEGIN INSTALLATION ###########################
USER root

# install
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update && apt-get install -y \
        gcc-11 \
        g++-11 \
        build-essential \
        coinor-cbc \
        zlib1g-dev \
        libbz2-dev \
        curl \
        python3-pip \
        git \
        cmake \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean


#HLA Typing
#OptiType dependecies
RUN curl -O https://support.hdfgroup.org/ftp/HDF5/current18/bin/hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz \
    && tar -xvf hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz \
    && mv hdf5/bin/* /usr/local/bin/ \
    && mv hdf5/lib/* /usr/local/lib/ \
    && mv hdf5/include/* /usr/local/include/ \
    && mv hdf5/share/* /usr/local/share/ \
    && rm -rf hdf5/ \
    && rm -f hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz

ENV LD_LIBRARY_PATH /usr/local/lib:$LD_LIBRARY_PATH
ENV HDF5_DIR /usr/local/

RUN pip install --upgrade pip && pip install \
    numpy \
    pyomo \
    pysam \
    matplotlib \
    tables \
    pandas \
    future
    
#installing optitype form git repository (version Dec 09 2015) and wirtig config.ini
RUN git clone https://github.com/lrenders/OptiType-Columba.git \
    && cd OptiType-Columba \
    && git checkout columba-boost \
    && cd .. \
    && sed -i -e '1i#!/usr/bin/env python\' OptiType-Columba/OptiTypePipeline.py \
    && mv OptiType-Columba/ /usr/local/bin/ \
    && chmod 777 /usr/local/bin/OptiType-Columba/OptiTypePipeline.py \
    && echo "[mapping]\n\
columba=/usr/local/bin/columba \n\
threads=1 \n\
\n\
[ilp]\n\
solver=cbc \n\
threads=1 \n\
\n\
[behavior]\n\
deletebam=true \n\
unpaired_weight=0 \n\
use_discordant=false\n" >> /usr/local/bin/OptiType-Columba/config.ini



# install Columba
RUN git clone https://github.com/biointec/columba.git columba-src \
    && cd columba-src \
    && git checkout v2.0.2 \
    && bash build_script.sh Vanilla \
    && mv build_Vanilla/columba /usr/local/bin/ \
    && cd .. \
    && rm -rf columba-src


ENV PATH=/usr/local/bin/OptiType-Columba:$PATH

# Change user to back to biodocker
USER biodocker

# Change workdir to /data/
WORKDIR /data/

# Define default command
ENTRYPOINT ["OptiTypePipeline.py"]
CMD ["-h"]

##################### INSTALLATION END ##########################

# File Author / Maintainer
MAINTAINER Benjamin Schubert <schubert@informatik.uni-tuebingen.de>
