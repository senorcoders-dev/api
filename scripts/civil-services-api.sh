#!/bin/bash
#
# description: Bash file to manage API Services
#
# author: Peter Schmalfeldt <hello@civil.services>

DIR=`dirname $0`
APP_NAME="Civil Services API"
PATH_API="$(dirname "$DIR")"

NX=""
ES=""
MS=""
NX=""
NS=""

__make_header(){
    TEXT=$( echo $1 | tr '\n' ' ')
    echo -e "\n\033[48;5;22m  Civil Services › $TEXT  \033[0m\n"
}

__output(){
    TEXT=$( echo $1 | tr '\n' ' ')
    echo -e "\033[7m › \033[27m $TEXT\n"
}

__success(){
    TEXT=$( echo $1 | tr '\n' ' ')
    echo -e "\033[38;5;34m✓ Civil Services › $TEXT\033[0m\n"
}

__notice(){
    TEXT=$( echo $1 | tr '\n' ' ')
    echo -e "\033[38;5;220m→ Civil Services › $TEXT\033[0m\n"
}

__error(){
    TEXT=$( echo $1 | tr '\n' ' ')
    echo -e "\033[38;5;196m! Civil Services › $TEXT\033[0m\n"
}

function civil_services_api(){
  case "$1" in
    install)
      civil_services_api_install
    ;;
    start)
      civil_services_service_check
      civil_services_api_start
    ;;
    stop)
      civil_services_service_check
      civil_services_api_stop
    ;;
    restart)
      __error "You are about to restart the $APP_NAME."

      echo -ne "\e[38;5;196mCONTINUE? (y or n) : \e[0m"
      read CONFIRM
      case $CONFIRM in
          y|Y|YES|yes|Yes)
            civil_services_api_stop
            civil_services_api_start
          ;;
          n|N|no|NO|No)
            __notice "Skipping Restart of $APP_NAME"
          ;;
          *)
            __notice "Please enter only y or n"
      esac
    ;;
    reset)
      civil_services_api_reset
    ;;
    update)
      civil_services_api_update
    ;;
    migrate)
      civil_services_api_migrate
    ;;
    seed)
      civil_services_api_seed
    ;;
    status)
      civil_services_service_check
      civil_services_api_status
    ;;
    "-h" | "-help" | "--h" | "--help" | help)
      civil_services_api_help
    ;;
    *)
      __error "Missing Argument | Loading Help ..."
      civil_services_api_help
  esac
}

civil_services_api_install() {
  __make_header "Installing $APP_NAME"

  # Change to Doing API Directory
  cd $PATH_API

  civil_services_api_reset

  npm install
}

civil_services_api_start() {
  __make_header "Starting $APP_NAME"

  # Change to Doing API Directory
  cd $PATH_API

  # Cleanup old log files
  rm -f *.log
  rm -f ~/.forever/web-server.log

  if [[ -n $NX ]]; then
    __notice "Nginx Already Running"
  else
    __success "Starting Nginx"

    if [[ $OSTYPE == darwin* ]]; then
        brew services start nginx
    else
        sudo systemctl start nginx
    fi
  fi

  if [[ -n $ES ]]; then
    __notice "Elasticsearch Already Running"
  else
    __success "Starting Elasticsearch"

    if [[ $OSTYPE == darwin* ]]; then
        brew services start elasticsearch@1.7
    else
        sudo systemctl start elasticsearch
    fi
  fi

  if [[ -n $MS ]]; then
    __notice "MySQL Already Running"
  else
    __success "Starting MySQL"

    if [[ $OSTYPE == darwin* ]]; then
        brew services start mysql
    else
        sudo systemctl start mysql
    fi
  fi

  if [[ -n $RS ]]; then
    __notice "Redis Server Already Running"
  else
    __success "Starting Redis"

    if [[ $OSTYPE == darwin* ]]; then
        brew services start redis
    else
        sudo systemctl start redis
    fi
  fi

  if [[ -n $NS ]]; then
    __notice "Node Server Already Running"
  else
    __success "Starting Node Server"

    cd $PATH_API

    npm run -s cleanup
    npm run -s docs
    npm run -s migrate
    npm run -s seed
    npm run -s elasticsearch:create
    npm run -s elasticsearch:update
    npm run -s cleanup && npm run -s docs

    DEBUG=express:* ./node_modules/nodemon/bin/nodemon.js index.js
  fi
}

