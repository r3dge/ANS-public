#!/bin/bash

# test si on est root ou sudo
test=`whoami`
if [ $test != "root" ]; then
  echo "A lancer avec sudo"
  exit
fi

# test si on a une connexion internet
ping -q -w1 -c1 google.com &>/dev/null
if [ $? != 0 ]; then
	echo "La connexion internet doit être activée"
	exit
fi

#vérifie la distrib
distrib="$(lsb_release -a | grep Description)"
if [[ $distrib == *"Ubuntu 22"* ]]; then
	soixantequatrebits="true"
	depotpartenaire="deb http://archive.canonical.com/ubuntu jammy partner"
else
	soixantequatrebits="false"
	depotpartenaire="deb http://archive.canonical.com/ubuntu bionic partner"
fi

#activation des dépôts partenaires
add-apt-repository "$depotpartenaire"


# Mises à jour
apt update
apt -y upgrade

# vérification du nom de la nom_machine
sudo apt-get -y install curl
nom_machine="$(hostname)"
ANS_ADDR='https://actionnumeriquesolidaire.org'
result_machine=$(curl -X GET "$ANS_ADDR/api/materiels?page=1&AnsId=$nom_machine" -H 'accept: application/ld+json')
if [[ $result_machine == *"\"hydra:totalItems\":0"* ]]; then
    echo "Cette machine n'est pas référencée chez ANS. Veuillez renommer la machine avec l'identifiant figurant sur l'étiquette ANS (exemple : 2021071900075)"
	exit
else
    echo "Cette machine est référencée chez ANS."
fi

if [[ $soixantequatrebits == "true" ]]; then
	# install skype + discord en ligne
	snap list discord
	if [ $? != 0 ]; then
		snap install discord
	fi

	snap list skype
	if [ $? != 0 ]; then
		snap install skype --classic
	fi
else
	#install libreoffice
	libreoffice --help
	if [ $? != 0 ]; then
		apt-get -y install libreoffice-writer libreoffice-calc libreoffice-impress
	fi

	#install vlc
	vlc --help
	if [ $? != 0 ]; then
		apt-get -y install vlc
	fi

fi

apt-get -y install audacity

echo "Installation des packages Russes et Ukrainiens"

# system
locale-gen ru_RU ru_RU.UTF-8
locale-gen uk_UA uk_UA.UTF-8

# LibreOffice 
apt-get -y install libreoffice-l10n-ru
apt-get -y install libreoffice-l10n-uk

# firefox 
apt-get -y --fix-missing install firefox-locale-uk 
apt-get -y --fix-missing install firefox-locale-ru 

# change le layout du clavier en qwerty --> désactivé pour l'instant
# setxkbmap us # ua si on veut le passer en ukrainien

