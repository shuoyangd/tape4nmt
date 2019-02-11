FROM openjdk:8-jre-stretch
MAINTAINER Shuoyang Ding <dings@jhu.edu>
ENV ROOTDIR /root/
WORKDIR $ROOTDIR
SHELL ["/bin/bash", "-c"]
# apt-get necessary utilities
RUN apt-get update \
    && apt-get install apt-utils -y \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get install wget git gcc cmake build-essential -y
# configure more apt-get packages
RUN apt-get install libffi-dev libprotobuf-dev protobuf-compiler -y
    # && wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protobuf-cpp-3.6.1.tar.gz \
    # && tar -zxvf protobuf-cpp-3.6.1.tar.gz \
    # && cd protobuf-3.6.1 \
    # && ./configure && make && make install && ldconfig
# configure ducttape
RUN wget http://www.cs.jhu.edu/~sding/downloads/ducttape.tar \
    && tar -xvf ducttape.tar \
    && chmod +x ducttape \
    && mv ducttape ducttape.jar /bin/
# configure miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh -O install_conda.sh \
    && /bin/bash ./install_conda.sh -b -p $ROOTDIR/miniconda \
    && ln -s $ROOTDIR/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
ENV PATH=$ROOTDIR/miniconda/bin:$PATH
# configure pytorch venv
RUN python -m venv pytorch \
    && source pytorch/bin/activate \
    && pip install https://download.pytorch.org/whl/cpu/torch-1.0.0-cp36-cp36m-linux_x86_64.whl \
    && deactivate
# configure mxnet conda
RUN conda create --name mxnet -y \
    && source activate mxnet \
    && conda install mxnet \
    && source deactivate

