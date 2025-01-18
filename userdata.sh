
#!/bin/bash
sudo apt-get update
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:ansible/ansible -y
sudo apt-get update
sudo apt-get install ansible -y