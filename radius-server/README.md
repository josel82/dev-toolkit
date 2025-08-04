# FreeRadius Server

[Documentation](https://wiki.freeradius.org/guide/Getting%20Started#other-resources)

## Installation

### Debian/Ubuntu

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install freeradius -y
```

Running the server in debugging mode:

```bash
freeradius -X
```

## Configuration

### Adding Clients

```bash
sudo nano /etc/freeradius/3.0/clients.conf
```

Edit accordingly for you clients

```
client switch1 {
        ipaddr          = 192.168.122.162
        secret          = radius123
}
```

### Adding Users

Not recommended for production. Use just for testing

```bash
sudo nano /etc/freeradius/3.0/mods-config/files/authorize
```

Edit accordingly for your users:

```
josepadilla    Cleartext-Password := "password123"
               Reply-Message := "Hello, %{User-Name}"
```

### **Connecting FreeRADIUS with MariaDB: A Step-by-Step Guide**

This guide assumes a Debian/Ubuntu-based system for package management and file paths.

**I. Database Setup (MariaDB)**

1. **Install MariaDB Server:**Bash
    
```bash
sudo apt update
sudo apt install mariadb-server mariadb-client
```
    
2. **Secure MariaDB Installation:**Bash
    
```bash
sudo mysql_secure_installation
```
    
    (Follow prompts: set root password, remove anonymous users, disallow remote root login, remove test database, reload privilege tables).
    
3. **Create RADIUS Database:**BashSQL
    
```bash
sudo mysql -u root -p
```
    
    (Enter MariaDB root password)
    
```sql
CREATE DATABASE radius;
EXIT;
```
    
4. **Import FreeRADIUS SQL Schema:**
Locate the `schema.sql` file. It's usually in `/etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql` (path might vary slightly depending on FreeRADIUS version).Bash
    
```bash
sudo mysql -u root -p radius < /etc/freeradius/3.0/mods-config/sql/main/mysql/schema.sql
```
    
5. **Create a Dedicated MariaDB User for FreeRADIUS:**
This user will be used by FreeRADIUS to connect to the `radius` database. For security, give it only the necessary permissions.BashSQL
    
```bash
sudo mysql -u root -p
```
    
```sql
CREATE USER 'freeradius_user'@'localhost' IDENTIFIED BY 'YOUR_FR_DB_PASSWORD';
GRANT ALL PRIVILEGES ON radius.* TO 'freeradius_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```
    
    **IMPORTANT:** Replace `YOUR_FR_DB_PASSWORD` with a strong, unique password.
    

**II. FreeRADIUS Configuration**

1. **Install FreeRADIUS and MySQL/MariaDB Module:**Bash
    
```bash
sudo apt install freeradius freeradius-mysql freeradius-utils
```
    
2. **Configure the SQL Module (`/etc/freeradius/3.0/mods-available/sql`):**
Open the file (e.g., `sudo nano /etc/freeradius/3.0/mods-available/sql`) and edit the `sql {}` block.
    
```
sql {
    driver = "rlm_sql_mysql"
    dialect = "mysql"

    # Connection info:
    server = "localhost"
    port = 3306
    login = "freeradius_user"           # The user you created above
    password = "YOUR_FR_DB_PASSWORD"    # The password for that user
    radius_db = "radius"                # The database name

    # Enable reading of groups and clients from SQL (optional, but good practice)
    read_groups = yes
    read_clients = yes
    client_table = "nas" # Default table for clients

    # Uncomment for debugging SQL queries in debug mode
    # sqltrace = yes
    # logfile = ${logdir}/sqltrace.sql
}
```
    
    **NOTE:** The `login` and `password` here are for the `freeradius_user` you created, not your MariaDB `root` user.
    
3. **Enable the SQL Module:**
Create a symbolic link to activate the module.Bash
    
```bash
sudo ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/
```
    
4. **Configure FreeRADIUS Site (`/etc/freeradius/3.0/sites-enabled/default`):**
Edit the `default` site configuration to use the `sql` module.
    - Find the `authorize {}` section and **add `sql`** before `files` (or wherever you want it to check the database). The order matters:
        
```
authorize {
    # ... other modules ...
    sql
    # files # Keep this if you also want to check /etc/freeradius/3.0/users for users
    # ... other modules ...
}
```
        
    - For accounting (logging sessions), also add `sql` to the `accounting {}` section:
        
```
accounting {
    # ... other modules ...
    sql
    # ... other modules ...
}
```
        
    - For `inner-tunnel` (if using EAP methods like PEAP/TTLS), also uncomment `sql` in `sites-enabled/inner-tunnel`.
5. **Restart FreeRADIUS:**Bash
    
```bash
sudo systemctl restart freeradius
```
    
    Check status: `sudo systemctl status freeradius`
    

**III. Optional: phpMyAdmin Setup for Database Management**

1. **Install phpMyAdmin and PHP extensions:**Bash
    
```bash
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl php-mysql
```
    
    (During installation, select `apache2` as the web server and let `dbconfig-common` configure it).
    
2. **Enable Apache PHP module & phpMyAdmin config:**
(Replace `X.Y` with your PHP version, e.g., `8.2`)Bash
    
```bash
sudo a2enmod phpX.Y
sudo a2enconf phpmyadmin
sudo systemctl restart apache2
```
    
3. **Grant phpMyAdmin User Database Access (if not visible):**
If the `radius` database isn't visible in phpMyAdmin after logging in as `phpmyadmin` (or another user), grant it permissions:BashSQL
    
```bash
sudo mysql -u root -p
```
    
```sql
GRANT ALL PRIVILEGES ON radius.* TO 'phpmyadmin'@'localhost'; # Or the user you login with
FLUSH PRIVILEGES;
EXIT;
```
    
4. **Access phpMyAdmin:**
Open your web browser and go to `http://YOUR_SERVER_IP/phpmyadmin`.
    - **Brave Browser Issue:** If phpMyAdmin doesn't load, disable Brave Shields for that site.

**IV. User Management Script (Python)**

1. **Install MySQL Connector for Python:**Bash
    
```bash
pip install mysql-connector-python
```
    
2. **Use the Enhanced Python Script:**
The script provided in this repository `add_radius_user.py` is ready to use

3. **Set Database Password Environment Variable:Before running the script**, set the `DB_PASSWORD` environment variable in your terminal:Bash
    
```bash
export DB_PASSWORD="YOUR_PYTHON_DB_PASSWORD" # This is the password for 'freeradius_user'
```
    
    (Replace `YOUR_PYTHON_DB_PASSWORD` with the password for the `freeradius_user` MariaDB user).
    
4. **Run the Script to Add Users:**Bash
    
```bash
python3 add_radius_user.py
```
    
    Follow the prompts to add a new user.
    

**V. Testing Authentication**

1. **Start FreeRADIUS in Debug Mode:**
Open a new terminal and run:Bash
    
```bash
sudo freeradius -X
```
    
    This shows detailed logs of authentication attempts.
    
2. **Perform a `radtest`:**
Open *another* terminal and run `radtest` using a user you added with your Python script.BashBash
    
```bash
radtest <username> <cleartext_password> 127.0.0.1 0 <client_secret_from_clients.conf>
```
    
    **Example:**
    If username is `josepadilla`, password is `MySecretPassword`, and client secret for `127.0.0.1` is `testing123`:
    
```bash
radtest josepadilla MySecretPassword 127.0.0.1 0 testing123
```
    
3. **Verify Output:**
    - `radtest` should show `Received Access-Accept`.
    - The `freeradius -X` terminal should show logs indicating successful SQL lookup and authentication.