#télécharge la vidéo et la documentation sur le bureau
fileName=lubuntu-quick-start.mp4
test -d /home/user/Desktop
if [[ $? == 0 ]] ; then

	mv /home/user/ANS-public/vdo/en/*.* /home/user/Desktop/
	mkdir /home/user/Desktop/Documentation/
	mv /home/user/ANS-public/Documentation/* /home/user/Desktop/Documentation/
	
	wget https://actionnumeriquesolidaire.org/resources/applaudissements.wav
	mv applaudissements.wav /home/user/Desktop/.
else
	mv /home/user/ANS-public/vdo/en/*.* /home/user/Bureau/
	mkdir /home/user/Bureau/Documentation/
	mv /home/user/ANS-public/Documentation/* /home/user/Bureau/Documentation/

	wget https://actionnumeriquesolidaire.org/resources/applaudissements.wav
	mv applaudissements.wav /home/user/Bureau/.
fi


# Diagnostics
apt-get -y install memtester hdparm
apt-get -y install libcpanel-json-xs-perl
apt-get -y install inxi

clear
echo "------------------------------------------------------- Diagnostique et effacement des données -------------------------------------------------------------"
echo ""
echo "Les installations sont terminées."

echo ""
echo "Démarrage du test mémoire"
test_mem=$(memtester 250M 1)
result=$?
if [ $? == 0 ]; then
    resultat="Aucune erreur détectée."
    flag="success"
else
    resultat="Erreurs détectées ! La mémoire de cette machine semble défectueuse"
    flag="danger"
fi
json_var="{\"AnsId\": \"$nom_machine\",\"Type\": \"Mémoire\",\"Flag\": \"$flag\",\"Description\": \" $resultat\" }"
curl -X 'POST' \
  "$ANS_ADDR/api/diagnostics" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo ""
echo "Résultat du test mémoire : $resultat"


echo ""
echo "Démarrage du test de lecture sur disque"
test_mem=$(hdparm -t /dev/sda | grep Timing)
json_var="{\"AnsId\": \"$nom_machine\",\"Type\": \"Disque dur\",\"Description\": \" $test_mem\" }"
curl -X 'POST' \
  "$ANS_ADDR/api/diagnostics" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo ""
echo "Test de lecture sur disque terminé."

echo ""

# Remontée de la configuration matérielle
hw=$(inxi -G -s -N -A -C -M -I --output json --output-file "/home/user/info.json")
json=$(cat /home/user/info.json)

json_var="$nom_machine|HW|$json"
curl -X 'POST' \
  "$ANS_ADDR/api/config" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo " : Remontée de la configuration matérielle"

# Remontée des infos sur les disques
disk=$(lsblk --json -o path,model,serial,size,type,wwn,vendor -d | grep -v loop)
json_var="$nom_machine|Disque|$disk"
curl -X 'POST' \
  "$ANS_ADDR/api/config" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo " : Remontée des informations sur les disques"

# Remontée des infos sur la batterie
batterie=$(upower -e | grep battery)
infosBatterie=$(upower -i $batterie)
json_var="$nom_machine|Batterie|$infosBatterie"
curl -X 'POST' \
  "$ANS_ADDR/api/config" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo " : Remontée des infos sur la batterie"


# Effacement des disques
echo "Démarrage de l'effacement des données de l'espace libre du disque dur. Cette opération peut être longue si le débit en écriture est faible. Veuillez patienter et ne pas éteindre la machine..."
echo ""

inxi -d | grep ID-1
driveDetails="$(inxi -d | grep ID-1 | tr ' ' '\n')"
for detail in $driveDetails
do
    if [[ $detail =~ ^/dev.*  ]]; then
      currentDrive=$detail
    fi
done

echo "Effacement du disque : $currentDrive"
echo ""
json_var="$nom_machine|Effacement|{\"title\":\"Démarrage de l'effacement du disque $currentDrive\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
curl -X 'POST' \
"$ANS_ADDR/api/config" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d "$json_var"
echo " : Remontée de la date-heure de démarrage du formatage"  

dd if=/dev/urandom bs=4096 status=progress > remplissage
rm remplissage

json_var="$nom_machine|Effacement|{\"title\":\"Fin de l'effacement du disque $currentDrive\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
curl -X 'POST' \
"$ANS_ADDR/api/config" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d "$json_var"
echo " : Remontée de la date-heure de fin du formatage"

json_var="$nom_machine|Effacement|{\"title\":\"Statut du disque $currentDrive\", \"description\": \"Effacé\"}"
curl -X 'POST' \
"$ANS_ADDR/api/config" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d "$json_var"
echo " : Remontée du statut de formatage"

json_var="$nom_machine|Effacement|{\"title\":\"Méthode d'effacement du disque $currentDrive\", \"description\": \"random-fill one-pass\"}"
curl -X 'POST' \
"$ANS_ADDR/api/config" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d "$json_var"
echo " : Remontée des de la méthode de formatage"


drives="$(inxi -d | grep ID | grep -v ID-1 | tr ' ' '\n')"
for drive in $drives
do
    if [[ $drive =~ ^/dev.*  ]]; then
      if [[ $drive != $currentDrive ]]; then
        echo "Effacement du disque : $drive"
		echo ""
		
        json_var="$nom_machine|Effacement|{\"title\":\"Démarrage de l'effacement du disque $drive\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
        curl -X 'POST' \
        "$ANS_ADDR/api/config" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$json_var"
        echo " : Remontée de la date-heure de démarrage du formatage"
        dd if=/dev/urandom of=$drive bs=4096 status=progress
        json_var="$nom_machine|Effacement|{\"title\":\"Fin de l'effacement du disque $drive\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
        curl -X 'POST' \
        "$ANS_ADDR/api/config" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$json_var"
        echo " : Remontée de la date-heure de fin du formatage"
        
		json_var="$nom_machine|Effacement|{\"title\":\"Statut du disque $drive\", \"description\": \"Effacé\"}"
        curl -X 'POST' \
        "$ANS_ADDR/api/config" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$json_var"
        echo " : Remontée du statut de formatage"

        json_var="$nom_machine|Effacement|{\"title\":\"Méthode d'effacement du disque $drive\", \"description\": \"random-fill one-pass\"}"
        curl -X 'POST' \
        "$ANS_ADDR/api/config" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "$json_var"
        echo " : Remontée des de la méthode de formatage"
      fi
    fi
done




# vérifications
test -e /home/user/Desktop/$fileName
resultVideo=$?
test -e /home/user/Desktop/Documentation
resultDoc=$?
resultPartner=$(cat /etc/apt/sources.list | grep "$depotpartenaire")
snap list skype
resultSkype=$?
snap list discord
resultDiscord=$?
vlc --help
resultVLC=$?
libreoffice --help
resultlibreoffice=$?

# tests son
echo ""
echo "_______________________________ Test du son _______________________________"

echo "Branchez le wrap (\ avec les enceintes si il n'y a pas de HP interne \)  et vous devriez entrendre des sons. Appuyez sur la touche Entrée quand vous êtes prêt"
read

clear
echo "_______________________________ Résultats du script _______________________________"
if [ "$resultPartner" != '' ]; then
	echo "Activation des dépôts partenaires ---------------------------------------------- OK"
else
	echo -e "\033[31mActivation des dépôts partenaires -------------------------------------- ERREUR\033[30m]$"
fi
if [ $resultVideo == 0 ]; then
	echo "Téléchargement de la vidéo ----------------------------------------------------- OK"
else
	echo -e "\033[31mTéléchargement de la vidéo --------------------------------------------- ERREUR\033[30m]$"
fi
if [ $resultDoc == 0 ]; then
	echo "Téléchargement de la documentation --------------------------------------------- OK"
else
	echo -e "\033[31mTéléchargement de la documentation ------------------------------------- ERREUR\033[30m]$"
fi

if [[ $soixantequatrebits == "true" ]]; then
	if [ $resultSkype == 0 ]; then
		echo "Installation de skype ---------------------------------------------------------- OK"
	else
		echo -e "\033[31mInstallation de skype ---------------------------------------------- ERREUR\033[30m]$"
	fi
	if [ $resultDiscord == 0 ]; then
		echo "Installation de Discord -------------------------------------------------------- OK"
	else
		echo -e "\033[31mInstallation de Discord -------------------------------------------- ERREUR\033[30m]$"
	fi
else
	if [ $resultVLC == 0 ]; then
		echo "Installation de VLC ------------------------------------------------------------- OK"
	else
		echo -e "\033[31mInstallation de VLC ------------------------------------------------ ERREUR\033[30m]$"
	fi
	if [ $resultlibreoffice == 0 ]; then
		echo "Installation de LibreOffice-------------------------------------------------- OK"
	else
		echo -e "\033[31mInstallation de LibreOffice ---------------------------------------- ERREUR\033[30m]$"
	fi
fi

echo "_______________________";
echo "< Installation terminée >";
echo " -----------------------";
echo "          \ ";
echo "           \ ";
echo "            \   ";
echo " .----------------.  .-----------------. .----------------. ";
echo "| .--------------. || .--------------. || .--------------. |";
echo "| |      __      | || | ____  _____  | || |    _______   | |";
echo "| |     /  \     | || ||_   \|_   _| | || |   /  ___  |  | |";
echo "| |    / /\ \    | || |  |   \ | |   | || |  |  (__ \_|  | |";
echo "| |   / ____ \   | || |  | |\ \| |   | || |   '.___\`-.   | |";
echo "| | _/ /    \ \_ | || | _| |_\   |_  | || |  |\`\____) |  | |";
echo "| ||____|  |____|| || ||_____|\____| | || |  |_______.'  | |";
echo "| |              | || |              | || |              | |";
echo "| '--------------' || '--------------' || '--------------' |";
echo " '----------------'  '----------------'  '----------------' ";

exit 0
