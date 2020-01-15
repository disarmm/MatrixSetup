#!/bin/bash

# check if user has sudo/root privileges
if [ $(whoami) != root ]; then
  echo "Please run as root or use sudo"
  exit
fi

#set script to exit on any errors
set -e

# install dependencies
apt install whiptail curl wget -y

# some colors
RES=$(echo -en '\001\033[0m\002')
LBLUE=$(echo -en '\001\033[01;34m\002')

# functions for later use
pause(){
	read -p "$*"
}
banner(){
        echo ${LBLUE}
        curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/banner
        echo ${RES}
}
lb(){
	printf "\n"
}
confirm(){
	if (whiptail --title "Confirmation" --yesno "Please confirm you wish to continue" 8 75); then
		:
	else
		echo >&2 "INSTALLATION ABORTED!!"
        	exit 1
    	fi
}
nameContainer(){
containerName=$(whiptail --title "Matrix AI Network Installer" --inputbox "Please choose a name for your container" 12 80 3>&1 1>&2 2>&3)
}

# intro stuff
whiptail --title "Matrix AI Network Installer" --msgbox "This installer will help you install your Matrix Node to any hard drive partition that has at least 100 GB of free space." 8 65
whiptail --title "Matrix AI Network Installer" --msgbox "PLEASE READ EVERY PROMPT CAREFULLY TO AVOID DATA LOSS" 8 57
whiptail --title "Matrix AI Network Installer" --msgbox "This installer will walk you through a few different types of installations. There are several steps that require confirmation before any files or data will be modified. Pressing [Esc] will halt the install and you will have several prompts that allow you to abort the install. If you have any questions or concerns, reach out to the community in telegram before proceeding. This installer is meant to replace the linux guides and should make things easier. Feedback is always welcome @pencekey on telegram." 14 100

