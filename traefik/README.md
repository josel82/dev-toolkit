# Traefik Docker Reverse Proxy with Let's Encrypt

This repository provides a robust and scalable solution for setting up a **reverse proxy with Traefik** using the **Docker provider**. It's designed to automatically forward traffic to your self-hosted applications while seamlessly providing **Let's Encrypt TLS certificates** for secure communication.

## Key Features

* **Dynamic Configuration:** Traefik automatically discovers and configures routes for your Docker containers based on labels.
* **Automatic TLS:** Integrates with Let's Encrypt to provide free, automatic SSL/TLS certificates.
* **Simplified Deployment:** Leverages Docker Compose for easy setup and management.
* **Network Isolation:** Requires application containers and Traefik to be on the same Docker network for seamless communication.

## How It Works

Traefik acts as the entry point for all incoming web traffic. When a request arrives, Traefik inspects the **labels** on your running Docker containers to determine which service should receive the traffic. It then forwards the request to the appropriate container. For secure connections, Traefik handles the TLS termination and certificate management with Let's Encrypt.

### Prerequisites

* **Docker** and **Docker Compose** installed.
* A **domain name** configured to point to your server's IP address.
* For this example I am using **cloudflare** as **domain registrar** and as **provider** for dnsChallenge.

### Example: Exposing an Nginx Server

To make an Nginx web server accessible via Traefik, you need to define specific labels in its `compose.yml` file. These labels instruct Traefik on how to route traffic to your Nginx container.

This example assumes that an **external Docker network** named `proxy` has previously been created. Your application's `compose.yml` would then connect to this network.

**`web-server/compose.yml`**

```yaml
services:
    nginx:
        image: "nginx"
        container_name: "nginx"
        labels:
        # Enable Traefik for this service
        - "traefik.enable=true"
        # Define a router named 'nginx' for secure sets the entry point configured int Traefik 'websecure'
        - "traefik.http.routers.nginx.entrypoints=websecure"
        # Route traffic to this container based on the Host header
        - "traefik.http.routers.nginx.rule=Host(`nginx.example.com`)"
        # Enable TLS for this router (required for HTTPS)
        - "traefik.http.routers.nginx.tls=true"
        # Specify the certificate resolver configured in Traefik (e.g., Let's Encrypt 'production')
        - "traefik.http.routers.nginx.tls.certresolver=production"
        # Tell Traefik which port the Nginx container is listening on internally
        - "traefik.http.services.nginx.loadbalancer.server.port=80"
        networks:
        - proxy # Connects this service to the shared 'proxy' network with Traefik
        restart: unless-stopped # Ensures the container restarts automatically
networks:
    proxy:
        external: true # Indicates that the 'proxy' network is managed externally by Traefik

```