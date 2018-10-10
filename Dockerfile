FROM rocker/geospatial:latest
MAINTAINER "Noam Ross" ross@ecohealthalliance.org

# Add nvidia GPU stuff

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
    ca-certificates apt-transport-https gnupg1-curl && \
    rm -rf /var/lib/apt/lists/* && \
  #  NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
  #  NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
  #  apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
  #  apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
  #  echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDA_VERSION 9.0.176
ENV CUDA_BLAS_VERSION 9.0.176.4-1

ENV CUDA_PKG_VERSION 9-0=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-9.0 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV CUDA_HOME /usr/local/cuda
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/bin/lib64:/usr/local/cuda/extras/CUPTI/lib64
 
# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.0"

ENV NCCL_VERSION 2.3.5

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
        cuda-libraries-$CUDA_PKG_VERSION \
 # >9.2 only       cuda-nvtx-$CUDA_PKG_VERSION \
        cuda-cublas-9-0=$CUDA_BLAS_VERSION \
        libnccl2=$NCCL_VERSION-2+cuda9.0 \
        cuda-samples-$CUDA_PKG_VERSION && \
    apt-mark hold libnccl2 && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
            cuda-libraries-dev-$CUDA_PKG_VERSION \
            cuda-nvml-dev-$CUDA_PKG_VERSION \
            cuda-minimal-build-$CUDA_PKG_VERSION \
            cuda-command-line-tools-$CUDA_PKG_VERSION \
#            cuda-cublas-$CUDA_PKG_VERSION \
#            cuda-cufft-$CUDA_PKG_VERSION \
#            cuda-curand-$CUDA_PKG_VERSION \
#            cuda-cusolver-$CUDA_PKG_VERSION \
#            cuda-cusparse-$CUDA_PKG_VERSION \
            libnccl-dev=$NCCL_VERSION-2+cuda9.0 \
   && rm -rf /var/lib/apt/lists/*

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs

ENV CUDNN_VERSION 7.3.1.20
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
            libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 && \
    apt-mark hold libcudnn7 && \
    rm -rf /var/lib/apt/lists/*


RUN apt-get update && apt-get install -y --no-install-recommends \
      python-dev \
      python-pip \
#  && pip install --upgrade pip \
 && pip install virtualenv \
 && pip install wheel setuptools scipy --upgrade \
 && pip install h5py pyyaml requests Pillow tensorflow-gpu keras

RUN install2.r --error --skipinstalled \
    keras

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
      cmake \
  && rm -rf /var/lib/apt/lists/* \
  && git clone --recursive https://github.com/dmlc/xgboost \
  && mkdir -p xgboost/build && cd xgboost/build \
  && cmake .. -DUSE_CUDA=ON -DR_LIB=ON \
  && make install -j$(nproc) \
  && cd ../.. && rm -rf xgboost

RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >> /etc/rstudio/rserver.conf \
 && echo $CUDA_HOME >> /etc/environment
