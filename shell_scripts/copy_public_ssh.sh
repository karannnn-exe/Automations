# This script copies public ssh key to remote hosts #
# We can run this script from AWS SSM or Ansible #

#!/bin/bash -e

# Storing & printing the hostname of server #
host=$(echo $HOSTNAME)
echo "Script is running on $host"

# Public key to copy #
public_key="ssh-xxxxxxxx"

# Get the OS name & displaying #
os_name="$(grep -iw '^name' /etc/os-release | awk -F'=' '{print $2}' | tr -d '"')"
echo $os_name

# Path to the authorized_keys file #
if [[ "$os_name" == "Ubuntu" ]]; then
  authorized_keys_file="/home/ubuntu/.ssh/authorized_keys"
elif [[ "$os_name" == "Amazon Linux" ]]; then
  authorized_keys_file="/home/ec2-user/.ssh/authorized_keys"
else
  echo "Error: This script only supports Ubuntu and Amazon Linux EC2 instances."
  exit 1
fi

# Checking if the key is already there #
if grep -q "$public_key" "$authorized_keys_file"; then
  echo "Public key is already in the authorized_keys file. Nothing to do. Exiting Gracefully"
  exit 0
fi

# Copying the public ssh key to the remote host #
echo -e "\n$public_key" >> "$authorized_keys_file"

# Check if the key was actually copied #
if grep -q "$public_key" "$authorized_keys_file"; then
  echo "Public key successfully copied to $host"
  exit 0
else
  echo "Error: Public key not copied to $host."
  exit 10
fi
