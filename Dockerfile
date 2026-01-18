# Full performance multi-stage build with complete CUDA toolchain
ARG CUDA_BASE_IMAGE_TAG=12.1.1-cudnn8-devel-ubuntu22.04
FROM nvidia/cuda:${CUDA_BASE_IMAGE_TAG} AS builder

# Environment mode: "lock" for reproducible builds, "yaml" for flexible dev builds
ARG BUILD_MODE=yaml

# Install complete build dependencies including CUDA compiler tools
RUN apt-get update && apt-get install -y \
    wget \
    libopenmpi-dev \
    libaio-dev \
    git \
    python3-dbg \
    build-essential \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install miniforge
# FIXME this needs to be pinned, with more recent versions (25.11.0-1) the package resolution is stuck
RUN wget -P /tmp \
    "https://github.com/conda-forge/miniforge/releases/download/25.11.0-1/Miniforge3-Linux-x86_64.sh" \
    && bash /tmp/Miniforge3-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniforge3-Linux-x86_64.sh

ENV PATH=/opt/conda/bin:$PATH

# Install environment based on BUILD_MODE
# - lock: uses conda-lock for exact reproducible builds (training/production)
# - yaml: uses mamba env create for flexible version resolution (development/testing)
RUN wget -P /tmp https://raw.githubusercontent.com/aqlaboratory/openfold-3/refs/heads/main/scripts/snakemake_msa/aln_env.yml
RUN mamba env create -f /tmp/aln_env.yml
RUN mamba clean --all --yes \
    && conda clean --all --yes

# Activate the of3-aln-env environment by default
ENV PATH=/opt/conda/envs/of3-aln-env/bin:$PATH
ENV CONDA_PREFIX=/opt/conda/envs/of3-aln-env
ENV CONDA_DEFAULT_ENV=of3-aln-env

ARG CUDA_BASE_IMAGE_TAG=12.1.1-cudnn8-devel-ubuntu22.04
FROM nvidia/cuda:${CUDA_BASE_IMAGE_TAG} AS devel

# Install devel dependencies
RUN apt-get update && apt-get install -y \
    libopenmpi3 \
    libaio1 \
    libaio-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Remove only documentation and samples, keep compiler tools
RUN rm -rf /usr/local/cuda/doc \
    && rm -rf /usr/local/cuda/extras \
    && rm -rf /usr/local/cuda/samples \
    && rm -rf /usr/local/cuda/src \
    && rm -rf /usr/local/cuda/nsight* \
    && rm -rf /usr/local/cuda/lib64/libcudart_static.a \
    && rm -rf /usr/local/cuda/lib64/libcublas_static.a \
    && rm -rf /usr/local/cuda/lib64/libcurand_static.a \
    && rm -rf /usr/local/cuda/lib64/libcusolver_static.a \
    && rm -rf /usr/local/cuda/lib64/libcusparse_static.a \
    && rm -rf /usr/local/cuda/lib64/libnpp_static.a \
    && rm -rf /usr/local/cuda/lib64/libnvblas_static.a \
    && rm -rf /usr/local/cuda/lib64/libnvtoolsext_static.a \
    && rm -rf /usr/local/cuda/lib64/libnvrtc_static.a \
    && rm -rf /usr/local/cuda/lib64/libnvrtc-builtins_static.a

# Copy the entire conda environment
COPY --from=builder /opt/conda /opt/conda

# Activate the of3-aln-env environment by default
ENV PATH=/opt/conda/envs/of3-aln-env/bin:/opt/conda/bin:$PATH
ENV CONDA_PREFIX=/opt/conda/envs/of3-aln-env
ENV CONDA_DEFAULT_ENV=of3-aln-env

# Ensure interactive shells also activate openfold3
RUN /opt/conda/bin/conda init bash \
    && echo "conda activate of3-aln-env" >> /root/.bashrc

# Set environment variables
ENV KMP_AFFINITY=none
ENV LIBRARY_PATH=/opt/conda/envs/of3-aln-env/lib:$LIBRARY_PATH
ENV LD_LIBRARY_PATH=/opt/conda/envs/of3-aln-env/lib:$LD_LIBRARY_PATH


# Test stage - build on devel layer with test dependencies
FROM devel AS test

RUN wget https://raw.githubusercontent.com/aqlaboratory/openfold-3/refs/heads/main/scripts/snakemake_msa/MSA_Snakefile
