#!/bin/bash

# test si on est root ou sudo
test=`whoami`
if [ $test != "root" ]; then
  echo "A lancer avec sudo"
  exit
fi

# récupération de paramètre(s)
if [[ -z "$1" ]]; then
	localServer="false"
else
	if [ $1 == "--local" ]; then
		localServer="true"
	else
		localServer="false"
	fi
fi

skipFormating='false'
if [[ $1 == "-s" ]]; then
    skipFormating='true'
fi

if [[ $2 == "-s" ]]; then
    skipFormating='true'
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

# si on utilise le serveur du local ANS
if [ $localServer == "true" ]; then
	#IP du serveur
	echo "Entrez l'adresse IP du serveur"
	read serveur
	echo "Adresse IP du serveur: "$serveur

	# Mise à l'heure avec le serveur local
	wget  http://$serveur/ubuntu/Packages/set_date.sh
	chmod +x set_date.sh
	./set_date.sh
	
	# Récupération du fichier sources.list et test réseau.
	if [[ $distrib == *"Ubuntu 20"* ]]; then
			soixantequatrebits="true"
		wget  http://$serveur/ubuntu/Packages/sources.list_64bits
		if [ $? != 0 ]; then
			echo "Récuperation des sources.list impossible, vérifiez l'accés au serveur"
			exit
			fi
			cat sources.list_64bits | sed "s/serveur/$serveur/g" > /etc/apt/sources.list
	else
			soixantequatrebits="false"
		wget http://$serveur/ubuntu/Packages/sources.list_32bits
				if [ $? != 0 ]; then
			echo "Récuperation des sources.list impossible, vérifiez l'accés au serveur"
			exit
			fi
			cat sources.list_32bits | sed "s/serveur/$serveur/g" > /etc/apt/sources.list
	fi
fi

if [ $localServer == "false" ]; then
	# test si on a une connexion internet
	ping -q -w1 -c1 google.com &>/dev/null
	if [ $? != 0 ]; then
		echo "La connexion internet doit être activée"
		exit
	fi
fi

# active le tap-to-click
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

#activation des dépôts partenaires
add-apt-repository -y "$depotpartenaire"
add-apt-repository -y ppa:kelebek333/kablosuz

# Mises à jour
apt update
#apt -y upgrade

apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade

# vérification du nom de la nom_machine
apt-get -y install curl
nom_machine="$(hostname)"
ANS_ADDR='https://actionnumeriquesolidaire.org'
result_machine=$(curl -X GET "$ANS_ADDR/api/materiels?page=1&AnsId=$nom_machine" -H 'accept: application/ld+json')

if [[ $result_machine == *"\"hydra:totalItems\":0"* ]]; then
    echo "Cette machine n'est pas référencée chez ANS. Veuillez renommer la machine avec l'identifiant figurant sur l'étiquette ANS (exemple : 2021071900075)"
	exit
else
    echo "Cette machine est référencée chez ANS."
fi

apt -y install rtl8188fu-dkms

if [[ $soixantequatrebits == "true" ]]; then

	if [ $localServer == "true" ]; then
		# install skype + discord
        type discord
        if [ $? != 0 ]; then
		wget http://$serveur/ubuntu/Packages/discord-0.0.14.deb 
		if [ $? != 0 ]; then
				echo "Récuperation de discord impossible, vérifiez l'accés au serveur"
				exit
			fi
		apt-get -y --fix-missing install  ./discord-0.0.14.deb
			fi

		type skype
			if [ $? != 0 ]; then
		wget http://$serveur/ubuntu/Packages/skypeforlinux-64.deb
		if [ $? != 0 ]; then
				echo "Récuperation de skype impossible, vérifiez l'accés au serveur"
				exit
			fi
		apt-get -y --fix-missing install ./skypeforlinux-64.deb
		fi
	else
		# install skype + discord en ligne
		snap list discord
		if [ $? != 0 ]; then
			snap install discord
		fi

		snap list skype
		if [ $? != 0 ]; then
			snap install skype --classic
		fi
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


language="$(cat /etc/default/locale|grep LANG)"
timezone="$(cat /etc/timezone)"

# si la langue installée est le français --> packages FR
if [ $language == 'LANG=fr_FR.UTF-8' ]; then
	# Passe libreoffice en français
	apt-get -y install libreoffice-l10n-fr

	# Passe Firefox en Français
	locale-gen fr_FR fr_FR.UTF-8
	apt-get -y --fix-missing install firefox-locale-fr
	LC_ALL=fr_FR firefox -no-remote
fi

# si la timezone est Ukraine
if [ $timezone == "Europe/Kiev" ] || [ $timezone == "Europe/Kyiv" ]; then
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

	#clavier ukrainien
	setxkbmap ua
fi

