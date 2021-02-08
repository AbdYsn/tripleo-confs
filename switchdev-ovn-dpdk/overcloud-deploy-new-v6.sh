#!/bin/bash

set -ux


### --start_docs
## Deploying the overcloud
## =======================

## Prepare Your Environment
## ------------------------

## * Source in the undercloud credentials.
## ::

source /home/stack/stackrc

### --stop_docs
# Wait until there are hypervisors available.
while true; do
    count=$(openstack hypervisor stats show -c count -f value)
    if [ $count -gt 0 ]; then
        break
    fi
done

### --start_docs


## * Deploy the overcloud!
## ::
openstack overcloud deploy\
    --templates /usr/share/openstack-tripleo-heat-templates \
    --libvirt-type kvm \
    -r /home/stack/roles_data.yaml\
    -n /home/stack/switchdev-ovn-dpdk/network_data-v6-tenant\
    --timeout 240 \
    -e /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/podman.yaml\
    --validation-warnings-fatal \
    -e /home/stack/switchdev-ovn-dpdk/cloud-names.yaml\
    -e /home/stack/overcloud_storage_params.yaml\
    -e /home/stack/containers-prepare-parameter.yaml\
    -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
    -e /home/stack/network-environment.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/net-single-nic-with-vlans.yaml\
    -e /home/stack/overcloud-selinux-config.yaml\
    -e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovn-standalone.yaml\
    -e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovn-dpdk.yaml\
    -e /home/stack/switchdev-ovn-dpdk/nic_configs/network-dpdk.yaml\
    -e /home/stack/switchdev-ovn-dpdk/ovs-hw-offload.yaml\
    "$@" && status_code=0 || status_code=$?

### --stop_docs

# Check if the deployment has started. If not, exit gracefully. If yes, check for errors.
if ! openstack stack list | grep -q overcloud; then
    echo "overcloud deployment not started. Check the deploy configurations"
    exit 1

    # We don't always get a useful error code from the openstack deploy command,
    # so check `openstack stack list` for a CREATE_COMPLETE or an UPDATE_COMPLETE
    # status.
elif ! openstack stack list | grep -Eq '(CREATE|UPDATE)_COMPLETE'; then
        # get the failures list
    openstack stack failures list overcloud --long > /home/stack/failed_deployment_list.log || true
    
    # get any puppet related errors
    for failed in $(openstack stack resource list \
        --nested-depth 5 overcloud | grep FAILED |
        grep 'StructuredDeployment ' | cut -d '|' -f3)
    do
    echo "openstack software deployment show output for deployment: $failed" >> /home/stack/failed_deployments.log
    echo "######################################################" >> /home/stack/failed_deployments.log
    openstack software deployment show $failed >> /home/stack/failed_deployments.log
    echo "######################################################" >> /home/stack/failed_deployments.log
    echo "puppet standard error for deployment: $failed" >> /home/stack/failed_deployments.log
    echo "######################################################" >> /home/stack/failed_deployments.log
    # the sed part removes color codes from the text
    openstack software deployment show $failed -f json |
        jq -r .output_values.deploy_stderr |
        sed -r "s:\x1B\[[0-9;]*[mK]::g" >> /home/stack/failed_deployments.log
    echo "######################################################" >> /home/stack/failed_deployments.log
    # We need to exit with 1 because of the above || true
    done
    exit 1
fi
exit $status_code
