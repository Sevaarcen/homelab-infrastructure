#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

stdin=$(jq .)

hosts=$(echo "$stdin" | jq -r .hosts)
private_key=$(echo "$stdin" | jq -r .private_key)
public_key=$(echo "$stdin" | jq -r .public_key)
ansible_user=$(echo "$stdin" | jq -r .ansible_user)

ANSIBLE_STDOUT_CALLBACK=json ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key "$private_key" -e "pub_key='$public_key'" -u "$ansible_user" -i "$hosts" ./ansible-playbooks/final-setup-tasks.yaml |& tee ./logs/k3s-final-deployment-tasks.log | jq '[leaf_paths as $path | {"key": $path | join("."), "value": getpath($path) | tostring}] | from_entries'