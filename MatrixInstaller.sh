#!/bin/bash

#set script to exit on any errors
set -e

#create colors
RES=$(echo -en '\001\033[0m\002')
RED=$(echo -en '\001\033[00;31m\002')
GREEN=$(echo -en '\001\033[00;32m\002')
YELLOW=$(echo -en '\001\033[00;33m\002')
BLUE=$(echo -en '\001\033[00;34m\002')
LBLUE=$(echo -en '\001\033[01;34m\002')
MAGENTA=$(echo -en '\001\033[00;35m\002')
PURPLE=$(echo -en '\001\033[00;35m\002')
CYAN=$(echo -en '\001\033[00;36m\002')
WHITE=$(echo -en '\001\033[01;37m\002')

CRES='\001\033[0m\002'
CRED='\001\033[00;31m\002'
CGREEN='\001\033[00;32m\002'
CYELLOW='\001\033[00;33m\002'
CBLUE='\001\033[00;34m\002'
CLBLUE='\001\033[01;34m\002'
CMAGENTA='\001\033[00;35m\002'
CLMAGENTA='\001\033[01;35m\002'
CCYAN='\001\033[00;36m\002'
CWHITE='\001\033[01;37m\002'

# functions for later use
pause(){
	read -p "$*"
}
lb(){
	printf "\n"
}
banner(){
	echo ${LBLUE}
	curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/banner
	echo ${RES}
}
dline(){
	echo "${WHITE}-----------------------------------${RES}"
}
confirm (){
    	read -r -p "$(echo $@) " YESNO

    	if [ "$YESNO" != "y" ]; then
       		echo >&2 "${RED}INSTALLATION ABORTED!!${RES}"
        	exit 1
    	fi
}

clear
banner
sleep 2
lb
echo "This installer will help you install your Matrix Node to any hard drive partition that has ${RED}at least 40 GB of free space.${RES}" | fold -s
lb
echo "${RED}PLEASE READ EVERY PROMPT CAREFULLY TO AVOID DATA LOSS${RES}"
lb
echo "${WHITE} 
This installer will walk you through a few different types of installations. There are several steps that require confirmation before any files or data will be modified. Pressing Ctrl+C will halt the install any time before the ${YELLOW}POINT OF NO RETURN${WHITE}. You will also have several prompts that allow you to abort the install. Once you see the ${YELLOW}POINT OF NO RETURN${WHITE} you need to finish the install or your node may be left in a non-functioning state. If you have any questions or concerns, reach out to the community in telegram before proceeding. This installer is meant to replace the linux guides and should make things easier. Feedback is always welcome @pencekey." | fold -s
lb
read -rsp 'Press [Enter] key to continue...'
clear
banner
lb

