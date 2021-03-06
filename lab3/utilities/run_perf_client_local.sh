#!/bin/bash

# Copyright (c) 2020 NVIDIA CORPORATION. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. 

MODEL_NAME=${1:-"bert"}
MODEL_VERSION=${2:-1}
precision=${3:-"fp32"}
BATCH_SIZE=${4:-1}
MAX_LATENCY=${5:-500}
MAX_CLIENT_THREADS=${6:-10}
MAX_CONCURRENCY=${7:-50}
SERVER_HOSTNAME=${8:-"localhost"}
DOCKER_BRIDGE=${9:-"host"}
RESULTS_ID=${10:-""}
PROFILING_DATA=${11:-"triton/profiling_data_int64"}
NV_VISIBLE_DEVICES=${12:-"0"}

if [[ $SERVER_HOSTNAME == *":"* ]]; then
  echo "ERROR! Do not include the port when passing the Server Hostname. These scripts require that the TRITON HTTP endpoint is on Port 8000 and the gRPC endpoint is on Port 8001. Exiting..."
  exit 1
fi

# add wait because server is polling model repository
sleep 10

# Wait until server is up. curl on the health of the server and sleep until its ready
bash utilities/wait_for_triton_server.sh $SERVER_HOSTNAME

TIMESTAMP=$(date "+%y%m%d_%H%M")

# Create model directory on host (directory /results is mounted)
mkdir -p ./results/${MODEL_NAME}

if [ ! -z "${RESULTS_ID}" ];
then
    RESULTS_ID="_${RESULTS_ID}"
fi

OUTPUT_FILE_CSV="./results/${MODEL_NAME}/results${RESULTS_ID}_${TIMESTAMP}.csv"

ARGS="\
   --max-threads ${MAX_CLIENT_THREADS} \
   -m ${MODEL_NAME} \
   -x ${MODEL_VERSION} \
   -p 3000 \
   -d \
   -v \
   -i gRPC \
   -u ${SERVER_HOSTNAME}:8001 \
   -b ${BATCH_SIZE} \
   -l ${MAX_LATENCY} \
   -c ${MAX_CONCURRENCY} \
   -f ${OUTPUT_FILE_CSV} \
   --input-data ${PROFILING_DATA}"
   

/workspace/install/bin/perf_client $ARGS
