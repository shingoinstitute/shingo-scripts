#!/bin/bash
# BEGIN Color definitions
BLACK='\033[0;30m'
DARK_GREY='\033[1;30m'
LIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
LIGHT_PURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHT_CYAN='\033[1;36m'
LIGHT_GREY='\033[0;37m'
WHITE='\033[1;37m'
RED='\033[0;31m'
NC='\033[0m'
# END Color definitions

# BEGIN Function declarations
# USAGE: error "ERROR MESSAGE"
function error (){
  echo -e "${RED}${1}${NC}"
  return 1
}
# USAGE: message COLOR "MESSAGE"
function message(){
  echo -e "${1}${2}${NC}"
}
# END Function declarations

# BEGIN Argument declaration
if [ $# -eq 0 ]; then
  message ${BLUE} "usage: . ./server_setup.sh /path/to/nginx_config [v0.33.0 (optional nvm version)]"
  return 1
fi
NGINX="${1}"
message ${CYAN} "Set <NGINX> to ${NGINX}"
NVM="v0.33.0"
if [ $# -eq 2 ]; then
  message ${GREEN} "Setting nvm version to ${2}...\n\n"
  NVM="${2}"
fi
# END Argument declaration

message ${GREEN} "        Starting Server Setup!"
message ${GREEN} "**************************************\n"

# Create swapfile if not present
echo -e "${DARK_GREY}"
ls -lh /swapfile
echo -e "${NC}"
if [ "$?" -ne "0" ]; then
    message ${GREEN} "Creating swapfile of 2G..."
    sudo fallocate -l 2G /swapfile
    ls -lh /swapfile
    if [ "$?" -ne "0" ]; then
    error "Failed to create swapfile!"
    fi
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
    if [ "$?" -ne "0" ]; then
    error "Failed to configure swapfile!"
    fi
    message ${GREEN} "Created and configured swapfile:"
    sudo swapon -s
fi

# Do full upgrade
message ${GREEN} "Starting system upgrade..."
sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y
if [ "$?" -ne "0" ]; then
  error "Upgrade failed!"
fi
message ${GREEN} "Finished system upgrade...\n"

# Install dependancies and dev tools
message ${GREEN} "Installing required libraries..."
sudo apt install git curl build-essential python libssl-dev -y
if [ "$?" -ne "0" ]; then
  error "Failed to install one or more required libraries!"
fi
message ${GREEN} "Finished installing required libraries...\n"

# Install NVM
message ${GREEN} "Installing nvm ${NVM}..."
curl https://raw.githubusercontent.com/creationix/nvm/${NVM}/install.sh > install.sh
bash install.sh
if [ "$?" -ne "0" ]; then
  error "Failed to install nvm ${NVM}!"
fi
source ~/.profile
echo -e "${DARK_GREY}"
nvm --version
echo -e "${NC}"
if [ "$?" -ne "0" ]; then
  error "nvm is not part of your path!"
fi
rm install.sh
message ${GREEN} "Finished installing nvm ${NVM}...\n"

# Install most recent node and use it
message ${GREEN} "Installing most recent version of node..."
nvm install node
if [ "$?" -ne "0" ]; then
  error "Node failed to install!"
fi
nvm alias default node
nvm use default
message ${CYAN} "Node version installed is"
echo -e "${DARK_GREY}"
node --version
echo -e "${NC}"
if [ "$?" -ne "0" ]; then
  error "Couldn't find node!"
fi

# Install bower and sails
message ${GREEN} "Installing bower and sails globally..."
npm install -g bower sails
if [ "$?" -ne "0" ]; then
  error "Couldn't install bower of sails!"
fi
message ${GREEN} "Finished installing bower and sails...\n"

# Install NGINX
message ${GREEN} "Installing NGINX..."
sudo apt install nginx -y
if [ "$?" -ne "0" ]; then
  error "Couldn't install NGINX!"
fi
message ${GREEN} "Finished installing NGINX...\n"

# Configure Firewall via ufw
message ${GREEN} "Configuring firewall..."
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'OpenSSH'
sudo ufw status
message ${GREEN} "Finished configuring firewall...\n"

# Create desired NGINX server config
message ${GREEN} "Adding config ${NGINX} to sites available/enabled..."
echo -e "${DARK_GREY}"
ls /etc/nginx/sites-enabled/default
echo -e "${NC}"
if [ "$?" -eq "0" ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi
NGINX_PATH=(${NGINX//\// })
NGINX_FILE="${NGINX_PATH[${#NGINX_PATH[@]}-1]}"
sudo cp ${NGINX} /etc/nginx/sites-available/${NGINX_FILE}
sudo ln -sf /etc/nginx/sites-available/${NGINX_FILE} /etc/nginx/sites-enabled/${NGINX_FILE}
if [[ "${NGINX_FILE}" =~ ^.*ssl.*$ ]]; then
    ls /etc/ssl/certs/server.crt
    if [ "$?" -ne "0" ]; then
        error "Couldn't find SSL Certificate! Please place Certificates and Keys at the specified paths in ${NGINX_FILE} or comment out the SSL Config."
    else
        message ${GREEN} "Using simple nginx config if found"
        ls ./nginx_config/simple_nginx
        if [ "$?" -eq "0" ]; then
          sudo cp ./nginx_config/simple_nginx /etc/nginx/sites-available/simple_nginx
          sudo rm /etc/nginx/sites-enabled/${NGINX_FILE}
          sudo ln -sf /etc/nginx/sites-available/simple_nginx /etc/nginx/sites-enabled/simple_nginx
          message ${GREEN} "Configured NGINX using simple config"
        else
          error "Couldn't find simple_nginx config..."
        fi
    fi
fi
sudo service nginx restart
echo -e "${DARK_GREY}"
ls /etc/nginx/sites-enabled/${NGINX_FILE}
if [ "$?" -ne "0" ]; then
  error "Couldn't configure NGINX!"
fi
echo -e "${NC}"
message ${GREEN} "Added NGINX config and reset server!\n"

# Install and configure MySQL server if not present
echo -e "${DARK_GREY}"
mysql --version
echo -e "${NC}"
if [ "$?" -ne "0" ]; then
    message ${GREEN} "Setting up mysql server..."
    sudo apt install mysql-server -y
    if [ "$?" -ne "0" ]; then
        error "Couldn't install MySQL server!"
    fi
    sudo mysql_secure_installation
    if [ "$?" -ne "0" ]; then
        error "Couldn't configure MySQL!"
    fi
    message ${GREEN} "Installed and configured MySQL server...\n\n"
fi

# DONE!
message ${GREEN} "Finished setting up server!\nHappy Coding!"
return 0