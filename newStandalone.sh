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
# define functions for different install types
newStandalone(){
i=0
W=()
while read -r line; do
    let i=$i+1
    W+=($i "$line")
done < <( df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 >= 150 {print}' | awk '$4 !~/M/ {print}' | awk '{print $6}' )
ITYPE=$(whiptail --title "Choose an install path" --menu "Please choose an install path. These options all provide at least 150GB of free space for your masternode." 22 80 12 "${W[@]}" 3>&1 1>&2 2>&3)
exitStatus=$?
if [ ${exitStatus} = 0 ]; then
	matrixPath=$(readlink -f $(df -h | grep /dev/ | grep -v "100%" | grep -v "tmpfs" | awk '$4 >= 150 {print}' | awk '$4 !~/M/ {print}' | awk '{print $6}' | sed -n "`echo "$ITYPE p" | sed 's/ //'`") )
	if (whiptail --title "Confirmation" --yesno "You have chosen to install to \n\n${matrixPath}/matrix\n\n$(df -h ${matrixPath}) \n\nAre you sure?" 18 90 20); then
		:
	else
		newStandalone
	fi
fi
# create signAccount file
manWallet=$(whiptail --title "Creating signAccount.json file..." --inputbox "Please enter your wallet B address" 12 80 3>&1 1>&2 2>&3)
whiptail --title "WARNING" --msgbox "YOUR WALLET B PASSWORD SHOULD BE DIFFERENT THAN YOUR WALLET A PASSWORD" 12 80
manPasswd=$(whiptail --title "Creating signAccount.json file..." --inputbox "This password is stored only in your signAccount.json file, which is deleted after your entrust file is created.\n\nPlease enter your wallet B password" 12 80 3>&1 1>&2 2>&3)
mkdir -p $matrixPath/matrix/
echo -e '[\n{\n"Address":"'$manWallet'",\n"Password":"'$manPasswd'"\n}\n]' > $matrixPath/matrix/signAccount.json
clear
# another obvious section.. downloading the files...
banner
lb
echo "Downloading and installing files..."
sleep 2
lb
wget www2.matrixainetwork.eu/snapshots/1405031.tar.gz -O $matrixPath/matrix/1405031.tar.gz && tar -zxvf $matrixPath/matrix/1405031.tar.gz -C $matrixPath/matrix/
lb
wget https://github.com/MatrixAINetwork/GMAN_CLIENT/raw/master/MAINNET/1022/linux/gman -O $matrixPath/matrix/gman && chmod a+x /$matrixPath/matrix/gman
lb
wget https://raw.githubusercontent.com/MatrixAINetwork/GMAN_CLIENT/master/MAINNET/1022/MANGenesis.json -O $matrixPath/matrix/MANGenesis.json
lb
mkdir $matrixPath/matrix/chaindata/keystore
rm $matrixPath/matrix/1405031.tar.gz
# create encrypted entrust file
whiptail --title "Creating entrust.json file..." --msgbox "This password is the password used for starting your node. It should be different than the password you use to unlock your wallet in the wallet app. Please choose a password that is different than the password used to unlock your wallet A or wallet B in the wallet app." 12 80
# running gman command to create entrust file
$matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata aes --aesin $matrixPath/matrix/signAccount.json --aesout $matrixPath/matrix/entrust.json
# removing plain text signAccount.json
rm $matrixPath/matrix/signAccount.json
# create keystore wallet file
matrixKeystore=$(whiptail --title "Creating wallet B keystore file..." --inputbox "Open your downloaded UTC wallet file with wordpad or notepad++ and copy/paste the contents below" 12 80 3>&1 1>&2 2>&3)
echo "$matrixKeystore" > $matrixPath/matrix/chaindata/keystore/${manWallet}
# creating easy startup script
echo -e "#!/bin/bash\ncd $matrixPath/matrix\nif [ ! -f "$matrixPath/matrix/firstRun" ]; then\n      touch $matrixPath/matrix/firstRun && $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust /$matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full --loadsnapfile "TrieData1405031"\nelse\n    $matrixPath/matrix/gman --datadir $matrixPath/matrix/chaindata --networkid 1 --debug --verbosity 1 --port 50505 --manAddress $manWallet --entrust $matrixPath/matrix/entrust.json --gcmode archive --outputinfo 1 --syncmode full\nfi" > $matrixPath/matrix/gmanClient.sh
chmod 775 $matrixPath/matrix/gmanClient.sh
# copy start script
cp $matrixPath/matrix/gmanClient.sh /usr/local/bin/gmanClient
echo "alias gmanClient=/$matrixPath/matrix/gmanRunScript.sh" >> ~/.bashrc
whiptail --title "Matrix AI Network - Installer" --msgbox "Installation Complete!\n\nYou can type gmanClient from any path and your Matrix node will start magically" 20 80
}
newStandalone
