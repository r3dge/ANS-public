#!/bin/bash

# test si on est root ou sudo
test=`whoami`
if [ $test != "root" ]; then
  echo "A lancer avec sudo"
  exit
fi

skipFormating='false'
if [[ $1 == "-s" ]]; then
    skipFormating='true'
fi

if [[ $2 == "-s" ]]; then
    skipFormating='true'
fi

# récupère le codename de la version pour ajouter les dépôts partenaires
codename=`lsb_release -a | grep Codename | awk '{ print $2 }'`
depotpartenaire="deb http://archive.canonical.com/ubuntu $codename partner"

# test si on a une connexion internet
ping -q -w1 -c1 google.com &>/dev/null
if [ $? != 0 ]; then
	echo "La connexion internet doit être activée"
	exit
fi

# Vérification que la version du script est à jour
git_status=$(git status --porcelain)

if [ -n "$git_status" ]; then
  echo "Cette version du script n'est pas à jour. Veuillez faire un "git pull" ou un commit des modifications"
  exit 1
else
  echo "Le script est à jour."
fi

#activation des dépôts partenaires
add-apt-repository -y "$depotpartenaire"
add-apt-repository -y ppa:kelebek333/kablosuz

# Mises à jour
apt update
apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" full-upgrade

# vérification du nom de la nom_machine
apt-get -y install curl
nom_machine="$(cat /etc/hostname)"
ANS_ADDR='https://actionnumeriquesolidaire.org'
result_machine=$(curl -X GET "$ANS_ADDR/api/materiels?page=1&AnsId=$nom_machine" -H 'accept: application/ld+json')

if [[ $result_machine == *"\"hydra:totalItems\":0"* ]]; then
    echo "Cette machine n'est pas référencée chez ANS. Veuillez renommer la machine avec l'identifiant figurant sur l'étiquette ANS (exemple : 2021071900075)"
	exit
else
    echo "Cette machine est référencée chez ANS."
fi

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

# installation des polices microsoft
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
sudo apt-get install -y ttf-mscorefonts-installer



clear
echo "Les installations sont terminées."

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
rm /home/user/Bureau/applaudissements.wav
rm /home/user/Desktop/applaudissements.wav
rm -R /home/user/ANS-public

exit 0