# Fucntion for updating standalone installations that want to use the snapshot
updateStandaloneSnapshot()
{
clear
banner
lb
echo "This installation type will locate wherever you currently have your node installed and update the gman files necessary to continue mining. This option will also replace your chaindata with the snapshot from block 1405031. This option is not meant to be used with the docker installation. If you need to update your docker files, or would like to keep your existing chaindata, please restart this installer and choose the correct option." | fold -s
lb
confirm "${WHITE}Would you like to proceed? [y/n]${RES}"
findGman=( $(find / -name gman ! -type d) )
existingInstall=( $(echo "$(dirname -- "$findGman")" ) )
existingInstallPath="${WHITE}Please confirm your current masternode install path:${RES}"
lb
PS3="$existingInstallPath "
echo -en ${CGREEN}
select gmanPath in "${existingInstall[@]}" "${RED}Abort Install${RES}" ; do
    if (( REPLY == 1 + ${#existingInstall[@]} )) ; then
	exit
    elif (( REPLY > 0 && REPLY <= ${#existingInstall[@]} )) ; then
	lb
	echo -en ${CRES}
	echo "You have selected to update..."
	echo -en ${CGREEN}
	echo $gmanPath
	echo -en ${CRES}
	lb
	read -rsp 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
	lb
	echo -e "${RED}WARNING:${WHITE} This will erase your existing chaindata and replace it with the 1405031 snapshot${RES}"
	lb
	echo -e "You will need to sync from snapshot block 1405031 if you continue."
	echo -e "If you would like to ${WHITE}ONLY${RES} update your gman files and keep your existing chaindata, restart the setup, and choose option 3 instead." | fold -s
	dline
	echo -e "${RED}This will also stop your node if it is still running${RES}"
	sleep 1
	lb
	confirm "${YELLOW}Are you sure you would like to delete your chaindata and continue with the snapshot? [y/n]" 
	lb
	confirm "${RED}Seriously, this deletes your current chaindata. Are you 100% sure you would like to continue? [y/n]${RES}"
	lb
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
	echo "${YELLOW}POINT OF NO RETURN${RES}"
	sleep 2
	rm $gmanPath/gman $gmanPath/MANGenesis.json $gmanPath/firstRun
	mv $gmanPath/chaindata/keystore $gmanPath/keystore
	rm -rf $gmanPath/chaindata $gmanPath/snapdir
	lb
	wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $gmanPath/1405031.tar.gz && tar -zxvf $gmanPath/1405031.tar.gz -C $gmanPath/
	lb
        wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $gmanPath/gman && chmod a+x $gmanPath/gman
	lb
        wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $gmanPath/MANGenesis.json
	mv $gmanPath/keystore $gmanPath/chaindata/keystore
	rm $gmanPath/1405031.tar.gz
	clear
	banner
	lb
	echo "Please enter your wallet B address to create startup script"
	read manWallet
	# Create start script and set an alias so it will run from any path
        echo -e "#!/bin/bash\ncd $gmanPath\nif [ ! -f "$gmanPath/firstRun" ]; then\n      touch $gmanPath/firstRun && $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $gmanPath/gmanRunScript.sh
        echo -e "alias gman=/$gmanPath/gmanRunScript.sh" >> ~/.bashrc
        source ~/.bashrc
        clear
	echo -en "${CGREEN}"
        curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/completedBanner
        lb
        echo -en "${CWHITE}"
        echo "Please type ${RED}bash${WHITE} and hit enter to load your custom script"
        lb
        echo "${RES}After running ${RED}bash${RES}, you can now type ${RED}gman${RES} from any path to start your node"
	break
    else
	echo "Invalid option. Please try again."
    fi
done
}

# Fucntion for updating standalone installations WITHOUT using the snapshot
updateStandaloneOnlyGman()
{
clear
banner
lb
echo "This installation type will locate wherever you currently have your node installed and update the gman files necessary to continue mining. This verion will not replace your chaindata with the snapshot. This option is not meant to be used with the docker installation. If you need to update your docker files, or would like to use the snapshot, please restart this installer and choose the correct option." | fold -s
lb
confirm "${WHITE}Would you like to proceed? [y/n]${RES}"
findGman=( $(find / -name gman ! -type d) )
existingInstall=( $(echo "$(dirname -- "$findGman")" ) )
existingInstallPath="${WHITE}Please confirm your current masternode install path:${RES}"
lb
PS3="$existingInstallPath "
echo -en ${CGREEN}
select gmanPath in "${existingInstall[@]}" "${RED}Abort Install${RES}" ; do
    if (( REPLY == 1 + ${#existingInstall[@]} )) ; then
        exit
    elif (( REPLY > 0 && REPLY <= ${#existingInstall[@]} )) ; then
        lb
        echo -en ${CRES}
        echo "You have selected to update..."
        echo -en ${CGREEN}
        echo $gmanPath
        echo -en ${CRES}
        lb
        read -rsp 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
        lb
        echo -e "${WHITE} This will only update your gman and other critical files."
	echo -e "It WILL NOT touch your chaindata files.${RES}"
        lb
        dline
        echo -e "${RED}gman will be stoppped if it is still running${RES}"
        sleep 2
        lb
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
        rm $gmanPath/gman $gmanPath/MANGenesis.json $gmanPath/firstRun
	lb
        wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $gmanPath/gman && chmod a+x $gmanPath/gman
	lb
        wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $gmanPath/MANGenesis.json
        clear
        banner
        lb
	echo -en "${CWHITE}"
        echo "Please enter your wallet B address to create startup script"
	echo -en "${CRES}"
        read manWallet
        # Create start script and set an alias so it will run from any path
        echo -e "#!/bin/bash\ncd $gmanPath\nif [ ! -f "$gmanPath/firstRun" ]; then\n      touch $gmanPath/firstRun && $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $gmanPath/gmanRunScript.sh
        echo -e "alias gman=/$gmanPath/gmanRunScript.sh" >> ~/.bashrc
        source ~/.bashrc
        clear
	echo -en "${CGREEN}"
        curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/completedBanner
        lb
        echo -en "${CWHITE}"
        echo "Please type ${RED}bash${WHITE} and hit enter to load your custom script"
        lb
        echo "${RES}After running ${RED}bash${RES}, you can now type ${RED}gman${RES} from any path to start your node"
	lb
        break
    else
        echo "Invalid option. Please try again."
    fi
done
}

newStandalone()
{
clear
banner
lb
echo "This installation type will install your matrix mining node as a standalone node starting with the snapshot at block 1405031. With this installation type, you will not be able to run multiple nodes on this machine. If you would like to run multiple nodes now, or think you might in the future, it is best to start over and choose the new docker node setup." | fold -s
lb
confirm "${WHITE}Would you like to proceed? [y/n]${RES}"
newInstall=( $(df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 >= 40 {print}' | awk '$4 !~/M/ {print}' | awk '{print $6}') )
newInstallPath="${WHITE}Select a path to install your new Matrix Node:${RES}"
lb
PS3="$newInstallPath "
echo -en ${CGREEN}
select matrixPath in "${newInstall[@]}" "${RED}Abort Install${RES}" ; do
    if (( REPLY == 1 + ${#newInstall[@]} )) ; then
	exit

    elif (( REPLY > 0 && REPLY <= ${#newInstall[@]} )) ; then
        lb
	echo -en ${CRES}
        echo  "You have selected to install to..."
	echo -en ${CGREEN}
        df -h $matrixPath | sed -n '2 p'
	echo -en ${CRES}
        lb
        pause 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
	mkdir -p $matrixPath/matrix/
	lb
	echo "Creating signAccount.json file..."
	lb
	echo "${WHITE}Please enter your wallet B address below and hit enter${RES}"
	read manWallet
	lb
	echo -e "WARNING: YOUR WALLET B PASSWORD SHOULD BE DIFFERENT THAN YOUR WALLET A PASSWORD"
	lb
	echo -e "${RED}If your wallet B and wallet A password are the same, please abort with Ctrl+C and create a new wallet B${RES}" | fold -s
	echo -e "${RED}This password is stored only in your signAccount.json file, which is deleted after your entrust file is created${RES}" | fold -s
	lb
	confirm "Have you created a unique wallet B password? [y/n]"
	lb
	echo "${GREEN}Please enter your wallet B password below and hit enter${RES}"
	read manPasswd
	echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/matrix/signAccount.json
	#signAccount="[\n{\n"Address":"$manWallet",\n"Password":"$manPasswd"\n}\n]"
	#cat $matrixPath/matrix/signAccount.json
	#printf "%s\n" "[" "{" "\"Address\":\"$manWallet\"," "\"Password\":\"$manPasswd\"" "}" "]"
	lb
	echo "Downloading and installing files..."
	echo "${YELLOW}POINT OF NO RETURN${RES}"
	sleep 2
	lb
	wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $matrixPath/matrix/1405031.tar.gz && tar -zxvf $matrixPath/matrix/1405031.tar.gz -C $matrixPath/matrix/
	lb
        wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $matrixPath/matrix/gman && chmod a+x /$matrixPath/matrix/gman
	lb
        wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $matrixPath/matrix/MANGenesis.json
	mkdir $matrixPath/matrix/chaindata/keystore
	rm $matrixPath/matrix/1405031.tar.gz
        clear
        banner
	lb
	echo "Creating entrust.json file..."
	lb
	echo "${WHITE}This password is the password used for starting your node. It should be different than the password you use to unlock your wallet in the wallet app. Please choose a password that is different than the password used to unlock your wallet A or wallet B in the wallet app." | fold -s
	echo -en "${CRED}"
	lb
	read -rsp '	Press [Return] if you understand'
	echo -en "${CRES}"
	lb
	$matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata aes --aesin $matrixPath/matrix/signAccount.json --aesout $matrixPath/matrix/entrust.json
	rm $matrixPath/matrix/signAccount.json
	lb
	echo -en "${CWHITE}"
	echo "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below, then press enter"
	echo -en "${CRES}"
	read matrixKeystore
	echo "$matrixKeystore" > $matrixPath/matrix/chaindata/keystore/wallet.file
	echo -e "#!/bin/bash\ncd $matrixPath/matrix\nif [ ! -f "$matrixPath/matrix/firstRun" ]; then\n      touch $matrixPath/matrix/firstRun && $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust /$matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $matrixPath/matrix/gmanRunScript.sh
	chmod 775 $matrixPath/matrix/gmanRunScript.sh
	echo "alias gman=/$matrixPath/matrix/gmanRunScript.sh" >> ~/.bashrc
	source ~/.bashrc
	clear
	echo -en "${CGREEN}"
	curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/completedBanner
	lb
	echo -en "${CWHITE}"
	echo "Please type ${RED}bash${WHITE} and hit enter to load your custom script"
	lb
	echo "${RES}After running ${RED}bash${RES}, you can now type ${RED}gman${RES} from any path to start your node"
	lb
	break
    else
        echo "Invalid option. Try again."
    fi
done
}

updateDocker()
{
existingDocker=( $(find / -name gman ! -type d) )
existingDockerPath="Please confirm your current masternode install path:"
lb
#PS3="$existingDockerPath "
#select gmanPath in "${existingDocker[@]}" "Abort Install" ; do
#    if (( REPLY == 1 + ${#existingDocker[@]} )) ; then
#        exit
#    elif (( REPLY > 0 && REPLY <= ${#existingDocker[@]} )) ; then
#        lb
#        echo "You have selected to update..."
#        echo $gmanPath
#        lb
#        pause 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
#        lb
#        echo "WARNING: This will erase your existing chaindata and replace it with the 1405031 snapshot"
#        dline
#        echo "This will also stop your node if it is still running"
#        sleep 1
#        pause '    Press [Enter] again to confirm or Ctrl+C to abort'
#        lb
#        kill -9 $(pgrep gman)
#        echo "Downloading and install files..."
#        sleep 2
#        rm $gmanPath/gman $gmanPath/MANGenesis.json $gmanPath/firstRun
#        mv $gmanPath/chaindata/keystore $gmanPath/keystore
#        rm -rf $gmanPath/chaindata $gmanPath/snapdir
#        wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $gmanPath/1405031.tar.gz && tar -zxvf $gmanPath/1405031.tar.gz -C $gmanPath/
#        wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $gmanPath/gman && chmod a+x $gmanPath/gman
#        wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $gmanPath/MANGenesis.json
#        mv $gmanPath/keystore $gmanPath/chaindata/keystore
#        clear
#        banner
#        lb
#        echo "Please enter your wallet B address to create startup script"
#        read manWallet
#        echo -e "if [ ! -f "$gmanPath/firstRun" ]; then\n      touch $gmanPath/firstRun && $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $gmanPath/gman --datadir $gmanPath/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $gmanPath/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $gmanPath/gmanRunScript.sh
#        echo -e "alias gman=/$gmanPath/gmanRunScript.sh" >> ~/.bashrc
#        source ~/.bashrc
#        clear
#        curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/completedBanner
#        lb
#        echo "You can now type gmanMatrix from any path to start your node"
#        break
#    else
#        echo "Invalid option. Please try again."
#    fi
#done
}

newDocker()
{
newDocker=( $(df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 >= 150 {print}' | awk '$4 !~/M/ {print}' | awk 'length($4) >= 4 {print}' | awk '{print $6}') )
newDockerPath="Select a path to install your new Matrix Node:"
lb
#PS3="$newDockerPath "
#select matrixPath in "${newDocker[@]}" "Abort Install" ; do
#    if (( REPLY == 1 + ${#newDocker[@]} )) ; then
#        exit
#
#    elif (( REPLY > 0 && REPLY <= ${#newDocker[@]} )) ; then
#        lb
#        echo  "You have selected to install to..."
#        df -h $matrixPath | sed -n '2 p'
#        lb
#        pause 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
#        mkdir -p $matrixPath/matrix/
#        lb
#        echo "Creating SignAccount.json file..."
#        lb
#        echo "Please enter your wallet B address"
#        read manWallet
#        lb
#        echo "WARNING: YOUR WALLET B PASSWORD SHOULD BE DIFFERENT THAN YOUR WALLET A PASSWORD"
#        lb
#        echo "If your wallet B and wallet A password are the same, please abort with Ctrl+C and create a new wallet B"
#        lb
#        echo "Please enter your wallet B password"
#        read manPasswd
#        echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/matrix/signAccount.json
#        lb
#        echo "Downloading and installing files..."
#        sleep 2
#        wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $matrixPath/matrix/1405031.tar.gz && tar -zxvf $matrixPath/matrix/1405031.tar.gz -C $matrixPath/matrix/
#        wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $matrixPath/matrix/gman && chmod a+x /$matrixPath/matrix/gman
#        wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $matrixPath/matrix/MANGenesis.json
#        mkdir $matrixPath/matrix/chaindata/keystore
#        clear
#        banner
#        lb
#        echo "Creating entrust.json file..."
#        lb
#        echo "Note: Please choose a different password than your Wallet B password"
#        sleep 1
#        lb
#        pause '         Press [Return] to continue]'
#        $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata aes --aesin $matrixPath/matrix/signAccount.json --aesout $matrixPath/matrix/entrust.json
#        echo "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below"
#        read matrixKeystore
#        echo -e "$matrixKeystore" > $matrixPath/matrix/chaindata/keystore/wallet.file
#        echo -e "if [ ! -f "$matrixPath/matrix/firstRun" ]; then\n      touch $matrixPath/matrix/firstRun && $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust /$matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $matrixPath/matrix/gmanRunScript.sh
#        echo -e "alias gmanMatrix=/$matrixPath/gmanRunScript.sh" >> ~/.bashrc
#        source ~/.bashrc
#        clear
#        curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/completedBanner
#        lb
#        echo "Type gmanMatrix to start your new node"
#        break
#    else
#        echo "Invalid option. Try again."
#    fi
#done
}

standaloneUpdatePrompt()
{
	lb
                PS3="$upgradePrompt "
		echo -en ${CGREEN}
                select sug in "New Install" "Update Existing With Snapshot" "Update Existing Without Snapshot"; do
                        case $sug in
				"New Install") newStandalone; exit;;
                                "Update Existing With Snapshot") updateStandaloneSnapshot; exit;;
				"Update Existing Without Snapshot") updateStandaloneOnlyGman; exit;;
                        esac
                done
		echo -en ${CRES}
}

DockerUpdatePrompt()
{
        lb
                PS3="$upgradePrompt "
		echo -en ${GREEN}
                select dug in "New install" "Update Existing With Snapshot" "Update Existing Without Snapshot"; do
                        case $dug in
                                "New Install") newDockere; exit;;
                                "Update Existing With Snapshot") updateDockerSnapshot; exit;;
				"Update Existing Without Snapshot") updateDockerOnlyGman; exit;;
                        esac
                done
		echo -en ${RES}
}

installType="${WHITE}Is this a single node(Standalone) or will you be using docker for multiple nodes?${RES}"
upgradePrompt="${WHITE}Are you updating your existing node or deploying a new node?${RES}"
PS3="$installType "
echo -en ${CGREEN}
select t in "Standalone" "Docker"; do
    case $t in
        Standalone ) standaloneUpdatePrompt; exit;;
        Docker ) dockerUpdatePrompt; exit;;
    esac
done
echo -en ${CRES}


