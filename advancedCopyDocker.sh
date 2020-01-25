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
destContainerPath(){
t=0
Q=()
while read -r nline; do
    let t=$t+1
    Q+=($t "$nline")
done < <( df | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '0+$4 >= 75000000 {print}' | awk '{print $6}' )
InstTYPE=$(whiptail --title "Choose an install path" --menu "Please choose an install path. These options all provide at least 75GB of free space for your masternode." 22 80 12 "${Q[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        newMatrixPath=$(readlink -f $(df | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '0+$4 >= 75000000 {print}' | awk '{print $6}' | sed -n "`echo "$InstTYPE p" | sed 's/ //'`") )
        if (whiptail --title "Confirmation" --yesno "You have chosen to install to \n\n${newMatrixPath}/matrixDocker\n\nLocated on the following device:\n\n$(df -h ${newMatrixPath})\n\nAre you sure?" 18 90 20); then
                :
        else
                whiptail --title "Matrix AI Network Installer" --msgbox "Please choose another option..." 12 80 && destContainerPath
        fi
fi
}
nameContainer(){
containerName=$(whiptail --title "Matrix AI Network Installer" --inputbox "Please choose a name for your container" 12 80 3>&1 1>&2 2>&3)
}
copyDocker(){
if [ -x "$(command -v docker)" ]; then
        :
else
        echo >&2 "Docker not installer, please choose new docker setup first"
        exit 1
fi
whiptail --title "Matrix AI Network - Installer" --msgbox "This installer option will help you copy your chaindata from an existing container to a new container. You should fully sync your existing node before copying. If you haven't finished syncing, please select no on the next screen and finish syncing first. For more advanced options please choose the advanced docker copy option." 14 100
confirm
whiptail --title "Matrix AI Network - Installer" --msgbox "FYI - When naming your containers and selecting port numbers for each, it would be smart to organize them by name and port number. For example: matrix50501 as a container name using port 50501 for the port number. That way you will always know which container is associate with which port. You CAN use any port, but stick to ports 50500-50600." 14 100
# select which container to copy docker
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( docker ps --format '{{.Names}}' )
ITYPE=$(whiptail --title "Select docker to copy" --menu "Please choose a current docker container where you would like to copy data from." 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        currentDocker=$(docker ps --format '{{.Names}}' | sed -n "`echo "$ITYPE p" | sed 's/ //'`")
	dockerMount=$(df -h $(docker inspect -f '{{ .Mounts }}' ${currentDocker} | awk {'print $2'}) | sed -n '2 p')
	if (whiptail --title "Confirmation" --yesno "You have chosen to copy from container:  ${currentDocker} \n\nLocated on the following device:\n${dockerMount} \n\nAre you sure?" 18 90 20); then
                :
        else
                whiptail --title "Matrix AI Network Installer" --msgbox "Installation is restarting..." 12 80 && copyDocker
        fi
fi
# set path for later use
copyFrom=$(docker inspect -f '{{ .Mounts }}' ${currentDocker} | awk {'print $2'})
# choose a destination path
tempMatrixPath=$(dirname -- "$(docker inspect -f "{{ .Mounts }}" ${currentDocker} | cut -d " " -f 3)" )
optionP=$(whiptail --title "Matrix AI Network - Installer" --menu "Would you like to install your new node in the same path as your existing node? \n\n${tempMatrixPath} \n\nLocated on the following device:\n\n$(df -h ${tempMatrixPath} | sed -n '2 p')" 18 100 2 "1" "yes" "2" "no" 3>&1 1>&2 2>&3)
if [[ "${optionP}" == "2" ]]; then
	destContainerPath
	matrixPath=${newMatrixPath}/matrixDocker
elif [[ "${optionP}" == "1" ]]; then
	matrixPath=${tempMatrixPath}
fi
# create container name
nameContainer
while ! [[ "$containerName" =~ ^[a-zA-Z0-9]+$ || $? -eq 1 ]]; do
        whiptail --title "ERROR" --msgbox "Please choose a container name using letters and numbers only" 8 57 && nameContainer
done
# create container directory
mkdir -p $matrixPath/$containerName
# set path for later use
copyTo=${matrixPath}/${containerName}
# choose port number to use for this container
portSelection=$(whiptail --title "Matrix AI Network - Installer" --inputbox "You will need to configure port forwarding in your router and each continaer must use a different port. It is suggested to use ports 50500-50600.\n\nPlease enter a port number" 12 80 3>&1 1>&2 2>&3)
# create signAccount file
manWallet=$(whiptail --title "Creating signAccount.json file..." --inputbox "Please enter your wallet B address" 12 80 3>&1 1>&2 2>&3)
whiptail --title "Creating signAccount.json file..." --msgbox "You are about to enter your Wallet B password. This is the password used to unlock your wallet." 12 80
manPasswd=$(whiptail --title "Creating signAccount.json file..." --inputbox "This password is stored in your signAccount.json file and is used to automatically create your entrust.json file each time your container is started.\n\nPlease enter your wallet B password" 12 80 3>&1 1>&2 2>&3)
echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/$containerName/signAccount.json
clear
# Copying the chaindata...
banner
lb
echo "Stopping container..."
docker stop ${currentDocker}
echo "Preparing to copy chaindata..."
sleep 3
mkdir $matrixPath/$containerName/keystore
mkdir $matrixPath/$containerName/snapdir
lb
echo "Copying chaindata from ${currentDocker} to ${containerName}"
lb
rsync -av --info=progress2 ${copyFrom}/gman ${copyTo}/
rsync -av --info=progress2 ${copyFrom}/picstore ${copyTo}/
touch ${copyTo}/firstRun
lb
rm ${copyTo}/gman/LOCK ${copyTo}/gman/nodekey ${copyTo}/gman/chaindata/LOCK
lb
echo "Starting original docker container..."
docker start ${currentDocker}
sleep 1
# create keystore wallet file
matrixKeystore=$(whiptail --title "Creating wallet B keystore file..." --inputbox "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below" 12 80 3>&1 1>&2 2>&3)
echo "$matrixKeystore" > $matrixPath/$containerName/keystore/${manWallet}
# check for container updates
echo "Checking for container updates..."
docker pull disarmm/matrix
lb
docker run -d -e MAN_PORT=${portSelection} -p ${portSelection}:${portSelection} -v $matrixPath/$containerName:/matrix/chaindata --name $containerName disarmm/matrix
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Docker Installation Complete!\n\n" 12 80
}
copyDocker
