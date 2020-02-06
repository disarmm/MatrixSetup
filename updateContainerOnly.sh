#!/bin/bash
set -e
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
updateContainerOnly(){
if [ -x "$(command -v docker)" ]; then
        :
else
        echo >&2 "Docker not installer, please choose new docker setup first"
        exit 1
fi
whiptail --title "Matrix AI Network - Updater" --msgbox "This option will update your container image without modifying any of your chaindata. It will recreate your container after the update using the same ports and chaindata as before. \n\n(Confirm on next screen)" 14 100
confirm

# Updating container image
docker pull disarmm/matrix

# Pull current container info and recreate with new image
for cont in $(docker ps -a --format '{{.Names}}') ; do
	contPort=$(docker inspect -f '{{.HostConfig.PortBindings}}' $cont | cut -d "[" -f 2 | cut -d "/" -f 1)
	hostVol=$(docker inspect -f '{{ .Mounts }}' B36 | cut -d " " -f 3)
	docker rm $cont
	docker run -d -e MAN_PORT=${contPort} -p ${contPort}:${contPort} -v ${hostVol}:/matrix/chaindata --name $cont disarmm/matrix
done
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Docker Installation Complete!\n\n" 12 80
}
updateContainerOnly
