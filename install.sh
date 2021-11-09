#!/bin/bash

COIN_NAME='raptoreum'
BOOTSTRAP_TAR='https://github.com/testnet3/RTMnode/releases/download/latest/bootstrap.tgz'
WALLET_TAR='https://github.com/Raptor3um/raptoreum/releases/download/1.3.15.99/raptoreum_1.3.15.99_ubuntu18_64.tar.gz'
CONFIG_DIR='.raptoreumcore'
CONFIG_FILE='raptoreum.conf'
PORT='10228'
COIN_DAEMON='raptoreumd'
COIN_CLI='raptoreum-cli'
COIN_CLI_QT='raptoreum-qt'
COIN_TX='raptoreum-tx'
COIN_PATH='/usr/local/bin'
USERNAME='$(whoami)'
START_QT_ANS=""
BP_ANS=""
DSCRD_ID=""

echo -e " 
echo -e " 
echo -e "             Based on Raptoreum node install script by dk808 from AltTank"
echo -e "                             Smartnode healthcheck by Delgon"
echo -e ""
echo -e "                    tRTM Node setup starting, press [CTRL-C] to cancel."
sleep 5
if [ "$USERNAME" = "root" ]; then
  echo -e "You are currently logged in as root, please switch to a sudo user."
  exit
fi

function wipe_clean() {
  echo -e "Removing any instances of tRTM..."
  sudo $COIN_CLI_QT stop 
  sudo killall $COIN_DAEMON 
  sudo rm /usr/local/bin/$COIN_NAME* 
  rm -rf $HOME/$CONFIG_DIR 
}

