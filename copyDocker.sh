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
copyDocker(){
whiptail --title "Matrix AI Network - Installer" --msgbox "This will let you copy existing containers to create new ones using your current chaindata. Before copying, you should full sync your node and then chose this copy option. " 14 100
confirm
whiptail --title "Matrix AI Network - Installer" --msgbox "FYI - When naming your containers and selecting port numbers for each, it would be smart to organize them by name and port number. For example: matrix50501 for a container name and port 50501 for the port number. That way you will always know which container is associate with which port. You can use any port, but stick to ports 50500-50600." 14 100
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( docker ps --format '{{.Names}}' )
ITYPE=$(whiptail --title "Select docker to copy" --menu "Please choose a current docker container where you would like to copy daya from." 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
        currentDocker=$(docker ps --format '{{.Names}}' | sed -n "`echo "$ITYPE p" | sed 's/ //'`")
        if (whiptail --title "Confirmation" --yesno "You have chosen to copy from container \n\n${currentDocker} \n\nAre you sure?" 18 90 20); then
                :
        else
                whiptail --title "Matrix AI Network Installer" --msgbox "Installation is restarting..." 12 80 && newDocker
        fi
fi
echo "$(docker inspect -f "{{ .Mounts }}" ${currentDocker} | cut -d " " -f 3)"
asd
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
copyDocker
