terraform {
    required_providers {
        proxmox = {
            source = "Telmate/proxmox"
            version = "2.9.4"
        }
    }
}

provider "proxmox" {
    pm_api_url = format("https://%s:8006/api2/json", var.proxmox_host)
    pm_api_token_id = var.proxmox_token_id
    pm_api_token_secret = var.proxmox_token_secret
    pm_tls_insecure = true

    # for debugging / development
    pm_log_enable = true
    pm_log_file   = "./logs/terraform-plugin-proxmox.log"
    pm_debug      = true
    pm_log_levels = {
        _default    = "debug"
        _capturelog = ""
    }
}

#
#  Pre-deployment tasks
#
resource "null_resource" "remove_prexisting_cluster_token" {
    provisioner "local-exec" {
        #command = "psql ${var.datastore_uri} -c \"delete from kine where name like '/bootstrap/%'\""
        command = "psql ${var.datastore_uri} -c \"delete from kine\""
    }
}


#
#  Post-deployment tasks
#
data "external" "get-joined-node-info" {
    program = ["bash", "./ansible-run-scripts/k3s-deployment-finalize.sh"]

    query = {
        hosts = "${join(",", [for vm in proxmox_vm_qemu.k3os-controller: vm.default_ipv4_address])},"
        private_key = var.ssh_private_key
        public_key = var.ssh_public_key
        ansible_user = var.ci_user

        # This is not used, but ensures that the read will be deferred until
        # after the deployment is done.
        deployment = data.external.k3s_worker_provision_ansible.result["plays.0.play.name"]
    }
}

# Then restart each VM to make sure that Traefik is actually instantiated properly, as it errors out otherwise on OL8...
resource "null_resource" "restart_controllers_and_workers" {
    for_each = merge({
                    for vm in proxmox_vm_qemu.k3os-controller:
                        vm.name => vm.default_ipv4_address       
                }, {
                    for vm in proxmox_vm_qemu.k3os-worker:
                        vm.name => vm.default_ipv4_address   
                })

    provisioner "remote-exec" {
        inline = [
            "sudo shutdown -r now"
        ]

        on_failure = continue  # remote-exec will exit early b/c of disconnect, but that's expected and should be ignored.

        connection {
            host = each.value
            type = "ssh"
            user = var.ci_user
            private_key = file(var.ssh_private_key)
        }
    }
}