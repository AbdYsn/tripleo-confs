#!/bin/bash
set -eux
set -o pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo rm -fr /var/www/html/*
sudo yum -y install wget createrepo httpd
sudo systemctl is-active --quiet httpd || sudo systemctl start httpd
sudo systemctl enable httpd

sudo cp -r /home/stack/RPMS /var/www/html/RPMS
cd /var/www/html/
sudo createrepo .
if [ ! -f /etc/yum.repos.d/local-repo.repo ]; then
    sudo tee -a /etc/yum.repos.d/local-repo.repo << EOF
[local-repo]
name=local-repo
mirrorlist=file:///etc/yum.repos.d/local-repo
enabled=1
gpgcheck=0
priority=1
EOF
fi
if [ ! -f /etc/yum.repos.d/local-repo ]; then
    sudo tee -a /etc/yum.repos.d/local-repo << EOF
http://192.168.24.1/
http://127.0.0.1/
EOF
fi
sudo yum clean all
sudo rm -rf /var/cache/yum
sudo yum list \*openvswitch\*
