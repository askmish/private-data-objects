#!/bin/bash

# Copyright 2018 Intel Corporation
#
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

SCRIPTDIR="$(dirname $(readlink --canonicalize ${BASH_SOURCE}))"
SRCDIR="$(realpath ${SCRIPTDIR}/..)"

# -----------------------------------------------------------------
# -----------------------------------------------------------------
cred=`tput setaf 1`
cgrn=`tput setaf 2`
cblu=`tput setaf 4`
cmag=`tput setaf 5`
cwht=`tput setaf 7`
cbld=`tput bold`
bred=`tput setab 1`
bgrn=`tput setab 2`
bblu=`tput setab 4`
bwht=`tput setab 7`
crst=`tput sgr0`

function recho () {
    echo "${cbld}${cred}" $@ "${crst}" >&2
}

function becho () {
    echo "${cbld}${cblu}" $@ "${crst}" >&2
}

function yell() {
    becho "$(basename $0): $*" >&2
}

function die() {
    recho "$(basename $0): $*" >&2
    exit 111
}

function try() {
    "$@" || die "test failed: $*"
}

# -----------------------------------------------------------------
# CHECK ENVIRONMENT
# -----------------------------------------------------------------
yell --------------- CONFIG AND ENVIRONMENT CHECK ---------------

: "${TINY_SCHEME_SRC?Missing environment variable TINY_SCHEME_SRC}"
: "${CONTRACTHOME?Missing environment variable CONTRACTHOME}"
: "${PDO_ENCLAVE_PEM?Missing environment variable PDO_ENCLAVE_PEM}"
: "${SGX_SSL?Missing environment variable SGX_SSL}"
: "${SGX_SDK?Missing environment variable SGXSDKInstallPath}"
: "${SGX_MODE:?Missing environment variable SGX_MODE, set it to HW or SIM}"
: "${SGX_DEBUG:?Missing environment variable SGX_DEBUG, set it to 1}"
: "${PKG_CONFIG_PATH?Missing environment variable PKG_CONFIG_PATH}"

try command -v python
PY3_VERSION=$(python --version | sed 's/Python 3\.\([0-9]\).*/\1/')
if [[ $PY3_VERSION -lt 5 ]]; then
    die must use python3, activate virtualenv first
fi

try command -v openssl
OPENSSL_VERSION=$(openssl version -v | sed 's/.*Library: OpenSSL \([^ ]*\) .*/\1/')
if [ $OPENSSL_VERSION != '1.1.0h' ]; then
   die incorrect version of openssl $(OPENSSL_VERSION) expecting 1.1.0.h
fi

try command -v protoc
PROTOC_VERSION=$(protoc --version | sed 's/libprotoc \([0-9]\).*/\1/')
if [[ $PROTOC_VERSION -lt 3 ]]; then
    echo protoc must be version3 or higher
fi

try command -v cmake
try command -v swig
try command -v make
try command -v g++
try command -v tinyscheme

if [ ! -d "${CONTRACTHOME}" ]; then
    die CONTRACTHOME directory does not exist
fi

# -----------------------------------------------------------------
# BUILD
# -----------------------------------------------------------------
yell --------------- COMMON ---------------
cd $SRCDIR/common

rm -rf build
mkdir build
cd build
try cmake ..
try make

yell --------------- PYTHON ---------------
cd $SRCDIR/python
make clean
try make
try make install

yell --------------- ESERVICE ---------------
cd $SRCDIR/eservice
make clean
try make
try make install

yell --------------- PSERVICE ---------------
cd $SRCDIR/pservice
make clean
try make
try make install

yell --------------- CLIENT ---------------
cd $SRCDIR/client
make clean
try make
try make install

yell --------------- CONTRACTS ---------------
cd $SRCDIR/contracts
make clean
try make all
try make install
