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
if [ $# -lt 2 ]; then
  message ${BLUE} "usage: . ./clone_and_build_sails.sh </path/to/dir> <git_url> (optional </path/to/env_file>) (optional <start script>)"
  return 1
fi
SAVE_DIR="${1}"
message ${CYAN} "Set <SAVE_DIR> to ${SAVE_DIR}"
GIT_URL="${2}"
message ${CYAN} "Set git repo to ${git_url}"
if [ $# -eq 3 ]; then
  message ${GREEN} "Setting path to env file to ${3}...\n\n"
  ENV_FILE=$3
fi
START_SCRIPT="app.js"
if [ $# -eq 4 ]; then
  message ${GREEN} "Setting path to env file to ${4}...\n\n"
  START_SCRIPT=$4
fi
# END Argument declaration

message ${GREEN} "    Cloning and Building SailsJS Application"
message ${GREEN} "************************************************\n\n"
message ${GREEN} "Changing working director to ${SAVE_DIR}"
cd ${SAVE_DIR}
if [ "$?" -ne 0 ]; then
    message ${GREEN} "Creating director ${SAVE_DIR}"
    mkdir ${SAVE_DIR}
    cd ${SAVE_DIR}
    if [ "$?" -ne 0 ]; then
        error "Failed to create directory ${SAVE_DIR}. Please create it yourself."
    fi
fi
message ${GREEN} "Cloning repo from ${GIT_URL}"
git clone ${GIT_URL}
if [ "$?" -ne 0 ]; then
   error "Failed to clone repo..."
fi
GIT_PATH=(${GIT_URL//\// })
GIT_REPO="${GIT_PATH[${#GIT_PATH[@]}-1]}"
message ${PURPLE} "GIT_REPO = ${GIT_REPO}"
GIT_FILE=(${GIT_REPO//\./ })
message ${PURPLE} "GIT_FILE = ${GIT_FILE}"
GIT_DIR="${GIT_FILE[0]}"
message ${GREEN} "Installing bower dependancies in ${GIT_DIR}/assets/"
cd ${GIT_DIR}/assets
bower install
if [ "$?" -ne 0 ]; then
    error "Failed to install bower dependancies..."
else
    message ${GREEN} "Installed bower assets"
fi
message ${GREEN} "Installing npm dependancies"
cd ../
npm install
if [ "$?" -ne 0 ]; then
    error "Failed to install npm dependancies..."
else
    message ${GREEN} "Installed npm dependancies"
fi
if [ -z ${ENV_FILE} ]; then
    message ${GREEN} "Finished cloning repo and installing dependancies"
else
    message ${GREEN} "Creating MySQL database with data from env file"
    source ${ENV_FILE}
    mysql --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" -e "CREATE DATABASE ${MYSQL_DB}"
    if [ "${NODE_ENV}" == "production" ]; then
        message ${GREEN} "Production enviroment found. Lifting sails in dev mode to create tables."
        NODE_ENV=development forever start ${START_SCRIPT}
        forever stop app.js
        message ${GREEN} "Lifting sails in production mode."
        NODE_ENV=production forever -w start ${START_SCRIPT}
    else
        message ${GREEN} "Development enviroment found. Lifting sails in dev mode."
        forever -w start ${START_SCRIPT}
    fi
fi





