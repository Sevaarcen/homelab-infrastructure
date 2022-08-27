# Homelab K3S Cluster using IaC

A set of terraform modules integrating with bash and ansible to automatically deploy and configure a high-availability kubernetes cluster on Proxmox.


## Requirements

* bash
* ansible
* ansible json callback
* terraform (obviously)
* Proxmox
* cloud-init enabled Linux distro of choice