# define functions for different install types
newStandalone(){
whiptail --title "Matrix AI Network - Installer" --msgbox "This installation type will install your matrix mining node as a standalone node starting with the snapshot at block 1405031. With this installation type, you will not be able to run multiple nodes on this machine. If you would like to run multiple nodes now, or think you might in the future, it is best to start over and choose the new docker node setup." 14 100
confirm
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( df | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '0+$4 >= 75000000 {print}' | awk '{print $6}' )
ITYPE=$(whiptail --title "Choose an install path" --menu "Please choose an install path. These options all provide at least 75GB of free space for your masternode." 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        matrixPath=$(readlink -f $(df | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '0+$4 >= 75000000 {print}' | awk '{print $6}' | sed -n "`echo "$ITYPE p" | sed 's/ //'`") )
        if (whiptail --title "Confirmation" --yesno "You have chosen to install to \n\n${matrixPath}/matrix\n\n$(df -h ${matrixPath}) \n\nAre you sure?" 18 90 20); then
                :
        else
                whiptail --title "Matrix AI Network Installer" --msgbox "Installation is restarting..." 12 80 && newStandalone
        fi
fi
if [ -d ${matrixPath}/matrix ]; then
	whiptail --title "WARNING" --msgbox "${matrixPath}/matrix path already exists, please choose different path or installation type" 12 80 && newStandalone
fi
# create signAccount file
manWallet=$(whiptail --title "Creating signAccount.json file..." --inputbox "Please enter your wallet B address" 12 80 3>&1 1>&2 2>&3)
whiptail --title "Creating signAccount.json file..." --msgbox "You are about to enter your Wallet B password. This is the password used to unlock your wallet.\n\nYOUR WALLET B PASSWORD SHOULD BE DIFFERENT THAN YOUR WALLET A PASSWORD" 12 80
manPasswd=$(whiptail --title "Creating signAccount.json file..." --inputbox "This password is stored only in your signAccount.json file, which is deleted after your entrust file is created.\n\nPlease enter your wallet B password" 12 80 3>&1 1>&2 2>&3)
mkdir -p $matrixPath/matrix/
echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/matrix/signAccount.json
clear
# another obvious section.. downloading the files...
banner
lb
echo "Downloading and installing files..."
sleep 2
lb
wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $matrixPath/matrix/1405031.tar.gz && tar -zxvf $matrixPath/matrix/1405031.tar.gz -C $matrixPath/matrix/
lb
wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $matrixPath/matrix/gman && chmod a+x /$matrixPath/matrix/gman
lb
wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $matrixPath/matrix/MANGenesis.json
lb
mkdir $matrixPath/matrix/chaindata/keystore
rm $matrixPath/matrix/1405031.tar.gz
# create encrypted entrust file
whiptail --title "Creating entrust.json file..." --msgbox "On the next page you will be creating the password used to start your node. It should be different than the password you use to unlock your wallet in the wallet app. Please choose a password that is different than the password used to unlock your wallet A or wallet B in the wallet app." 12 80
# running gman command to create entrust file
clear
banner
echo "Creating entrust.json file..."
lb
$matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata aes --aesin $matrixPath/matrix/signAccount.json --aesout $matrixPath/matrix/entrust.json
# removing plain text signAccount.json
rm $matrixPath/matrix/signAccount.json
# create keystore wallet file
matrixKeystore=$(whiptail --title "Creating wallet B keystore file..." --inputbox "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below" 12 80 3>&1 1>&2 2>&3)
echo "$matrixKeystore" > $matrixPath/matrix/chaindata/keystore/${manWallet}
# creating easy startup script
echo -e "#!/bin/bash\ncd $matrixPath/matrix\nif [ ! -f "$matrixPath/matrix/firstRun" ]; then\n      touch $matrixPath/matrix/firstRun && $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust /$matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $matrixPath/matrix/gmanClient.sh
chmod 775 $matrixPath/matrix/gmanClient.sh
# copy start script
cp $matrixPath/matrix/gmanClient.sh /usr/local/bin/gmanClient
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Installation Complete!\n\nYou can type gmanClient from any path and your Matrix node will start magically" 12 80
}

updateStandaloneSnapshot()
{
whiptail --title "Matrix AI Network Installer" --msgbox "This installation type will locate wherever you currently have your node installed and update the gman files necessary to continue mining. This option will also replace your chaindata with the snapshot from block 1405031. This option is not meant to be used with the docker installation. If you need to update your docker files, or would like to keep your existing chaindata, please restart this installer and choose the correct option." 14 100
confirm
# perform pre-check for previous installations
if [ $(find / -name gman ! -type d | wc -l) -eq 0 ]; then
        whiptail --title "ERROR" --msgbox "The installer cannot find any previous installations. Please install using option 1 or contact @pencekey for help on telegram"
        exit 1
fi
echo "Searching for previous installations. Please wait..."
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( find / -name gman ! -type d )
clear
IPATH=$(whiptail --title "Matrix AI Network - Installer" --menu "The following paths have been identified as previous installations.\n\nPlease select the Matrix path you would like to update" 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        installedPath=$(readlink -f $(find / -name gman ! -type d  | sed -n "`echo "$IPATH p" | sed 's/ //'`") )
        if (whiptail --title "Confirmation" --yesno "You have chosen to update \n\n${installedPath} \n\nAre you sure?" 18 90 20); then
                :
        else
                updateStandaloneSnapshot
        fi
fi
gmanPath=( $(echo "$(dirname -- "$installedPath")" ) )
# warn that this kills gman
if (whiptail --title "Matrix AI Network - Installer" --yesno "This will also stop your node if it is still running\n\nWould you like to proceed?" 12 80); then
        :
else
        echo >&@ "INSTALLATION ABORTED!!"
        exit 1
fi
# confirm
if (whiptail --title "Confirmation" --yesno "Are you sure you would like to delete your chaindata and continue with the snapshot?" 8 75); then
        :
else
        echo >&2 "INSTALLATION ABORTED!!"
        exit 1
fi
# confirm again
if (whiptail --title "Confirmation" --yesno "Seriously, this deletes your current chaindata. Are you 100% sure you would like to continue?" 8 75); then
        :
else
        echo >&2 "INSTALLATION ABORTED!!"
        exit 1
fi
# check if gman is stopped
if [ -z "$(pgrep gman)" ]; then
        echo "gman is stopped"
else
        echo "gman is still running" && lb && echo "Killing gman" && kill -9 $(pgrep gman)
fi
sleep 2
clear
banner
lb
echo "Cleaning up old files..."
sleep 2
lb
# clean up old files if they exist
if [ -f "${gmanPath}"/gman ]; then
        echo "Removing gman..." && sleep 1 && rm $gmanPath/gman
fi
if [ -f "${gmanPath}"/MANGenesis.json ]; then
        echo "Removing MANGenesis.json..." && sleep 1 && rm $gmanPath/MANGenesis.json
fi
if [ -f "${gmanPath}"/firstRun ]; then
        echo "Removing firstRun..." && sleep 1 && rm $gmanPath/firstRun
fi
lb
echo "Backing up keystore..."
mv $gmanPath/chaindata/keystore $gmanPath/keystore
lb
echo "Removing old chaindata..."
rm -rf $gmanPath/chaindata $gmanPath/snapdir
# download new files
lb
echo "Downloading new files..."
sleep 2
lb
wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $gmanPath/1405031.tar.gz && tar -zxvf $gmanPath/1405031.tar.gz -C $gmanPath/
lb
wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $gmanPath/gman && chmod a+x $gmanPath/gman
lb
wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $gmanPath/MANGenesis.json
mv $gmanPath/keystore $gmanPath/chaindata/keystore
rm $gmanPath/1405031.tar.gz
manWallet=$(whiptail --title "Creating gman startup script..." --inputbox "Please enter your wallet B address to create startup script" 12 80 3>&1 1>&2 2>&3)
# Create start script and set an alias so it will run from any path
echo -e "#!/bin/bash\ncd $gmanPath\nif [ ! -f "$gmanPath/firstRun" ]; then\n      touch $gmanPath/firstRun && $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $gmanPath/gmanClient.sh
chmod 755 $gmanPath/gmanClient.sh
# copy start script
cp $gmanPath/gmanClient.sh /usr/local/bin/gmanClient
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Installation Complete!\n\nYou can type gmanClient from any path and your Matrix node will start magically" 12 80
}

# Fucntion for updating standalone installations WITHOUT using the snapshot
updateStandaloneOnlyGman()
{
clear
whiptail --title "Matrix AI Network - Installer" --msgbox "This installation type will locate wherever you currently have your node installed and update the gman files necessary to continue mining. This verion will not replace your chaindata with the snapshot. This option is not meant to be used with the docker installation. If you need to update your docker files, or would like to use the snapshot, please restart this installer and choose the correct option." 14 100
confirm
 # perform pre-check for previous installations
if [ $(find / -name gman ! -type d | wc -l) -eq 0 ]; then
	whiptail --title "ERROR" --msgbox "The installer cannot find any previous installations. Please install using option 1 or contact @pencekey for help on telegram"
	exit 1
fi
echo "Searching for previous installations. Please wait..."
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( find / -name gman ! -type d )
clear
IPATH=$(whiptail --title "Matrix AI Network - Installer" --menu "The following paths have been identified as previous installations.\n\nPlease select the Matrix path you would like to update" 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        installedPath=$(readlink -f $(find / -name gman ! -type d  | sed -n "`echo "$IPATH p" | sed 's/ //'`") )
        if (whiptail --title "Confirmation" --yesno "You have chosen to update \n\n${installedPath} \n\nAre you sure?" 18 90 20); then
                :
	else
		updateStandaloneOnlyGman
        fi
fi
gmanPath=( $(echo "$(dirname -- "$installedPath")" ) )
# warn that it kills gman
if (whiptail --title "Matrix AI Network - Installer" --yesno "This will also stop your node if it is still running\n\nWould you like to proceed?" 12 80); then
        :
else
        echo >&@ "INSTALLATION ABORTED!!"
        exit 1
fi
# check if gman is stopped
if [ -z "$(pgrep gman)" ]; then
	echo "gman is stopped"
else
	echo "gman is still running" && lb && echo "Killing gman" && kill -9 $(pgrep gman)
fi
sleep 2
clear
banner
lb
echo "Cleaning up old files..."
sleep 2
lb
# clean up old files if they exist
if [ -f "${gmanPath}"/gman ]; then
        echo "removing gman..." && sleep 1 && rm $gmanPath/gman
fi
if [ -f "${gmanPath}"/MANGenesis.json ]; then
        echo "removing MANGenesis.json..." && sleep 1 && rm $gmanPath/MANGenesis.json
fi
lb
echo "Downloading new files..."
# download new files
lb
wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $gmanPath/gman && chmod a+x $gmanPath/gman
lb
wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $gmanPath/MANGenesis.json
# get address for startup script
manWallet=$(whiptail --title "Creating gman startup script..." --inputbox "Please enter your wallet B address to create startup script" 12 80 3>&1 1>&2 2>&3)
echo -e "#!/bin/bash\ncd $gmanPath\nif [ ! -f "$gmanPath/firstRun" ]; then\n      touch $gmanPath/firstRun && $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $gmanPath/gmanClient.sh
chmod 755 $gmanPath/gmanClient.sh
# copy start script
cp $gmanPath/gmanClient.sh /usr/local/bin/gmanClient
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Installation Complete!\n\nYou can type gmanClient from any path and your Matrix node will start magically" 12 80
}
newDocker(){
whiptail --title "Matrix AI Network - Installer" --msgbox "This installation type will install your matrix mining node as a new docker container with the snapshot at block 1784250. With this installation type, you will be able to run multiple nodes on this machine. If you need to install multiple docker nodes, it is recommended to fully sync with one node and then use the Docker Copy option at the main menu." 14 100
whiptail --title "Matrix AI Network - Installer" --msgbox "When naming your containers and selecting port numbers for each, it would be smart to organize them by name and port number. For example: matrix50501 for a container name and port 50501 for the port number. That way you will always know which container is associate with which port." 14 100
confirm
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( df | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '0+$4 >= 75000000 {print}' | awk '{print $6}' )
ITYPE=$(whiptail --title "Choose an install path" --menu "Please choose an install path. These options all provide at least 75GB of free space for your masternode." 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        matrixPath=$(readlink -f $(df | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '0+$4 >= 75000000 {print}' | awk '{print $6}' | sed -n "`echo "$ITYPE p" | sed 's/ //'`") )
        if (whiptail --title "Confirmation" --yesno "You have chosen to install to \n\n${matrixPath}/matrixDocker\n\n$(df -h ${matrixPath}) \n\nAre you sure?" 18 90 20); then
                :
        else
                whiptail --title "Matrix AI Network Installer" --msgbox "Installation is restarting..." 12 80 && newDocker
        fi
fi
if [ -d ${matrixPath}/matrixDocker ]; then
        whiptail --title "WARNING" --msgbox "${matrixPath}/matrixDocker path already exists. If you need to create another node, please use the Docker Copy installation type." 12 80 && newDocker
fi
# create container name
nameContainer
while ! [[ "$containerName" =~ ^[a-zA-Z0-9]+$ || $? -eq 1 ]]; do
        whiptail --title "ERROR" --msgbox "Please choose a container name using letters and numbers only" 8 57 && nameContainer
done
# create container directory
mkdir -p $matrixPath/matrixDocker/$containerName
# choose port number to use for this container
portSelection=$(whiptail --title "Matrix AI Network - Installer" --inputbox "You will need to configure port forwarding in your router and each continaer must use a different port. It is suggested to use ports 50500-50600.\n\nPlease enter a port number" 12 80 3>&1 1>&2 2>&3)
# create signAccount file
manWallet=$(whiptail --title "Creating signAccount.json file..." --inputbox "Please enter your wallet B address" 12 80 3>&1 1>&2 2>&3)
whiptail --title "Creating signAccount.json file..." --msgbox "You are about to enter your Wallet B password. This is the password used to unlock your wallet." 12 80
manPasswd=$(whiptail --title "Creating signAccount.json file..." --inputbox "This password is stored in your signAccount.json file and is used to automatically create your entrust.json file each time your container is started.\n\nPlease enter your wallet B password" 12 80 3>&1 1>&2 2>&3)
echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/matrixDocker/$containerName/signAccount.json
clear
# another obvious section.. downloading the files...
banner
lb
if [ -x "$(command -v docker)" ]; then
        echo "Docker already installed"
        echo "Moving on..."
else
        echo "Docker not installed"
        echo "Installing docker..."
        bash < <(curl https://get.docker.com)
fi
lb
echo "Downloading and installing matrix files..."
lb
mkdir $matrixPath/matrixDocker/$containerName/keystore
mkdir $matrixPath/matrixDocker/$containerName/snapdir
wget www2.matrixainetwork.eu/snapshots/1784250.tar.gz -O $matrixPath/matrixDocker/$containerName/1784250.tar.gz && tar -zxvf $matrixPath/matrixDocker/$containerName/1784250.tar.gz -C $matrixPath/matrixDocker/$containerName/snapdir
lb
rm $matrixPath/matrixDocker/$containerName/1784250.tar.gz


#rm $matrixPath/matrixDocker/$containerName/1405031.tar.gz
# create keystore wallet file
matrixKeystore=$(whiptail --title "Creating wallet B keystore file..." --inputbox "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below" 12 80 3>&1 1>&2 2>&3)
echo "$matrixKeystore" > $matrixPath/matrixDocker/$containerName/keystore/${manWallet}
docker pull disarmm/matrix
lb
docker run -d -e MAN_PORT=${portSelection} -p ${portSelection}:${portSelection} -v $matrixPath/matrixDocker/$containerName:/matrix/chaindata --name $containerName disarmm/matrix
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Docker Installation Complete!\n\n" 12 80
}
manChoice=$(
whiptail --title "Matrix AI Network Installer" --menu "How do you like your MAN?" 20 90 8 \
	'1)' "Standalone - New intall with latest snapshot" \
	'2)' "Standalone - Upgrade current install with snapshot" \
	'3)' "Standalone - Upgrade current install without snapshot" \
	'4)' "Docker - New install with latest snapshot" \
	'5)' "Docker - Upgrade current install with snapshot(coming soon)" \
	'6)' "Docker - Upgrade current install without snapshot(coming soon)" \
	'7)' "Docker - Copy node" \
	'8)' "exit" 3>&2 2>&1 1>&3
)

case $manChoice in
	"1)")
		newStandalone
		;;
	"2)")
		updateStandaloneSnapshot
		;;
	"3)")
		updateStandaloneOnlyGman
		;;
	"4)")
		newDocker
		;;
	"5)")
                echo "Docker Installs Coming Soon"
                exit
                ;;
	"6)")
                echo "Docker Installs Coming Soon"
                exit
                ;;
	"7)")
                echo "Docker Installs Coming Soon"
                exit
                ;;
	"8)")
                exit
                ;;
esac
