#!/bin/bash

# functions for later use
function pause(){
	read -p "$*"
}
function lb(){
	printf "\n"
}
function banner(){
	curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/banner
}

clear
banner
lb
echo "This installer will help you install your Matrix Node to any hard drive partition that has at least 300 GB of free space." | fold -s
lb
pause 'Press [Enter] key to continue...'

# Define install functions
function existingNodeInstall()
{
existingInstall=( $(find / -name gman ! -type d) )
existingPath="Please confirm your current masternode install path:"
lb
PS3="$existingPath "
select matrixPath in "${existingInstall[@]}" "Abort Install" ; do
    if (( REPLY == 1 + ${#existingInstall[@]} )) ; then
	exit
    elif (( REPLY > 0 && REPLY <= ${#existingInstall[@]} )) ; then
	lb
	echo "You have selected to update..."
	echo $matrixPath
	lb
	pause 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
	break
    else
	echo "Invalid option. Please try again."
    fi
done
}
	
function newNodeInstall()
{
newInstall=( $(df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 >= 100 {print}' | awk '$4 !~/M/ {print}' | awk 'length($4) >= 4 {print}' | awk '{print $6}') )
newInstallPath="Select a path to install your new Matrix Node:"
lb
PS3="$newInstallPath "
select matrixPath in "${newInstall[@]}" "Abort Install" ; do
    if (( REPLY == 1 + ${#newInstall[@]} )) ; then
	exit

    elif (( REPLY > 0 && REPLY <= ${#newInstall[@]} )) ; then
        lb
        echo  "You have selected to install to..."
        df -h $matrixPath | sed -n '2 p'
        lb
        pause 'If this is correct, press [Enter] to confirm, or Ctrl+C to abort installation'
	mkdir -p $matrixPath/matrix/
	lb
	echo "Creating SignAccount.json file..."
	lb
	echo "Please enter your wallet B address"
	read manWallet
	lb
	echo "WARNING: YOUR WALLET B PASSWORD SHOULD BE DIFFERENT THAN YOUR WALLET A PASSWORD"
	lb
	echo "If your wallet B and wallet A password are the same, please abort with Ctrl+C and create a new wallet B"
	lb
	echo "Please enter your wallet B password"
	read manPasswd
	echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/matrix/signAccount.json
	lb
	echo "Downloading and installing files..."
	sleep 5
	wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $matrixPath/matrix/1405031.tar.gz && tar -zxvf $matrixPath/matrix/1405031.tar.gz -C $matrixPath/matrix/
        wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $matrixPath/matrix/gman && chmod a+x /$matrixPath/matrix/gman
        wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $matrixPath/matrix/MANGenesis.json
	mkdir $matrixPath/matrix/chaindata/keystore
        clear
        banner
	lb
	echo "Creating entrust.json file..."
	lb
	echo "Note: Please choose a different password than your Wallet B password"
	sleep 5
	lb
	pause '		Press [Return] to continue]'
	$matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata aes --aesin $matrixPath/matrix/signAccount.json --aesout $matrixPath/matrix/entrust.json
	echo "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below"
	read matrixKeystore
	echo -e "$matrixKeystore" > $matrixPath/matrix/chaindata/keystore/wallet.file
	echo -e "if [ ! -f "$matrixPath/matrix/firstRun" ]; then\n      touch $matrixPath/matrix/firstRun && $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust /matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $matrixPath/matrix/gmanRunScript.sh
	echo -e "alias gmanMatrix=/$matrixPath/gmanRunScript.sh" >> ~/.bashrc
	source ~/.bashrc
	clear
	curl https://raw.githubusercontent.com/disarmm/MatrixSetup/master/completedBanner
	lb
	echo "Type gmanMatrix to start your new node"
	break
    else
        echo "Invalid option. Try again."
    fi
done
}

installType="Do you already have a Matrix node on this system?"
lb
PS3="$installType "
select yn in "Yes" "No"; do
    case $yn in
        No ) newNodeInstall; exit;;
        Yes ) existingNodeInstall; exit;;
    esac
done

