
terraform {
    required_providers {
        proxmox = {
            source  = "local/proxmox/proxmox"
            version = "2.9.14"
        }
    }
}

provider "proxmox" {
    pm_api_url          = var.api_url
    pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "node1" {
    name                = "node1"
    target_node         = var.node
    clone               = "ubuntu-22.04-template"
    full_clone          = true
    memory              = 2048

    cpu{
        cores = 2
        sockets = 1
    }

    disk {
        slot            = "scsi0"
        size            = "32G"
        type            = "disk"
        storage         = "pool1"
        discard         = false
        passthrough     = false
    }

    network {
        id        = 0
        model     = "virtio"
        bridge    = "vmbr1"
        firewall  = false
        link_down = false
    }
}