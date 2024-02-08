#!/bin/bash

# This script will run tests in each module.
declare -a modules=("aws-nacl" "aws-vpc" "aws-vpc-gw", "aws-vpc-tgw")
len_modules=${#modules[@]}
CWD=$(pwd)

printf "###########################################\n"
printf "## EXECUTING TESTS FOR ALL MODULES ########\n"
printf "###########################################\n\n\n\n"

for (( i=0; i<${len_modules}; i++ ));
do
  printf "###########################################\n"
  printf "## Executing tests for module: ${modules[$i]}\n"
  printf "###########################################\n\n"
  cd ${CWD}/modules/${modules[$i]}
  printf "## Initializing module: ${modules[$i]}\n\n"
  terraform init
  printf "## Validating module: ${modules[$i]}\n\n"
  terraform validate
  printf "## Running tests for module: ${modules[$i]}\n\n"
  terraform test
done