#!/bin/bash
# This script serves as the entrypoint for all customization scripts
# This file is downloaded directly from storage and executed
# The only other file we download is the archived contents of customizations/linux

# Temporarily allow failures so the script doesnt exit if this fails
set +e

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "         Removing unattended upgraded package"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"

sudo tdnf update -y

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "         Disabling app armor"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"

# app armor is not mentioned as a azsecpack requirment and is likely providing redundant functionality
# disable the service here to prevent extra overhead on file access
echo "--- Checking App Armor status ---"
sudo systemctl status apparmor --no-pager --full
echo "--- Stopping App Armor ---"
sudo systemctl stop apparmor
echo "--- Disable App Armor ---"
sudo systemctl disable apparmor

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "         Performing Initial package upgrade"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"

## Update what came with the base image
## Base image could be a bit out of date, but everything else we install should be latest
## If we update what's baked into the image first,
##  the upgrade should be faster compared to doing it at the end.
while :
do
    # Temporarily allow failures so the script doesnt exit if this fails
    set +e

    sudo tdnf update -y

    if [ $? -ne 0 ] 
    then 
        echo "-----------------------------------------------------"
        echo "         FAILED tdnf update, retrying ..."
        echo "-----------------------------------------------------"
        continue
    fi
    
    sudo tdnf upgrade -y
    if [ $? -ne 0 ] 
    then 
        echo "-----------------------------------------------------"
        echo "         FAILED tdnf upgrade, retrying ..."
        echo "-----------------------------------------------------"
        continue
    fi

    # All good, breaking retry loop
    break
done


# Modify the default behavior to fail if an invoked command returns a non 0 exit code.
# Reset this back after the initial success
set -e

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "           Starting Linux Customization"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"

# list the contents of this directory
ls -a /tmp/

# Create a temp directory to store the unarchived customization scripts
# After creating the directory we change into it, tar will by default place unarchived contents into the current directory
mkdir -p /tmp/AIB/
cd /tmp/AIB/

# Perform the archive extraction
tar xvf /tmp/linux.tar

ls -a

# Update permissions on these scripts to ensure we can execute them
sudo chmod -R +x /tmp/AIB

# Invoke required customization scripts
echo "Invoke required customization scripts"

echo "Start execution initDirectories.sh"
/tmp/AIB/initDirectories.sh
echo "initDirectories.sh completed execution"

echo "Start execution 050_configure-limits.sh"
/tmp/AIB/050_configure-limits.sh
echo "050_configure-limits.sh completed execution"

echo "Start execution linux-mariner-build-tools-amd64.sh"
/tmp/AIB/linux-mariner-build-tools-amd64.sh
echo "linux-mariner-build-tools-amd64.sh completed execution"


echo "Start execution block-container-to-imds-azLinux.sh"
/tmp/AIB/block-container-to-imds-azLinux.sh
echo "block-container-to-imds-azLinux.sh completed execution"

echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "           Ending Mariner Linux Customization"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"
echo "-----------------------------------------------------"