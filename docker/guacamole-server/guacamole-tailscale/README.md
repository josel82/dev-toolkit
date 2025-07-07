# Guacamole with Tailscale Integration

This guide explains how to deploy Apache Guacamole with secure access via **Tailscale**. It includes configuration steps for integrating your Guacamole container with your Tailscale network using OAuth authentication and tagging.

---

## Requirements

- A **Tailscale** account
- Access to the **Tailscale Admin Console**
- A generated **OAuth token** (details below)
- Docker and Docker Compose installed on your host

**Note:** Some configuration in the Tailscale admin console is required **prior** to deployment.

---

## 1. Tailscale Configuration

### Step 1: Edit the ACL File

1. Log in to the [Tailscale Admin Console](https://login.tailscale.com/).
2. Navigate to **Access Controls**.
3. Under `"groups"`, create a group and add your user if not already present:
```json
"groups": {
  "group:admin": ["my_user@example.com"]
}
```
4. Next, under "tagOwners", define a tag and associate it with your group:
```json
"tagOwners": {
  "tag:management":     ["autogroup:admin"],
  "tag:prod":           ["autogroup:admin"],
  "tag:guacamole-node": ["group:admin"]
}
```
This allows your user (via group membership) to assign the tag:guacamole-node tag to nodes like your Guacamole container.

### Step 2: Generate an OAuth Token
1. Go to Settings > OAuth Clients in the Tailscale admin console.
2. Click Generate OAuth Client.
Use the following scopes for this deployment:
- Devices > Core > Read/Write (to assign the guacamole-node tag)
- Keys > Auth Keys > Read/Write
    Copy the generated token — you’ll need it in the next step.


### Step 3: Configure Environment Variables
On your host machine, navigate to the directory containing your docker-compose.yml file and create (or update) a .env file with the following:
```env
OAUTH_KEY=paste-your-token-here
MYSQL_PASSWORD=your_db_password
MYSQL_ROOT_PASSWORD=your_root_password
```
**Keep this file secure** — your OAuth token grants privileged access to your Tailnet.


## 2. Deploy the Container Stack
Start the deployment with Docker Compose:
```bash
docker compose up -d
```

# Notes
Instructions on how to configure Guacamole on the main page

