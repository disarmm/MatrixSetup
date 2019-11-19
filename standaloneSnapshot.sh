#!/bin/bash
set -e
# some colors
RES=$(echo -en '\001\033[0m\002')
LBLUE=$(echo -en '\001\033[01;34m\002')
# various functions to reuse
lb(){
printf "\n"
}
banner(){
	echo ${LBLUE}
	curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/banner
	echo ${RES}
}
confirm (){
if (whiptail --title "Confirmation" --yesno "Please confirm you wish to continue" 8 75); then
:
else
echo >&2 "INSTALLATION ABORTED!!"
exit 1
fi
}
# define functions for different install types

updateStandaloneSnapshot()
{
clear
whiptail --title "Matrix AI Network - Installer" --msgbox "This installation type will locate wherever you currently have your node installed and update the gman files necessary to continue mining. This option will also replace your chaindata with the snapshot from block 1405031. This option is NOT meant to be used with the docker installation. If you need to update your docker files, or would like to keep your existing chaindata, please restart this installer and choose the correct option." 14 100
confirm
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( find / -name gman ! -type d )
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
if [ -z "$(pgrep gman)" ]
then
echo "gman is stopped"
else
echo "gman is still running" && lb && echo "Killing gman" && kill -9 $(pgrep gman)
fi
sleep 2
clear
banner
lb
echo "Downloading and install files..."
sleep 2
# clean up old files
rm $gmanPath/gman $gmanPath/MANGenesis.json $gmanPath/firstRun
mv $gmanPath/chaindata/keystore $gmanPath/keystore
rm -rf $gmanPath/chaindata $gmanPath/snapdir
# download new files
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
echo -e "#!/bin/bash\ncd $gmanPath\nif [ ! -f "$gmanPath/firstRun" ]; then\n      touch $gmanPath/firstRun && $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $gmanPath/gmanRunScript.sh
# copy start script
cp $gmanPath/gmanRunScript.sh /usr/local/bin/gmanClient
# finished!
whiptail --title "Matrix AI Network - Installer" --msgbox "     Installation Complete!\n\nYou can type gmanClient from any path and your Matrix node will start magically" 20 80
}
updateStandaloneSnapshot