fileName=undefined
# si la langue installée est le français --> vidéo et doc en français
if [ $language == 'LANG=fr_FR.UTF-8' ]; then
	echo "Installation documentation et vidéo en Français"
	#télécharge la vidéo et la documentation sur le bureau
	fileName=Lubuntu-Introduction.avi
	test -d /home/user/Desktop
	if [[ $? == 0 ]] ; then
		wget https://actionnumeriquesolidaire.org/resources/Lubuntu-Introduction.avi
		mv Lubuntu-Introduction.avi /home/user/Desktop/
		mkdir /home/user/Desktop/Documentation/
		mv /home/user/ANS-public/Documentation/fr/*.* /home/user/Desktop/Documentation/
		
		wget https://actionnumeriquesolidaire.org/resources/applaudissements.wav
		mv applaudissements.wav /home/user/Desktop/.
	else
		wget https://actionnumeriquesolidaire.org/resources/Lubuntu-Introduction.avi
		mv Lubuntu-Introduction.avi /home/user/Bureau/.
		mkdir /home/user/Bureau/Documentation/
		mv /home/user/ANS-public/Documentation/fr/*.* /home/user/Bureau/Documentation/

		wget https://actionnumeriquesolidaire.org/resources/applaudissements.wav
		mv applaudissements.wav /home/user/Bureau/.
	fi
else
		echo "Installation documentation et vidéo en Anglais"
		fileName=lubuntu-quick-start.mp4
		mv /home/user/ANS-public/vdo/en/*.* /home/user/Desktop/
		mkdir /home/user/Desktop/Documentation/
		mv /home/user/ANS-public/Documentation/* /home/user/Desktop/Documentation/
		
		wget https://actionnumeriquesolidaire.org/resources/applaudissements.wav
		mv applaudissements.wav /home/user/Desktop/.
fi




if [ $localServer == "true" ]; then
	#Restauration sources.list
	if [[ $soixantequatrebits == "true" ]]; then
			wget http://$serveur/ubuntu/Packages/sources.list_64bits_ORI
			mv sources.list_64bits_ORI /etc/apt/sources.list
	else
			wget http://$serveur/ubuntu/Packages/sources.list_32bits_ORI
			mv sources.list_32bits_ORI /etc/apt/sources.list
	fi
	#Chargement du test de son
	wget http://$serveur/ubuntu/Packages/Test.wav
	wget http://$serveur/ubuntu/Packages/Test.sh
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

# Identification du type de pc (portable ou fixe) en fonction de la présence d'une batterie
batterie=$(upower -e | grep battery)
if [[ $? == 0 ]]; then
	# s'il y a une batterie --> il s'agit d'un pc portable
	laptop=true
	infosBatterie=$(upower -i $batterie)
	json_var="$nom_machine|Batterie|$infosBatterie"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée des infos sur la batterie"

	# vérification que le wifi fonctionne
	echo ""
	echo "Vérification du wifi"
	wifi_networks=$(nmcli dev wifi list)
	if [[ $wifi_networks == "" ]]; then
		wifi=false
		flag="danger"
		resultat="Le wifi de cette machine n'est pas opérationnel."
	else
		wifi=true
		flag="success"
		resultat="Le wifi de cette machine fonctionne."
	fi
	json_var="{\"AnsId\": \"$nom_machine\",\"Type\": \"Wifi\",\"Flag\": \"$flag\",\"Description\": \" $resultat\" }"
	curl -X 'POST' \
	"$ANS_ADDR/api/diagnostics" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo ""
	echo "Résultat du test wifi : $resultat"
else
	# pas de batterie --> pc fixe --> pas de test wifi
	laptop=false
	wifi=false
	echo "pas de batterie"
fi


if [[ $skipFormating == 'false' ]]; then
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

	/home/user/ANS-public/src/fillsystemdisk
	rm ./remplissage
	rm ./thread_file*

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
fi

# vérifications
test -e /home/user/Desktop/$fileName
resultVideo=$?
test -e /home/user/Desktop/Documentation
resultDoc=$?
resultPartner=$(cat /etc/apt/sources.list | grep "$depotpartenaire")
#snap list skype
#resultSkype=$?
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

if [ $localServer == "true" ]; then
	arecord -d 10 -f cd -t wav /tmp/test.wav &
	aplay Test.wav
	wait
	aplay /tmp/test.wav
else
	aplay /home/user/Desktop/applaudissements.wav
fi

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

if [[ $laptop == true ]]; then
	if [[ $wifi == true ]]; then
		echo "WIFI ------------------------------------------------------------------------ OK"
	else
		echo -e "\033[31mWIFI----------------------- ---------------------------------------- ERREUR\033[30m]$"
	fi
fi

echo "_______________________"
echo "< Installation terminée >"
echo " -----------------------"
echo "          \ "
echo "           \ "
echo "            \          __---__"
echo "                    _-       /--______"
echo "               __--( /     \ )XXXXXXXXXXX\v."
echo "             .-XXX(   O   O  )XXXXXXXXXXXXXXX-"
echo "            /XXX(       U     )        XXXXXXX\ "
echo "          /XXXXX(              )--_  XXXXXXXXXXX\ "
echo "         /XXXXX/ (      O     )   XXXXXX   \XXXXX\ "
echo "         XXXXX/   /            XXXXXX   \__ \XXXXX"
echo "         XXXXXX__/          XXXXXX         \__----> "
echo " ---___  XXX__/          XXXXXX      \__         / "
echo "   \-  --__/   ___/\  XXXXXX            /  ___--/= "
echo "    \-\    ___/    XXXXXX              '--- XXXXXX"
echo "       \-\/XXX\ XXXXXX                      /XXXXX"
echo "         \XXXXXXXXX   \                    /XXXXX/"
echo "          \XXXXXX      >                 _/XXXXX/ "
echo "            \XXXXX--__/              __-- XXXX/ "
echo "             -XXXXXXXX---------------  XXXXXX-"
echo "                \XXXXXXXXXXXXXXXXXXXXXXXXXX/ "
echo "                  ""VXXXXXXXXXXXXXXXXXXV"" "


cd ..
rm /home/user/infos.json
rm /home/user/Bureau/applaudissements.wav
rm /home/user/Desktop/applaudissements.wav
rm -R /home/user/ANS-public

exit 0
