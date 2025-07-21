#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

conda_install_accepted() {
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
    echo "Creating new Conda environment cosmos-predict1..."
    conda env create --file /cosmos-predict1.yaml
    conda activate cosmos-predict1
    pip install --no-cache-dir -r /requirements.txt
    ln -sf $CONDA_PREFIX/lib/python3.10/site-packages/nvidia/*/include/* $CONDA_PREFIX/include/
    ln -sf $CONDA_PREFIX/lib/python3.10/site-packages/nvidia/*/include/* $CONDA_PREFIX/include/python3.10
    ln -sf $CONDA_PREFIX/lib/python3.10/site-packages/triton/backends/nvidia/include/* $CONDA_PREFIX/include/
    pip install transformer-engine[pytorch]==1.12.0
    git clone https://github.com/NVIDIA/apex && cd apex
    CUDA_HOME=$CONDA_PREFIX pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" .
    echo "Environment setup complete"
    cat <<EOF >> /root/.bashrc
if [ -d "$CONDA_PREFIX/envs/cosmos-predict1" ]; then
    echo "Conda environment cosmos-predict1 already exists"
    echo "Activating Conda environment cosmos-predict1..."
    source ~/miniconda3/bin/activate
    conda activate cosmos-predict1
fi
EOF
}

conda_install_ask() {
    cat <<EOF >> /root/.bashrc
if [ -d "$CONDA_PREFIX/envs/cosmos-predict1" ]; then
    echo "Conda environment cosmos-predict1 already exists"
    echo "Activating existing environment..."
    source ~/miniconda3/bin/activate
    conda activate cosmos-predict1
else
    echo "=============================================================================================================="
    echo "Note: This container did not have a pre-accepted conda_terms_of_service value when it was built                "
    echo "Conda environment cosmos-predict1 will be created now, once you accept the terms and conditions.              "
    echo "This may take a while...                                                                                      "
    echo "Alternatively, you can build the container from github using the following command:"
    echo "\n"
    echo "docker build -f Dockerfile --build-arg conda_terms_of_service=accept -t cosmos-predict1 ."
    echo "\n"
    echo "and then run the container with the following command:                                                        "
    echo "\n"
    echo "docker run -it  --gpus all --ipc=host cosmos-predict1"
    echo "\n"
    echo "=============================================================================================================="
    source ~/miniconda3/bin/activate
    conda env create --file /cosmos-predict1.yaml
    pip install --no-cache-dir -r /requirements.txt
    ln -sf $CONDA_PREFIX/lib/python3.10/site-packages/nvidia/*/include/* $CONDA_PREFIX/include/
    ln -sf $CONDA_PREFIX/lib/python3.10/site-packages/nvidia/*/include/* $CONDA_PREFIX/include/python3.10
    ln -sf $CONDA_PREFIX/lib/python3.10/site-packages/triton/backends/nvidia/include/* $CONDA_PREFIX/include/
    pip install transformer-engine[pytorch]==1.12.0
    git clone https://github.com/NVIDIA/apex && cd apex
    CUDA_HOME=$CONDA_PREFIX pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" .
    echo "Environment setup complete"
    conda activate cosmos-predict1
fi
EOF
}

if [ "$conda_terms_of_service" = "ask" ]; then
    echo "=============================================================================================================="
    echo "Note: This container does not have a pre-accepted conda_terms_of_service value in the Dockerfile build argument"
    echo "Conda environment will be created when the user first runs the container, this may take a while..."
    echo "[ conda_terms_of_service=$conda_terms_of_service ]"
    echo "Alternatively, you can build the container from github using the following command:"
    echo "\n"
    echo "docker build -f Dockerfile --build-arg conda_terms_of_service=accept -t cosmos-predict1 ."
    echo "\n"
    echo "and then run the container with the following command:                                                        "
    echo "\n"
    echo "docker run -it  --gpus all --ipc=host cosmos-predict1"
    echo "\n"
    echo "=============================================================================================================="
    conda_install_ask
elif [ "$conda_terms_of_service" = "accept" ]; then
    echo "=============================================================================================================="
    echo "Conda installer terms and conditions accepted from user-specified value in the Dockerfile build argument"
    echo "[ conda_terms_of_service=$conda_terms_of_service ]"
    echo "Continuing with Conda environment creation during container build, this may take a while..."
    echo "=============================================================================================================="
    conda_install_accepted
elif [ "$conda_terms_of_service" = "reject" ]; then
    echo "Conda installer terms and conditions rejected from user-specified value in the Dockerfile build argument"
    echo " [ conda_terms_of_service=$conda_terms_of_service ]"
    echo "Exiting..."
    exit 1
else
    echo "Invalid conda_terms_of_service value: $conda_terms_of_service. Should be one of: ask, accept"
    exit 1
fi
