#!/bin/bash

printf "Creating Ubuntu Base USB Provisioner...\n\n"

# Function for checking if a required package is installed,
# prompting the user to install it if not or to skip
# installation if desired, which results in aborting the
# creation of the provisioner.
check_package() {
  local package=$1
  if ! dpkg -s $package &> /dev/null; then
    read -p "Package $package not installed but is required. Install now? [Y/n] " choice
    case "$choice" in
      [Yy]*|"") sudo apt-get install -y $package ;;
      [Nn]*) echo "Required package will not be installed.  Aborting creation of provisioner..." && exit 1;;
      *) echo "Invalid input. Aborting creation of provisioner..." && exit 1;;
    esac
  fi
}

# Ensure required packages are installed.
packages=("util-linux" "coreutils" "pigz")
for package in "${packages[@]}"; do
  check_package $package
done

# Ensure input directory exists.
mkdir -p input

# Print the name of the USB device, if connected.
printf "Currently connected devices:\n\n"
lsblk | grep -v ^loop | grep -v ^$'\u251C' | grep -v ^$'\u2514'

# Install the community.general modules.
printf "Ensuring Ansible dependencies are installed...\n"
ansible-galaxy collection install community.general 1> /dev/null || echo "Ansible dependencies could not be installed!" || return
printf "Ansible dependencies are installed, running playbook...\n\n"

# Run the playbook.
cd .ansible || return
export ANSIBLE_LOCALHOST_WARNING=false
ansible-playbook -K -i .inventory.yaml provision_usb.yaml
cd ..
