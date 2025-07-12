# Telmate/Proxmox local install

Clone the provider repository

```bash
git clone https://github.com/Telmate/terraform-provider-proxmox.git
```

This provider has a known bug after Proxmox latest version upgrades were the provider crashes due to variable type mismatch. The following is a workaround for this issue.

## Patch Proxmox API Module

This module is a dependency of telmate/proxmox provider.

Clone the repository:

```bash
git clone [https://github.com/Telmate/proxmox-api-go.git](https://github.com/Telmate/proxmox-api-go.git)
cd proxmox-api-go
```

Edit the `(QemuMemory) mapToSDK(params map[string]interface{})` **** function inside `config_qemu_memory.go`

```go
func (QemuMemory) mapToSDK(params map[string]interface{}) *QemuMemory {
	config := QemuMemory{}

	if v, isSet := params["memory"]; isSet {
		if tmp, err := safeParseUint(v); err == nil {
			tmpIntermediate := QemuMemoryCapacity(tmp)
			config.CapacityMiB = &tmpIntermediate
		}
	}

	if v, isSet := params["balloon"]; isSet {
		if tmp, err := safeParseUint(v); err == nil {
			tmpIntermediate := QemuMemoryBalloonCapacity(tmp)
			config.MinimumCapacityMiB = &tmpIntermediate
		}
	}

	if v, isSet := params["shares"]; isSet {
		if tmp, err := safeParseUint(v); err == nil {
			tmpIntermediate := QemuMemoryShares(tmp)
			config.Shares = &tmpIntermediate
		}
	}

	return &config
}

```

Add the following helper function inside `internal/util/util.go`

```go
func safeParseUint(v interface{}) (uint64, error) {
	switch val := v.(type) {
	case float64:
		return uint64(val), nil
	case int:
		return uint64(val), nil
	case string:
		return strconv.ParseUint(val, 10, 64)
	default:
		return 0, fmt.Errorf("unsupported type for parseUint: %T", v)
	}
}

```

## Build the provider

cd into `terraform-provider-proxmox` directory, and run:

```bash
go build -o terraform-provider-proxmox
```

## Install the plugin locally

```bash
mkdir -p ~/.terraform.d/plugins/local/proxmox/proxmox/2.9.14/darwin_arm64
cp terraform-provider-proxmox ~/.terraform.d/plugins/local/proxmox/proxmox/2.9.14/darwin_arm64/

```

Update Terraform Configuration file

```
terraform {
  required_providers {
    proxmox = {
      source  = "local/proxmox/proxmox"
      version = "2.9.14"
    }
  }
}
```