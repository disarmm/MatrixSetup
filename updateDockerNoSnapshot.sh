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
checkForContainerUpdate(){
if [ "$(docker pull disarmm/matrix | grep "Status: Image is up to date for disarmm/matrix:latest" | wc -l)" -eq 0 ]; then
	echo >&2 "Your docker container is already up-to-date"
	exit 1
fi
}
isDockerInstalled(){
if [ -x "$(command -v docker)" ]; then
        :
else
        echo >&2 "Docker not installer, please choose new docker setup first"
        exit 1
fi
}
updateDockerWithoutSnapshot(){
# keep working from here
whiptail --title "Matrix AI Network - Installer" --msgbox "This installer option will update your container image if an update is available. This will not touch your chaindata and will only update the container with the gman files needed to contining running your node." 14 100
confirm
isDockerInstalled
checkForContainerUpdate
# set path for later use
copyFrom=$(docker inspect -f '{{ .Mounts }}' ${currentDocker} | awk {'print $2'})
lb
echo "Stopping container..."
docker stop ${currentDocker}
# run container updates
echo "Updating container image..."
docker pull disarmm/matrix
lb
docker run -d -e MAN_PORT=${portSelection} -p ${portSelection}:${portSelection} -v $matrixPath/$containerName:/matrix/chaindata --name $containerName disarmm/matrix
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Docker Installation Complete!\n\n" 12 80
}
copyDocker
