resource "proxmox_vm_qemu" "k3os-worker" {
    count = length(var.worker_nodes)
    name = format("k3s-worker-%02d", count.index+1)

    target_node = var.worker_nodes[count.index]

    clone = var.template_name

    agent = 1
    os_type = "cloud-init"

    ciuser = var.ci_user
    sshkeys = var.ssh_public_key

    sockets = 1
    cores = 4
    memory = 2048
    balloon = 1024
    
    scsihw = "virtio-scsi-pci"
    disk {
        type = "scsi"
        storage = "local-lvm"
        size = "20G"
    }

    ipconfig0 = format("gw=192.168.1.1,ip=192.168.1.%02d/24", 40 + count.index+1)
    network {
        model = "virtio"
        bridge = "vmbr0"
    }

    lifecycle {
        ignore_changes = all
    }

    provisioner "remote-exec" {
        inline = [
            "cloud-init status --wait &> /dev/null; echo Done waiting for cloud-init to finish",  # Wait for cloud-init to actually finish
            "sudo dhclient -x eth0; sudo dhclient eth0",  # Re-do DHCP without releasing lease, to fix /etc/resolv.conf not actually updating
            "sudo dnf update -y &> /dev/null",  # Update packages
            "sudo dnf install python3 -y &> /dev/null",  # Install python3 (for use by ansible)
            "echo Finished remote exec provisioning"
        ]

        connection {
            host = self.default_ipv4_address
            type = "ssh"
            user = var.ci_user
            private_key = file(var.ssh_private_key)
        }
    }
}

data "external" "k3s_worker_provision_ansible" {
    program = ["bash", "./ansible-run-scripts/k3s-worker-provision-ansible.sh"]

    query = {
        hosts = "${join(",", [for vm in proxmox_vm_qemu.k3os-worker: vm.default_ipv4_address])},"
        private_key = var.ssh_private_key
        public_key = var.ssh_public_key
        k3s_loadbalancer_url = var.k3s_loadbalancer_url
        ansible_user = var.ci_user
        node_token = trimspace(base64decode(data.external.k3s_controller_provision_ansible.result["plays.0.tasks.5.hosts.192.168.1.31.content"]))
    }
}