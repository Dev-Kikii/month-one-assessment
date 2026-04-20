#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Get instance ID from metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Create a simple HTML page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Web Server</title>
</head>
<body>
    <h1>Welcome to TechCorp!</h1>
    <p>Server Instance ID: $INSTANCE_ID</p>
    <p>Powered by Apache on AWS EC2</p>
</body>
</html>
EOF

# Enable password authentication for SSH
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Create a user with password for bastion access
useradd webadmin
echo "webadmin:TechCorp2024!" | chpasswd