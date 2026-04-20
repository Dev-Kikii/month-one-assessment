#!/bin/bash
yum update -y

# Install PostgreSQL
amazon-linux-extras enable postgresql14
yum install -y postgresql postgresql-server

# Initialize the database
postgresql-setup initdb

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Configure PostgreSQL to allow password authentication
sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/peer/md5/g' /var/lib/pgsql/data/pg_hba.conf

# Restart PostgreSQL to apply changes
systemctl restart postgresql

# Create a database and user
sudo -u postgres psql <<EOF
CREATE USER techcorp WITH PASSWORD 'TechCorp2024!';
CREATE DATABASE techcorpdb OWNER techcorp;
GRANT ALL PRIVILEGES ON DATABASE techcorpdb TO techcorp;
EOF

# Enable password authentication for SSH
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Create a user with password for bastion access
useradd dbadmin
echo "dbadmin:TechCorp2024!" | chpasswd