#!/bin/bash

set -eux
set -o pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d ${SCRIPT_DIR}/overcloud ]; then
    mkdir ${SCRIPT_DIR}/overcloud
else
    rm -fr ${SCRIPT_DIR}/overcloud/* || true
fi
export DIB_YUM_REPO_CONF="/etc/yum.repos.d/*"
export OS_YAML="/usr/share/openstack-tripleo-common/image-yaml/overcloud-images-centos7.yaml"

cp /usr/share/openstack-tripleo-common/image-yaml/overcloud-images.yaml ${SCRIPT_DIR}/
sed -i '/ironic-agent-multipath/a\      - stable-interface-names' ${SCRIPT_DIR}/overcloud-images.yaml
sed -i '/python-psutil/a\      - dpdk' ${SCRIPT_DIR}//overcloud-images.yaml
#sed -i '/python-psutil/a\      - dpdk-tools' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - iproute' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - kernel' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - kernel-headers' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - linux-firmware' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch-devel' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch-ovn-central' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch-ovn-common' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch-ovn-docker' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch-ovn-host' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - openvswitch-ovn-vtep' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - python2-openvswitch' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - rdma-core' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - mstflint' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - gdb' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - vim' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - nvmetcli' ${SCRIPT_DIR}/../templates/overcloud-images.yaml
#sed -i '/python-psutil/a\      - nvme-cli' ${SCRIPT_DIR}/../templates/overcloud-images.yaml

openstack overcloud image build --config-file ${SCRIPT_DIR}/overcloud-images.yaml --config-file ${OS_YAML}   --output-directory ${SCRIPT_DIR}/overcloud/
openstack image delete bm-deploy-kernel bm-deploy-ramdisk overcloud-full overcloud-full-initrd overcloud-full-vmlinuz || true
sudo rm -fr /var/lib/ironic/httpboot/agent.* || true
openstack overcloud image upload --image-path ${SCRIPT_DIR}/overcloud/
