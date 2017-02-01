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
  message ${BLUE} "usage: . ./workstation_setup.sh /path/to/nginx_config [v0.33.0 (optional nvm version)]"
  return 1
fi
NGINX="${1}"
message ${CYAN} "Set <NGINX> to ${NGINX}"
NVM="v0.33.0"
if [ $# -eq 2 ]; then
  message ${GREEN} "Setting nvm version to ${2}...\n\n"
  NVM=$2
fi
# END Argument declaration

message ${GREEN} "Setting up development server..."
wget https://raw.githubusercontent.com/shingoinstitute/shingo-scripts/master/server_setup.sh
sudo chmod +x server_setup.sh
. ./server_setup.sh ${NGINX} ${NVM}
message ${GREEN} "Finished setting up development server...\n"
message ${GREEN} "  Setting up workstation "
message ${GREEN} "***************************\n\n"
message ${GREEN} "Installing Visual Studio Code..."
wget -O code.deb https://go.microsoft.com/fwlink/?LinkID=760868
sudo dpkg -i code.deb
if [ "$?" -ne "0" ]; then
   error "DPKG failed to install. Maybe missing dependancies? Trying to resolve..."
   sudo apt-get -f install
   sudo dpkg -i code.deb
   if [ "$?" -ne "0" ]; then
       error "Failed to install Visual Studio Code"
   fi
   message ${GREEN} "Successfully resolved issues and installed Visual Studio Code...\n"
   rm code.deb
else
   message ${GREEN} "Installed Visual Studio Code...\n"
   rm code.deb
fi
message ${GREEN} "Installing VIM..."
sudo apt install vim -y
if [ "$?" -ne "0" ]; then
   error "VIM failed to install..."
fi
message ${GREEN} "Installed VIM...\n"
message ${GREEN} "Installing build tools (CMake)..."
sudo apt install cmake
if [ "$?" -ne "0" ]; then
   error "CMake failed to install..."
fi
message ${GREEN} "Installed build tools (CMake)..."
message ${GREEN} "Finished setting up workstation..."



