resource "proxmox_vm_qemu" "k3os-controller" {
    count = length(var.controller_nodes)
    name = format("k3os-controller-%02d", count.index+1)

    target_node = var.controller_nodes[count.index]

    clone = var.template_name

    agent = 1
    os_type = "cloud-init"

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

    ipconfig0 = format("gw=192.168.1.1,ip=192.168.1.%02d/24", 30 + count.index+1)
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

resource "null_resource" "k3s_controller_deployment" {
    depends_on = [proxmox_vm_qemu.k3os-controller]
}

data "external" "k3s_controller_provision_ansible" {
    program = ["bash", "./k3s-controller-provision-ansible.sh"]

    query = {
        hosts = "${join(",", [for vm in proxmox_vm_qemu.k3os-controller: vm.default_ipv4_address])},"
        private_key = var.ssh_private_key
        public_key = var.ssh_public_key
        datastore_endpoint = var.datastore_uri
        ansible_user = var.ci_user

        # This is not used, but ensures that the read will be deferred until
        # after the deployment is done.
        deployment = null_resource.k3s_controller_deployment.id
    }
}