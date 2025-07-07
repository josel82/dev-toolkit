# Docker Install Script

This script installs Docker on **Ubuntu Server** only.

For other Linux distributions, please refer to the [official Docker installation guide](https://docs.docker.com/engine/install/).

---

## How to Use

### 1. Clone the Repository

```bash
git clone https://github.com/josel82/docker-install.git
```
### 2. Navigate to the Repository Directory
```bash
cd docker-install
```
### 3. Make the Script Executable
```bash
sudo chmod +x install.sh
```
### 4. Run the Script as Root
```bash
sudo ./install.sh
```
Note: This script must be run with root privileges (sudo).

What the Script Does
- Updates the system package index.
- Installs required dependencies.
- Adds Docker’s official GPG key and repository.
- Installs Docker Engine and CLI.
- Enables and starts the Docker service.

Once completed, you can verify the installation with:
```bash
docker --version
```