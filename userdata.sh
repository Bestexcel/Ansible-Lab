
#!/bin/bash
sudo apt-get update -y   # Update the package list and install necessary dependencies 
sudo apt-get install software-properties-common -y  # Install software-properties-common to manage repositories
sudo add-apt-repository --yes --update ppa:ansible/ansible  # Add the Ansible PPA (Personal Package Archive) and update repositories
sudo apt-get install ansible -y  # Install Ansible

# Set the hostname of the instance
sudo hostnamectl set-hostname ansible

# Optionally, restart the instance to apply changes (useful for some configurations)
# reboot








