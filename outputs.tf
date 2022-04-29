output "controller_ip_addresses" {
    value = {
        for vm in proxmox_vm_qemu.k3os-controller:
            vm.name => vm.default_ipv4_address
    }
}

output "worker_ip_addresses" {
    value = {
        for vm in proxmox_vm_qemu.k3os-worker:
            vm.name => vm.default_ipv4_address
    }
}

output "node-token" {
    //value = data.external.k3s_controller_provision_ansible.result
    value = trimspace(base64decode(data.external.k3s_controller_provision_ansible.result["plays.0.tasks.4.hosts.192.168.1.31.content"]))
}

output "dashboard-admin-user-token" {
    //value = data.external.get-joined-node-info.result
    value = try(data.external.get-joined-node-info.result["plays.0.tasks.7.hosts.192.168.1.31.stdout"], data.external.get-joined-node-info.result["plays.0.tasks.2.hosts.192.168.1.31.stdout"])
}