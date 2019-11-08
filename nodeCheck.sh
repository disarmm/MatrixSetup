#!/bin/bash

function lb(){
        printf "\n"
}


function mine(){
docker ps | grep nodeConfig
for m in $(docker ps | grep nodeConfig | awk {'print $1'}) ; do
        docker exec -i $m /bin/bash -c "/matrix/gman attach /matrix/chaindata/gman.ipc -exec man.mining"
done
}

function sync(){
docker ps | grep nodeConfig
for s in $(docker ps | grep nodeConfig | awk {'print $1'}) ; do
        docker exec -i $s /bin/bash -c "/matrix/gman attach /matrix/chaindata/gman.ipc -exec man.syncing"
done
}


mooseFarts="Would you like to check your mining or syncing status?"
lb
PS3="$mooseFarts "
select ms in "Mining" "Syncing"; do
    case $ms in
        Mining ) mine; exit;;
        Syncing ) sync; exit;;
    esac
done
