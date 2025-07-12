terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}


provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = var.api_url
}


resource "proxmox_vm_qemu" "nodes" {
    count = var.node_count
    name = "node${count.index + 1}"
    vmid = 700 + count.index + 1
    desc = "Kubernetes controller"
    target_node = "pve1"
    # The template name to clone this vm from
    clone = "ubuntu-24.10-template"
    # Activate QEMU agent for this VM
    agent = 1
    os_type = "cloud-init"
    cores = 2
    sockets = 1
    vcpus = 0
    cpu = "host"
    memory = 2048
    scsihw = "virtio-scsi-single"

    # Disk setup
    disks {
        ide {
            ide3 {
                cloudinit {
                    storage = "pool1"
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size            = 32
                    iothread        = true
                    storage         = "pool1"
                    format          = "raw"
                    replicate       = true
                }
            }
        }
    }
    # Display device
    vga {
        type = "std"
        memory = 4
    }
    # Network Interface 
    network {
        model = "virtio"
        bridge = "vmbr1"
    }

    boot = "order=scsi0"
    ipconfig0 = "ip=10.1.20.3${count.index + 5}/24,gw=10.1.20.1"
    nameserver = "1.1.1.1,8.8.8.8"

    # Serial console
    serial {
        id = 0
        type = "socket"
    }

    #Cloud-init user credentials
    ciuser = var.ci_user
    sshkeys = join("\n",var.sshkeys)
}