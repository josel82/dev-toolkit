#!/usr/bin/python3

import mysql.connector #<-- INSTALL LIBRARY: pip install mysql-connector-python
import crypt
import getpass
import os
import secrets # For crypt.mksalt

# --- Database Configuration ---
DB_CONFIG = {
    'host': 'localhost',
    'user': 'freeradius_user',
    'password': os.environ.get('DB_PASSWORD'), # <-- IMPORTANT: export DB_PASSWORD="your_secure_db_password" (run this command before running the script)
    'database': 'radius'
}

# Ensure the password was actually set in the environment
if not DB_CONFIG['password']:
    print("Error: DB_PASSWORD environment variable not set. Please set it using 'export DB_PASSWORD=\"your_secure_db_password\"' before running the script.")
    exit(1)


# --- RADIUS Table Definitions (based on FreeRADIUS schema) ---
# radcheck: Used for authentication attributes (e.g., password)
#    id, username, attribute, op, value
# radreply: Used for attributes returned to the NAS after successful auth (e.g., VLAN)
#    id, username, attribute, op, value
# radusergroup: Used to assign users to groups for policy management
#    id, username, groupname, priority (often 0)

def generate_crypt_hash(password):
    # Use SHA512 method for stronger hashing
    # crypt.mksalt generates a random salt
    return crypt.crypt(password, crypt.mksalt(crypt.METHOD_SHA512))

def add_radius_user(username, password, groupname=None, default_vlan=None):
    conn = None
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # 1. Check if user already exists in radcheck
        cursor.execute("SELECT COUNT(*) FROM radcheck WHERE username = %s", (username,))
        if cursor.fetchone()[0] > 0:
            print(f"Error: User '{username}' already exists.")
            return

        # 2. Add to radcheck (for password)
        hashed_password = generate_crypt_hash(password)
        sql_check = "INSERT INTO radcheck (username, attribute, op, value) VALUES (%s, %s, %s, %s)"
        cursor.execute(sql_check, (username, 'Crypt-Password', ':=', hashed_password))
        print(f"Added '{username}' to radcheck with hashed password.")

        # 3. Add to radusergroup (if specified)
        if groupname:
            sql_group = "INSERT INTO radusergroup (username, groupname, priority) VALUES (%s, %s, %s)"
            cursor.execute(sql_group, (username, groupname, 0)) # Priority 0 is common
            print(f"Added '{username}' to group '{groupname}'.")

        # 4. Add to radreply (for default VLAN if specified)
        if default_vlan:
            sql_vlan = "INSERT INTO radreply (username, attribute, op, value) VALUES (%s, %s, %s, %s)"
            # These are standard RADIUS attributes for VLANs via 802.1X
            cursor.execute(sql_vlan, (username, 'Tunnel-Type', ':=', 'VLAN'))
            cursor.execute(sql_vlan, (username, 'Tunnel-Medium-Type', ':=', 'IEEE-802'))
            cursor.execute(sql_vlan, (username, 'Tunnel-Private-Group-Id', ':=', str(default_vlan)))
            print(f"Set default VLAN '{default_vlan}' for '{username}'.")

        conn.commit()
        print(f"\nUser '{username}' created successfully!")

    except mysql.connector.Error as err:
        print(f"Database Error: {err}")
        if conn:
            conn.rollback() # Rollback changes on error
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    finally:
        if conn:
            conn.close()

# --- Main execution block ---
if __name__ == "__main__":
    print("--- Add FreeRADIUS User ---")
    username = input("Enter username: ").strip()
    if not username:
        print("Username cannot be empty. Exiting.")
        exit(1)

    password = getpass.getpass("Enter password: ").strip()
    if not password:
        print("Password cannot be empty. Exiting.")
        exit(1)

    confirm_password = getpass.getpass("Confirm password: ").strip()
    if password != confirm_password:
        print("Passwords do not match. Exiting.")
        exit(1)

    groupname_input = input("Enter group name (optional, press Enter to skip): ").strip()
    groupname = groupname_input if groupname_input else None

    vlan_input = input("Enter default VLAN (optional, press Enter to skip): ").strip()
    default_vlan = int(vlan_input) if vlan_input and vlan_input.isdigit() else None

    add_radius_user(username, password, groupname, default_vlan)