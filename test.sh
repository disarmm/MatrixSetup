#!/bin/bash
pause(){
        read -p "$*"
}
nameContainer(){
containerName=$(whiptail --title "Matrix AI Network Installer" --inputbox "Please choose a name for your container" 12 80 3>&1 1>&2 2>&3)
}
containerName=!@#$
while ! [[ "$containerName" =~ ^[a-zA-Z0-9]+$ || $? -eq 1 ]]; do
        whiptail --title "ERROR" --msgbox "Please choose a container name using letters and numbers only" 8 57 && nameContainer
done
