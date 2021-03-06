#!/bin/bash -e
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prepares the local filesystem to build the Google Cloud DataLab
# docker image. Note that invocations of this should generally
# be followed by a `docker build` and then `cleanup.sh`.
#
# Usage:
#   ../../sources/build.sh
#   prepare.sh datalab-base
#   docker build -t datalab ./
#   cleanup.sh
#
# If [path_of_pydatalab_dir] is provided, it will copy the content of that dir into image.
# Otherwise, it will get the pydatalab by "git clone" from pydatalab repo.

pushd $(pwd) >> /dev/null
HERE=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd "${HERE}"

# Create a versioned Dockerfile based on current date and git commit hash
export REVISION_ID="${2:-}"
source ../../tools/release/version.sh

VERSION_SUBSTITUTION="s/_version_/$DATALAB_VERSION/"
COMMIT_SUBSTITUTION="s/_commit_/$DATALAB_COMMIT/"
BASE_IMAGE_SUBSTITUTION="s/_base_image_/${1}/"

cat Dockerfile.in | sed $VERSION_SUBSTITUTION | sed $COMMIT_SUBSTITUTION | sed $BASE_IMAGE_SUBSTITUTION > Dockerfile

# Build the datalab frontend if necessary
if [ ! -d ../../build/ ]; then
    ../../sources/build.sh
fi

function install_rsync() {
  echo "Installing rsync"
  pacman -S rsync
  #apt-get update -y -qq
  #apt-get install -y -qq rsync
}

# Copy build outputs as a dependency of the Dockerfile
rsync -h >/dev/null 2>&1 || install_rsync
rsync -avp ../../build/ build

# Copy the license file into the container
cp ../../third_party/license.txt content/license.txt

popd >> /dev/null
