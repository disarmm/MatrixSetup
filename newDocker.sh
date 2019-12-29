#!/bin/bash
set -e
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
newDocker(){
whiptail --title "Matrix AI Network - Installer" --msgbox "This installation type will install your matrix mining node as a new docker container with the snapshot at block 1405031. With this installation type, you will be able to run multiple nodes on this machine. If you need to install multiple docker nodes, it is recommended to fully sync with one node and then use the Docker Copy option at the main menu." 14 100
confirm
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 !~/M/ {print}' | awk '0+$4 >= 75 {print}' | awk '{print $6}' )
ITYPE=$(whiptail --title "Choose an install path" --menu "Please choose an install path. These options all provide at least 75GB of free space for your masternode." 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        matrixPath=$(readlink -f $(df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 !~/M/ {print}' | awk '0+$4 >= 75 {print}' | awk '{print $6}' | sed -n "`echo "$ITYPE p" | sed 's/ //'`") )
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
wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $matrixPath/matrixDocker/$containerName/1405031.tar.gz && tar -zxvf $matrixPath/matrixDocker/$containerName/1405031.tar.gz -C $matrixPath/matrixDocker/$containerName/
lb
mkdir $matrixPath/matrixDocker/$containerName/keystore
mv $matrixPath/matrixDocker/$containerName/chaindata/gman $matrixPath/matrixDocker/$containerName/
rm $matrixPath/matrixDocker/$containerName/MANGenesis.json
#mv $matrixPath/matrixDocker/$containerName/chaindata/picstore $matrixPath/matrixDocker/$containerName/
#rm -rf $matrixPath/matrixDocker/$containerName/chaindata
#rm $matrixPath/matrixDocker/$containerName/1405031.tar.gz


#rm $matrixPath/matrixDocker/$containerName/1405031.tar.gz
# create keystore wallet file
matrixKeystore=$(whiptail --title "Creating wallet B keystore file..." --inputbox "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below" 12 80 3>&1 1>&2 2>&3)
echo "$matrixKeystore" > $matrixPath/matrixDocker/$containerName/keystore/${manWallet}
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Docker Installation Complete!\n\n" 12 80
}
newDocker
