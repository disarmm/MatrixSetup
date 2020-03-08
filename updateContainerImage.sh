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
else
	echo "Container updated"
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
updateContainerOnly(){
if [ -x "$(command -v docker)" ]; then
        :
else
        echo >&2 "Docker not installed, please choose new docker setup first"
        exit 1
fi
whiptail --title "Matrix AI Network - Updater" --msgbox "This option will update your container image without modifying any of your chaindata IF an image update is available. It will then recreate your existing containers with the new image using the same ports and chaindata as before. This should not be run if you have containers for anything other than matrix nodes. \n\n(Confirm on next screen)" 14 100
confirm
# check if docker is installed
isDockerInstalled
# Check if update is needed
checkForContainerUpdate

lb
# Pull current container info and recreate with new image
for cont in $(docker ps -a --format '{{.Names}}') ; do
	echo "Updating container..."
        contPort=$(docker inspect -f '{{.HostConfig.PortBindings}}' $cont | cut -d "[" -f 2 | cut -d "/" -f 1)
        hostVol=$(docker inspect -f '{{ .Mounts }}' $cont | cut -d " " -f 3)
	docker stop $cont && docker rm $cont
        docker run -d --restart unless-stopped -e MAN_PORT=${contPort} -p ${contPort}:${contPort} -v ${hostVol}:/matrix/chaindata --name $cont disarmm/matrix
	lb
done
# finished!
whiptail --title "Matrix AI Network - Updater" --msgbox "     Container Image updated!\n\n" 12 80
}
updateContainerOnly

