FROM openjdk:8-jre-stretch
MAINTAINER Shuoyang Ding <dings@jhu.edu>
ENV ROOTDIR /root/
WORKDIR $ROOTDIR
SHELL ["/bin/bash", "-c"]
RUN apt-get update \
    && apt-get install apt-utils -y \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get install wget git -y \
    && wget http://www.cs.jhu.edu/~sding/downloads/ducttape.tar \
    && tar -xvf ducttape.tar \
    && chmod +x ducttape \
    && mv ducttape ducttape.jar /bin/ \
    && wget https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh -O install_conda.sh \
    && /bin/bash ./install_conda.sh -b -p $ROOTDIR/miniconda
ENV PATH=$ROOTDIR/miniconda/bin:$PATH
RUN python -m venv pytorch \
    && source pytorch/bin/activate \
    && pip install https://download.pytorch.org/whl/cpu/torch-1.0.0-cp36-cp36m-linux_x86_64.whl \
    && deactivate \
    && python -m venv mxnet \
    && source mxnet/bin/activate \
    && pip install mxnet \
    && deactivate \
    && conda create --name pytorch -y \
    && source activate pytorch \
    && conda install pytorch-cpu -c pytorch \
    && source deactivate \
    && conda create --name mxnet -y \
    && source activate mxnet \
    && conda install mxnet \
    && source deactivate
