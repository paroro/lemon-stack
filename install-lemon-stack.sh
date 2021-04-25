#!/bin/bash
set -euo pipefail

########################################################################################################
# Create a droplet with ssh keys, and add this script in the user data form to finish the setup. 
# It creates new users and copys the authorized_keys to them. 
# Replace "user1" and "user2" with your own user names. 
# Replace "mypassword" with your password.
# The script installs dotnetcore, nginx and MySQL.
########################################################################################################

########################
### SCRIPT VARIABLES ###
########################
# Name of the user to create and grant sudo privileges
USERNAMES_TO_ADD=(
	"user1"
	"user2"
)

# Whether to copy over the root user's `authorized_keys` file to the new sudo
# user.
COPY_AUTHORIZED_KEYS_FROM_ROOT=true

# Additional public keys to add to the new sudo user
# OTHER_PUBLIC_KEYS_TO_ADD=(
#     "ssh-rsa AAAAB..."
#     "ssh-rsa AAAAB..."
# )
OTHER_PUBLIC_KEYS_TO_ADD=(
)

####################
### SCRIPT LOGIC ###
####################

for USERNAME in "${USERNAMES_TO_ADD[@]}"; do
    # Add sudo user and grant privileges
	useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"

	# Check whether the root account has a real password set
	encrypted_root_pw="$(grep root /etc/shadow | cut --delimiter=: --fields=2)"

	if [ "${encrypted_root_pw}" != "*" ]; then
		# Transfer auto-generated root password to user if present
		# and lock the root account to password-based access
		echo "${USERNAME}:${encrypted_root_pw}" | chpasswd --encrypted
		passwd --lock root
	else
		# Delete invalid password for user if using keys so that a new password
		# can be set without providing a previous value
		passwd --delete "${USERNAME}"
	fi

	# Expire the sudo user's password immediately to force a change
	chage --lastday 0 "${USERNAME}"

	# Create SSH directory for sudo user
	home_directory="$(eval echo ~${USERNAME})"
	mkdir --parents "${home_directory}/.ssh"

	# Copy `authorized_keys` file from root if requested
	if [ "${COPY_AUTHORIZED_KEYS_FROM_ROOT}" = true ]; then
		cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
	fi

	# Adjust SSH configuration ownership and permissions
	chmod 0700 "${home_directory}/.ssh"
	chmod 0600 "${home_directory}/.ssh/authorized_keys"
	chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"
done

# Add additional provided public keys
for pub_key in "${OTHER_PUBLIC_KEYS_TO_ADD[@]}"; do
	echo "${pub_key}" >> "${home_directory}/.ssh/authorized_keys"
done

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then
    systemctl restart sshd
fi

# Add exception for SSH and then enable UFW firewall
ufw allow OpenSSH
ufw --force enable

###################################################################################
# Install dotnet core on Ubuntu.
###################################################################################

# Register the Microsoft key and product repository:
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

# Install the specified file
sudo dpkg -i packages-microsoft-prod.deb

# To facilitate the installation of other packages required for the application, 
# install the universe repository
sudo add-apt-repository universe

# Install the apt-transport package to allow the use of repositories accessed 
# via the HTTP Secure protocol
sudo apt-get install apt-transport-https

# Download the packages list from the repositories and update them to get 
# information on the newest versions of packages and their dependencies
sudo apt-get update

# Install the .NET Core and the ASP.NET Core Runtimes
# The -y replies "yes" to the install question for an unattended installation.
# To install the sdk: sudo apt-get install -y dotnet-sdk-3.1
sudo apt-get install -y dotnet-runtime-3.1
sudo apt-get update
sudo apt-get install -y aspnetcore-runtime-3.1
# Clean up by removing the downloaded package
sudo rm packages-microsoft-prod.deb

###################################################################################
# Install nginx on Ubuntu.
###################################################################################

# Update the package index on the server 
sudo apt update

# Install nginx.
# The -y replies "yes" to the install question for an unattended installation.
sudo apt install -y nginx 

# Add firewall exception for nginx
sudo ufw allow 'Nginx HTTP'

###################################################################################
# Install MySQL 8.0 on Ubuntu using the official MySQL Software Repository.
# To remove : sudo apt purge mysql-client mysql-server
###################################################################################

# Set environment as noninteractive
export DEBIAN_FRONTEND=noninteractive

# Preset selections to allow noninteractive(unattended) installation, remember to set the password twice below.
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server  select  mysql-8.0'
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/root-pass password mypassword'
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/re-root-pass password mypassword'
sudo debconf-set-selections <<< 'mysql-community-server mysql-server/default-auth-override select Use Strong Password Encryption (RECOMMENDED)'

# Download the MySQL Software Repository. We need to pass two command line flags to curl. 
# -O instructs curl to output to a file instead of standard output. 
# The L flag makes curl follow HTTP redirects, necessary in this case because the address 
# we copied actually redirects us to another location before the file downloads.
curl -OL https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb

# Install the repository : dpkg is used to install, remove, and inspect .deb software packages. 
# The -i flag indicates that we’d like to install from the specified file.
# Add a -E after sudo, to preserve the environment selections (DEBIAN_FRONTEND).
sudo -E dpkg -i mysql-apt-config*

# Refresh the apt package cache to make the new software packages available.
sudo apt update

# Clean up by removing the downloaded file.
rm mysql-apt-config*

# Install the default package.
# The -E flag is used to pass the DEBIAN_FRONTEND values to apt.
# The -y replies "yes" to the install question for an unattended installation.
sudo -E apt install -y mysql-server 

# Allow MySQL Port 3306 on the Ubuntu Firewall for MySQLWorkbench connection
sudo ufw allow mysql
