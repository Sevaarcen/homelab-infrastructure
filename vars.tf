variable "proxmox_host" {
    description = "Network fqdn/IP of main proxmox server to deploy on"
    type = string
}

variable "proxmox_token_id" {
    description = "Proxmox token user, e.g username@auth!token-name"
    type = string
}

variable "proxmox_token_secret" {
    description = "Proxmox token secret, given by Proxmox"
    type = string
    sensitive = true
}

variable "ci_user" {
    description = "Username for CloudInit"
    type = string
}

variable "ssh_public_key" {
    description = "SSH public key"
    type = string
}

variable "ssh_private_key" {
    description = "Filepath for SSH private key"
    type = string
}

variable "template_name" {
    description = "Name of cloud-init enabled template used to deploy VMs"
    default = "ol8-ci-template"
}

variable "datastore_uri" {
    description = "Connection string for K3S datastore endpoint"
    type = string
    #sensitive = true
}

variable "controller_nodes" {
    description = "List of node names to deploy controller VMs on"
    type = list(string)
}

variable "loadbalancer_nodes" {
    description = "List of node names to deploy nginx loadbalancer VMs to interface to the K3S Control Plane"
    type = list(string)
}

variable "k3s_loadbalancer_url" {
    description = "URL of loadbalancer used for control plane"
    type = string
    default = "https://loadbalancer:443"
}

variable "worker_nodes" {
    description = "List of node names to deploy worker VMs on"
    type = list(string)
}