civil_services_api_stop() {
  __make_header "Stopping $APP_NAME"

  # Change to Doing API Directory
  cd $PATH_API

  if [[ -n $NX ]]; then
    __success "Stopping Nginx"

    if [[ $OSTYPE == darwin* ]]; then
        brew services stop nginx
    else
        sudo systemctl stop nginx
    fi

  else
    __notice "Nginx was not Running"
  fi

  if [[ -n $ES ]]; then
    __success "Stopping Elasticsearch"

    cd $PATH_API
    npm run -s elasticsearch:delete

    if [[ $OSTYPE == darwin* ]]; then
        brew services stop elasticsearch@1.7
    else
        sudo systemctl stop elasticsearch
    fi

  else
    __notice "Elasticsearch was not Running"
  fi

  if [[ -n $MS ]]; then
    __success "Stopping MySQL"

    if [[ $OSTYPE == darwin* ]]; then
        brew services stop mysql
    else
        sudo systemctl stop mysql
    fi

  else
    __notice "MySQL was not Running"
  fi

  if [[ -n $RS ]]; then
    __success "Stopping Redis Server"

    if [[ $OSTYPE == darwin* ]]; then
        brew services stop redis
    else
        sudo systemctl stop redis
    fi

  else
    __notice "Redis Server was not Running"
  fi

  if [[ -n $NS ]]; then
    __success "Stopping Node Server"

    cd $PATH_API
    node ./node_modules/forever/bin/forever stop -w --minUptime 1000 --spinSleepTime 1000 -m 1 -l web-server.log -o ./web-server-stdout.log -e ./web-server-stderr.log index.js

  else
    __notice "Node Server was not Running"
  fi

}

civil_services_api_reset() {
  __make_header "Resetting $APP_NAME"

  # Change to Doing API Directory
  cd $PATH_API

  # Remove old NPM Modules to prevent weird issues
  rm -fr node_modules
}

civil_services_api_update() {
  __make_header "Updating $APP_NAME"

  # Change to Doing API Directory
  cd $PATH_API

  civil_services_api_stop

  __success "Updating Git Repo"
  git reset --hard
  git fetch
  git pull

  civil_services_api_install
  civil_services_api_start
}

civil_services_api_migrate() {
  __make_header "Migrating $APP_NAME Database"

  cd $PATH_API
  npm run -s migrate
}

civil_services_api_seed() {
  __make_header "Migrating $APP_NAME Database"

  cd $PATH_API
  npm run -s seed
}

civil_services_api_status() {
  __make_header "$APP_NAME Status Check"

  if [[ -n $NX ]]; then
    __success "Nginx is Running"
  else
    __error "Nginx is Not Running"
  fi

  if [[ -n $ES ]]; then
    __success "Elasticsearch is Running"
  else
    __error "Elasticsearch is Not Running"
  fi

  if [[ -n $MS ]]; then
    __success "MySQL is Running"
  else
    __error "MySQL is Not Running"
  fi

  if [[ -n $RS ]]; then
    __success "Redis Server is Running"
  else
    __error "Redis Server is Not Running"
  fi

  if [[ -n $NS ]]; then
    __success "Node Server is Running"
  else
    __error "Node Server is Not Running"
  fi
}

civil_services_service_check() {
  if [[ $OSTYPE == darwin* ]]; then
      NX=$(brew services list | grep nginx | awk '{print $2}' | grep started)
      ES=$(brew services list | grep elasticsearch@1.7 | awk '{print $2}' | grep started)
      MS=$(brew services list | grep mysql | awk '{print $2}' | grep started)
      RS=$(brew services list | grep redis | awk '{print $2}' | grep started)
      NS=$(lsof -i TCP:5000 | grep LISTEN | awk '{print $2}')
  else
      NX=$(systemctl status nginx | grep 'Main PID' | awk '{print $3}')
      ES=$(systemctl status elasticsearch | grep 'Main PID' | awk '{print $3}')
      MS=$(systemctl status mysql | grep 'Main PID' | awk '{print $3}')
      RS=$(systemctl status redis | grep 'Main PID' | awk '{print $3}')
      NS=$(lsof -i TCP:5000 | grep LISTEN | awk '{print $2}')
  fi
}

civil_services_api_help() {
  __make_header "Instructions"

  echo -e "\033[38;5;34m$ civil_services_api install\033[0m\n"

  echo "  Installs dependencies and NPM modules."

  echo -e "\n\033[38;5;34m$ civil_services_api start\033[0m\n"

  echo "  Starts Elasticsearch, MySQL, Redis & Node Servers."

  echo -e "\n\033[38;5;34m$ civil_services_api stop\033[0m\n"

  echo "  Stops Elasticsearch, MySQL, Redis & Node Servers."

  echo -e "\n\033[38;5;34m$ civil_services_api restart\033[0m\n"

  echo -e "  Same as running \033[38;5;220m$ civil_services_api stop\033[0m and then \033[38;5;220m$ civil_services_api start\033[0m."

  echo -e "\n\033[38;5;34m$ civil_services_api reset\033[0m\n"

  echo "  Resets Project to Clean Installation State."

  echo -e "\n\033[38;5;34m$ civil_services_api update\033[0m\n"

  echo -e "  Pulls down latest Git Repo Changes and runs \033[38;5;220m$ civil_services_api reset\033[0m."

  echo -e "\n\033[38;5;34m$ civil_services_api migrate\033[0m\n"

  echo "  Updates to latest database schema."

  echo -e "\n\033[38;5;34m$ civil_services_api seed\033[0m\n"

  echo "  Updates to latest database data."

  echo -e "\n\033[38;5;34m$ civil_services_api status\033[0m\n"

  echo "  Prints the status of all running services."

  echo -e "\n\033[38;5;34m$ civil_services_api help\033[0m\n"

  echo "  Prints this help screen."

  echo -e ""
}

civil_services_api $1