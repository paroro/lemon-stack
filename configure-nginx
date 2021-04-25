#!/bin/bash

#########################################################################################################################################
# Configure Nginx as a reverse proxy.
# Before running the script : 
# Copy all files from the development computer to the directory on the server. 
# The -r flag means recursive, copy sub directories and their contents.
# scp -r /h/code/myapplication/myapplication/bin/Release/netcoreapp3.1/publish/* root@000.00.00.00:/var/www/myapplication
# OR run the deployment from Gitlab CI.
# Replace "000.00.00.00" with your servers IP address, "user" with your user name and "myapplication" with your applications name.
##########################################################################################################################################

# Fill in the variables
SERVER_NAME=000.00.00.00
APPLICATION_NAME=myapplication
USER=user

# Variables built using the application name
APPLICATION_DIRECTORY=$APPLICATION_NAME/app
APPLICATION_SERVICE=$APPLICATION_NAME

# Modify /etc/nginx/sites-available/default
sudo echo 'server {
    listen        80;
    server_name   '$SERVER_NAME';
    location / {
        proxy_pass         http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
server {
    listen   80 default_server;
    # listen [::]:80 default_server deferred;
    return   444;
}' > /etc/nginx/sites-available/default

# Force Nginx to reload the changes
sudo nginx -s reload

# Use systemd to create a service file to start and monitor the underlying web app
sudo echo '[Unit]
Description='$APPLICATION_NAME' app

[Service]
WorkingDirectory=/var/www/'$APPLICATION_DIRECTORY'
ExecStart=/usr/bin/dotnet /var/www/'$APPLICATION_DIRECTORY'/'$APPLICATION_NAME'.dll
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGKILL
SyslogIdentifier='$APPLICATION_SERVICE'
User='$USER'
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/$APPLICATION_SERVICE.service

# Save the file and enable the new service 
sudo systemctl enable $APPLICATION_SERVICE.service 

#  Start the service 
sudo systemctl start $APPLICATION_SERVICE.service 

# After running the script, verify the syntax of the configuration files  
sudo nginx -t 

# Check the service status 
sudo systemctl status $APPLICATION_SERVICE.service 
