#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

stdin=$(jq .)

hosts=$(echo "$stdin" | jq -r .hosts)
private_key=$(echo "$stdin" | jq -r .private_key)
public_key=$(echo "$stdin" | jq -r .public_key)
node_token=$(echo "$stdin" | jq -r .node_token)
k3s_loadbalancer_url=$(echo "$stdin" | jq -r .k3s_loadbalancer_url)
ansible_user=$(echo "$stdin" | jq -r .ansible_user)

ANSIBLE_STDOUT_CALLBACK=json ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key "$private_key" -e "pub_key='$public_key' node_token='$node_token' k3s_url='$k3s_loadbalancer_url'" -u "$ansible_user" -i "$hosts" k3s-worker-setup.yaml |& tee k3s-worker-ansible-deployment.log | jq '[leaf_paths as $path | {"key": $path | join("."), "value": getpath($path) | tostring}] | from_entries'