# Apache Guacamole Deployment Guide
Credits to:
- [Sonoran Tech](https://www.youtube.com/watch?v=PEUO2cCICS4)
- [Alex from Tailscale](https://www.youtube.com/watch?v=YTjYXii4WzI&t=514s)

The following steps walk you through setting up Guacamole with docker compose. Instructions on how to integrate Tailscale with this project in `guacamole-tailscale` directory.

## Requirements
This deployment requires Docker Engine and Docker Compose installed on the host server.
For installation instructions, visit the official [Docker documentation](https://docs.docker.com/engine/install/).
Or visit [get.docker.com](https://get.docker.com/) and download their Docker install script

## Deployment Steps
1. Clone this Repository
```bash
git clone https://github.com/josel82/guacamole-deployment-guide.git
cd guacamole-deployment-guide/guacamole
```
**Note:** Tailscale integration on `guacamole-deployment-guide/guacamole-tailscale`

2. Configure Environment
Edit the `docker-compose.yml` file and replace the default database user and root passwords with secure credentials.

3. Launch the Containers
Run the following command:
```bash
docker compose up -d
```
Alternatively, you can deploy the stack via Portainer, if installed.

Once the containers are running, proceed to initialize the database.

## MySQL Database Setup
1. Access the Database Container
From the host server:
```bash
docker exec -it guac-sql /bin/bash
```
Or use Portainer to access the terminal.

Then start the MySQL CLI:
```bash
mysql -u root -p
```
Enter the root password when prompted.

2. Create the Database
```sql
CREATE DATABASE guacamole_db;
```

3. Create the Database User

```sql
CREATE USER 'guacamole_user'@'%' IDENTIFIED BY 'your_secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON guacamole_db.* TO 'guacamole_user'@'%';
FLUSH PRIVILEGES;
```

Optional: Verify the user creation


```sql
SELECT User FROM mysql.user;
```
Leave this terminal open — you'll return to it shortly.

4. Initialize the Guacamole Schema
On the host machine, generate the initialization SQL:
```bash
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
```
Copy the file to the guac-sql container:
```bash
docker cp ./initdb.sql guac-sql:/initdb.sql
```
Return to the MySQL shell inside the container and run:

```sql
USE guacamole_db;
SOURCE initdb.sql;
```

## Accessing Guacamole
Once setup is complete, open your browser and navigate to:
`http://<your-server-ip>:8080/guacamole`
You should now see the Guacamole login interface.