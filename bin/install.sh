#!/bin/bash

echo "Installation des dépendances pour killbit..."

# sudo apt update

sudo apt install -y build-essential
sudo apt install -y g++
sudo apt install -y libcurl4-openssl-dev
sudo apt install -y curl
sudo apt install -y hdparm
sudo apt install -y nvme-cli
sudo apt install -y inxi
sudo apt install -y util-linux
sudo apt install -y coreutils
sudo apt install -y libcpanel-json-xs-perl
sudo apt install -y smartmontools
sudo apt install -y nvme-cli
sudo apt install -y memtester

# nouvelles dépendances
sudo apt install -y upower