function ip_confirm() {
  echo -e "Detecting IP address being used..." && sleep 1
  WANIP=$(curl https://ifconfig.co/ip)
  if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
      WANIP=$(whiptail --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
  fi
  }

function install_packages() { 
  echo -e "Installing Packages..."
  sudo apt-get install pwgen tar -y
  echo -e "Packages complete..."
}

smartnodeblsprivkey=""
function create_conf() {
  if [[ ! -z $1 ]]; then
    while [[ -z $smartnodeblsprivkey ]]; do
      smartnodeblsprivkey=$(whiptail --inputbox "Enter your SmartNode OperatorSecret key" 8 75 3>&1 1>&2 2>&3)
    done
    return
  fi
  while [[ -z $smartnodeblsprivkey ]]; do
    smartnodeblsprivkey=$(whiptail --inputbox "Enter your SmartNode operatorSecret key" 8 75 3>&1 1>&2 2>&3)
  done
  if [ -f $HOME/$CONFIG_DIR/$CONFIG_FILE ]; then
    echo -e "Existing conf file found backing up to $COIN_NAME.old ..."
    mv $HOME/$CONFIG_DIR/$CONFIG_FILE $HOME/$CONFIG_DIR/$COIN_NAME.old;
  fi
  RPCUSER=$(pwgen -1 8 -n)
  PASSWORD=$(pwgen -1 20 -n)
  echo -e "Creating Conf File..."
  sleep 1
  mkdir $HOME/$CONFIG_DIR > /dev/null 2>&1
  touch $HOME/$CONFIG_DIR/$CONFIG_FILE
  cat << EOF > $HOME/$CONFIG_DIR/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
port=$PORT
server=1
daemon=1
listen=1
smartnodeblsprivkey=$smartnodeblsprivkey
externalip=$WANIP
maxconnections=128
EOF
}

function install_bins() {
  echo -e "Installing latest binaries..."
  mkdir rtemp
  curl -L $WALLET_TAR | tar xz -C ./rtemp
  sudo mv ./rtemp/$COIN_DAEMON ./rtemp/$COIN_CLI ./rtemp/$COIN_CLI_QT ./rtemp/$COIN_TX $COIN_PATH
  sudo chmod 755 ${COIN_PATH}/${COIN_NAME}*
  rm -rf rtemp
}

function bootstrap() {
    echo -e "Downloading wallet bootstrap please be patient..."
  mkdir ~/$CONFIG_DIR
    curl -L $BOOTSTRAP_TAR | tar xz -C $HOME/$CONFIG_DIR
 } 
 
 
CRON_ANS=""
PROTX_HASH=""
# If $1 is provided, just ask about bootstrap.
function cron_job() {
  if [[ ! -z $1 ]]; then
    if whiptail --yesno "Would you like Cron to check on daemon's health every 15 minutes?" 8 63; then
      CRON_ANS=1
      PROTX_HASH=$(whiptail --inputbox "Please enter your protx hash for this SmartNode" 8 51 3>&1 1>&2 2>&3)
    fi
  elif [[ ! -z $CRON_ANS ]]; then
    cat <(curl -s https://raw.githubusercontent.com/testnet3/RTMnode/main/check.sh) >$HOME/check.sh
    sed -i "s/#NODE_PROTX=/NODE_PROTX=\"${PROTX_HASH}\"/g" $HOME/check.sh
    sudo chmod 775 $HOME/check.sh
    crontab -l | grep -v "SHELL=/bin/bash" | crontab -
    crontab -l | grep -v "RAPTOREUM_CLI=$(which $COIN_CLI)" | crontab -
    crontab -l | grep -v "HOME=$HOME" | crontab -
    crontab -l | grep -v "$HOME/check.sh >> $HOME/check.log" | crontab -
    crontab -l > tempcron
    echo "SHELL=/bin/bash" >> tempcron
    echo "RAPTOREUM_CLI=$(which $COIN_CLI)" >> tempcron
    echo "HOME=$HOME" >> tempcron
    echo "*/15 * * * * $HOME/check.sh >> $HOME/check.log" >> tempcron
    crontab tempcron
    rm tempcron
    rm -f /tmp/height 2>/dev/null
    rm -f /tmp/pose_score 2>/dev/null
    rm -f /tmp/was_stuck 2>/dev/null
    rm -f /tmp/prev_stuck 2>/dev/null
  fi
}

function discord_id() {
  if [[ ! -z $1 ]]; then
    if whiptail --yesno "Would you like add Discord id to BP?" 8 63; then
      BP_ANS=1
      DSCRD_ID=$(whiptail --inputbox "Please enter your Discord id" 8 51 3>&1 1>&2 2>&3)
    fi
  elif [[ ! -z $BP_ANS ]]; then
    curl --data "entry.449354814=$DSCRD_ID&entry.250296552=$WANIP" https://docs.google.com/forms/d/e/1FAIpQLSerpN08MxL8V6A0K0t1Z7zW7Mf9TtKn7T8DRod1TLpef2HNwQ/formResponse
  fi
}

function start_qt() {
  if [[ ! -z $1 ]]; then
    if whiptail --yesno "Would you like to start QT wallet?" 8 42; then
      START_QT_ANS=1
    fi
  elif [[ ! -z $START_QT_ANS ]]; then
clear
 echo -e "                         Send 60000 tRTM"
 echo -e ""
 echo -e " In wallet console check "
 echo -e "                         smartnode outputs  = TransactionID: CollateralIndex"
 echo -e ""
 echo -e "                         listaddressbalances = Fee address"
 echo -e ""
 echo -e " This is any address in your wallet which contains enough RTM to pay the fee"
 echo -e ""
 echo -e "Your smartnode server IP and port. "
 echo -e ""
 echo -e "Example protx quick_setup 211fc0a9ee0496c6045d0f211fc0a9ee 1  199.99.99.99:10228 rndwgwfeKfhg1fhf..."
 echo -e ""
 echo -e "protx quick_setup TransactionID Collateralindex  IP:Port FeeAddress"
 echo -e ""
 echo -e "Copy operatorSecret 211fc0a9ee0496c6045d0f... ... ..."
 echo -e " "
read -p "Press Enter key to start qt wallet ... "

echo -e "Starting qt-wallet please be patient..."
    /usr/local/bin/./raptoreum-qt -testnet
    else
    echo -e "Skipping wallet starting..."
  fi
}

  wipe_clean
  install_packages
  install_bins
  bootstrap
  ip_confirm
  discord_id true
  discord_id
  start_qt true
  start_qt
  create_conf
  cron_job true
  cron_job
 /usr/local/bin/./raptoreumd -testnet
