/*
resource "proxmox_vm_qemu" "loadbalancer" {
    #depends_on = [proxmox_vm_qemu.k3os-controller]

    count = length(var.worker_nodes)
    name = format("k3s-loadbalancer-%02d", count.index+1)

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

    network {
        model = "virtio"
        bridge = "vmbr0"
    }

    provisioner "remote-exec" {
        inline = ["cloud-init status --wait", "sudo dnf update -y", "sudo dnf install python3 -y"]

        connection {
            host = self.default_ipv4_address
            type = "ssh"
            user = var.ci_user
            private_key = file(var.ssh_private_key)
        }
    }

    #provisioner "local-exec" {
    #    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ${var.ssh_private_key} -e 'pub_key=${var.ssh_public_key}, k3s_url=${var.k3s_hostname}, node_token=${}' -u ${var.ci_user} -i '${self.default_ipv4_address},' k3s-worker-setup.yaml"
    #}
}*/


