# lemon-stack
# Description
This project was created to share scripts to set up a Digital Ocean droplet for a .NET Core application. 

LEMoN is an acronym I chose for the following collection of software : 
* L = Linux operating system, Ubuntu in this case.
* E = nginx web server (pronounced engine-x, hence the E, as with the LEMP stack).
* M = MySQL for the database.
* oN = .NET Core for the application.

I called it LEMoN because it is easier to pronounce than LEMD (dotnet) or LEMC (C#) and with the lack of clear resources out there, the stack sometimes felt like a lemon.

## Steps to setup the server
### Install the LEMoN stack
install-lemon-stack.sh: creates the Ubuntu users, installs dotnet Core, nginx and MySQL. It is based on the Digital Ocean [initial server setup script](https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ubuntu-18-04). When creating a droplet from the Control Panel, select the User data checkbox then copy and paste the script into the field provided before launching the installation.
### Prepare app deployment
prepare-app-deployment.sh: creates a user called "deployer" for deployment purposes and an application directory.
### Install the application
Copy your .NET Core application to the application directory created in the previous script or deploy it from your CI/CD pipeline. Use .gitlab-ci.yml to help setup your Gitlab CI pipeline.
### Configure nginx
configure-nginx.sh: configures nginx as a proxy server.
