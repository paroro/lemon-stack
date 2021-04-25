#!/bin/bash

#####################################################################################
# Setup the deployment user on Ubuntu.
# The script creates a deployment group called deployers and a user called deployer 
# that you can use to deploy from your CI/CD pipeline.
# It assumes that the Public/Private key pair has already been created and that the 
# public key is installed on the machine. An application directory is created and 
# the appropriate permissions given to the deployers group. 
# Run the tests at the end of the script to check that the script executed correctly.
# Replace "myapplication" with your application name.
#####################################################################################
# Declare variables
APPLICATION=myapplication
GROUP=deployers
USERNAME=deployer

# Add a group and user for deployment purposes and limit their access to the application directory
# Add the user to the www-data group and grant privileges
groupadd "${GROUP}"
useradd --create-home --shell "/bin/bash" --groups "${GROUP}" "${USERNAME}"

# Create SSH directory for sudo user
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"

# Copy `authorized_keys` file from root 
cp /root/.ssh/authorized_keys "${home_directory}/.ssh"

# Adjust SSH configuration ownership and permissions
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Create a main directory for the application and an app folder for the application files.  -parents parameter for recursive directory creation.
# Grant read, write and execute permissions as well as acces to the deployers group. User root: rwx, group deployers: rwx, others: rwx.
application_directory="$(eval echo /var/www/${APPLICATION})"
mkdir --parents "${application_directory}/app"
chmod --recursive 0777 "${application_directory}"
chown --recursive :"${GROUP}" "${application_directory}"

# Add an archive directory to store successive versions of the application after each deployment.
# Grant read, write and execute permissions as well as acces to the deployers group.
archive_directory="$(eval echo /var/archive/${APPLICATION})"
mkdir --parents "${archive_directory}"
chmod --recursive 0777 "${archive_directory}"
chown --recursive :"${GROUP}" "${archive_directory}"

# Allows deployer to restart service with sudo command without entering password (prevent storing password on deployment service)
sudo echo "${USERNAME}   ALL = NOPASSWD: /bin/systemctl restart myapplication.service" | sudo tee -a /etc/sudoers.d/myapplication

# TESTS
# Replace "000.00.00.00" with your servers IP address and "myapplication" with your applications name.
# Test the write permissions of the deployer user from another server.
# Ensure that the server has the private key file id_rsa installed in the ~/.ssh directory.
# Test write: scp -r test.file deployer@000.00.00.00:/var/www/myapplication
# Test move: ssh -p22 deployer@000.00.00.00 "mv /var/www/myapplication/app /var/www/myapplication/_old"
# Test remove: ssh -p22 deployer@000.00.00.00 "rm -rf /var/www/myapplication/_old"
# Check groups: cat /etc/group
# Check groups for user deployer: groups deployer
# To check owner of directory: ls -l {directory}





    
	
