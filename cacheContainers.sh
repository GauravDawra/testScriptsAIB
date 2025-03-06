#!/bin/bash

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "           Starting Download Containers from ACR"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"

# Modify the default behavior to fail if an invoked command returns a non 0 exit code.
set -e

# The goal of the test to see if we can log into ACR
# next, download containers. 

if [ "${ENV}" == "prod" ]
then
  VAULT=opprod-basic
  
  APPID_KEY=cdpx-acr-reader-appid
  APPSECRET_KEY=cdpx-acr-reader-appkey

  ACRs=()
  # ACRs+=("cdpxlinux.azurecr.io")

  # Overlake Release Candidate ACR
  ACRs+=("overlakeacr.azurecr.io")

  MSIACRs=()
  MSIACRs+=("onebranch.azurecr.io")

  containers=()

  # Signing Image

  # 2004 Images from the new pipeline
  containers+=("onebranch.azurecr.io/linux/ubuntu-2004:vprev")
  containers+=("onebranch.azurecr.io/linux/ubuntu-2004:latest")
  containers+=("onebranch.azurecr.io/linux/ubuntu-2004:vnext")
    # 2204 Images from the new pipeline
  containers+=("onebranch.azurecr.io/linux/ubuntu-2204:vnext")
  containers+=("onebranch.azurecr.io/linux/ubuntu-2204:vprev")
  containers+=("onebranch.azurecr.io/linux/ubuntu-2204:latest")
  # 2404 Images from the new pipeline
  containers+=("onebranch.azurecr.io/linux/ubuntu-2404:vnext")
  containers+=("onebranch.azurecr.io/linux/ubuntu-2404:vprev")
  containers+=("onebranch.azurecr.io/linux/ubuntu-2404:latest")
  # RockyLinux Images from the new pipeline
  containers+=("onebranch.azurecr.io/linux/rockylinux:vprev")
  containers+=("onebranch.azurecr.io/linux/rockylinux:latest")
  containers+=("onebranch.azurecr.io/linux/rockylinux:vnext")
  # DebianLinux Images from the new pipeline
  containers+=("onebranch.azurecr.io/linux/debianlinux:vprev")
  containers+=("onebranch.azurecr.io/linux/debianlinux:latest")
  containers+=("onebranch.azurecr.io/linux/debianlinux:vnext")

  # Mariner 2.0 multi-architecture golden image
  containers+=("onebranch.azurecr.io/public/onebranch/cbl-mariner/build:2.0")
  containers+=("onebranch.azurecr.io/public/onebranch/cbl-mariner/build:vnext")
  containers+=("onebranch.azurecr.io/public/onebranch/cbl-mariner/build:vprev")

  # AzLinux 3.0 multi-architecture golden image
  containers+=("onebranch.azurecr.io/public/onebranch/azurelinux/build:3.0")
  containers+=("onebranch.azurecr.io/public/onebranch/azurelinux/build:vnext")
  containers+=("onebranch.azurecr.io/public/onebranch/azurelinux/build:vprev")

  # 25.1 Overlake images
  containers+=("overlake.azurecr.io/official/release/es.overlake.2008.8.24011801:25.1")

  # 25.2 Overlake images
  containers+=("overlake.azurecr.io/official/release/es.overlake.2008.8.24011801:25.2")
else
  VAULT=pipeline-image-kv-dev                     

  APPID_KEY=cdpx-acr-writer-appid-ame
  APPSECRET_KEY=cdpx-acr-writer-appkey-ame

  ACRs=()
  ACRs+=("IBDevACR.azurecr.io")
  ACRs+=("IBDevACR.azurecr.io")

  containers=()
fi

echo "ENV: ${ENV}"
echo "SUB: ${SUB}"
echo "VAULT: ${VAULT}"
echo "APPID_KEY: ${APPID_KEY}"
echo "APPSECRET_KEY: ${APPSECRET_KEY}"
echo "ACRs: ${ACRs[*]}"
echo "Containers: ${containers[*]}"


echo "****** START wait 5 min to attach MSI *******"
date
sleep 5m
date
echo "****** END wait 5 min to attach MSI *******"

i=1
while [ $i -lt 16 ]
do
  echo "  "
  az login --identity
  if [ $? -eq 0 ]
  then
    echo "az login succeeded on attempt ${i}"
    break
  else
    echo "az loging failed on attempt ${i}"
    i=$(($i+1))
    sleep 2
  fi
done

APPID=$(az keyvault secret show --vault-name "${VAULT}" --name "${APPID_KEY}" --query value -o tsv)
APPSECRET=$(az keyvault secret show --vault-name "${VAULT}" --name "${APPSECRET_KEY}" --query value -o tsv)

echo "Login to ACRs via App Token: ${ACRs[*]}"

for ACRNAME in ${ACRs[*]}
do
  i=1
  while [ $i -lt 16 ]
  do
    docker login ${ACRNAME} -u "${APPID}" -p ${APPSECRET}
    if [ $? -eq 0 ]
    then
      echo "docker login to ${ACRNAME} succeeded on attempt ${i}"
      break
    else
      echo "docker login to ${ACRNAME} failed on attempt ${i}"
      i=$(($i+1))
      sleep 2
    fi
  done
done

echo "Login to ACRs via MSI: ${MSIACRs[*]}"

for ACRNAME in ${MSIACRs[*]}
do
  i=1
  while [ $i -lt 16 ]
  do
    az login --identity
    az acr login --name ${ACRNAME}
    if [ $? -eq 0 ]
    then
      echo "docker login to ${ACRNAME} succeeded on attempt ${i}"
      break
    else
      echo "docker login to ${ACRNAME} failed on attempt ${i}"
      i=$(($i+1))
      sleep 2
    fi
  done
done

# Login to Overlake prod ACR in specified subscription
az account set --subscription "e6a85248-9279-4b80-a2f4-2b581f90a262"
az login --identity
az acr login --name "overlake.azurecr.io"

echo "Download containers: ${containers[*]}"

for f in ${containers[*]}
do
  echo "Processing $f"
  docker pull $f

  if [ $? -eq 0 ]
  then
    echo "docker pull succeeded"
  else
    echo "docker pull failed"
    exit 1
  fi
done

exit 0
