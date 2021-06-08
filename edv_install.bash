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
if [[ $distrib == *"Ubuntu 20"* ]]; then
	soixantequatrebits="true"
	depotpartenaire="deb http://archive.canonical.com/ubuntu focal partner"
else
	soixantequatrebits="false"
	depotpartenaire="deb http://archive.canonical.com/ubuntu bionic partner"
fi


# active le tap-to-click
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

#activation des dépôts partenaires
resultPartner=$(cat /etc/apt/sources.list | grep "$depotpartenaire")
add-apt-repository "$depotpartenaire"


# Mises à jour
apt update
apt -y upgrade


if [[ $soixantequatrebits == "true" ]]; then

	# install skype + discord
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


# Passe libreoffice en français
apt-get -y install libreoffice-l10n-fr

# TODO : plugins libre-office
# ajoute le plugin libreoffice cartable fantastique
# su - user
# unopkg add -s --shared ./Lbo_CartableFantastique.v2.oxt
# exit
# ajouter également le plugin grammalecte
# + plugin dmaths

# Passe Firefox en Français
locale-gen fr_FR fr_FR.UTF-8
apt-get -y --fix-missing install firefox-locale-fr
LC_ALL=fr_FR firefox -no-remote

#télécharge la vidéo sur le bureau
curl --help
if [ $ != 0 ]; then
	apt-get -y install curl
fi
cd /home/user/Desktop
fileName=Lubuntu-introduction.avi
fileId=1519PAoVY7U9HBF12G_clMwSccFntl0Eb
test -e $fileName
if [ $ != 0 ]; then
	curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${fileId}" > /dev/null
	code="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"  
	curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${code}&id=${fileId}" -o $fileName 
fi

# Télécharge la documentation sur le bureau
docName=EDV-Documentation-Lubuntu.odp
docId=13YSzLpujubgEZIJZe0TocEclV8p7I5rz
test -e $docName
if [ $ != 0 ]; then
	curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${docId}" > /dev/null
	code="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"  
	curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${code}&id=${docId}" -o $docName 
fi

# vérifications
curl --help
resultCurl=$?
test -e $fileName
resultVideo=$?
test -e $docName
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

clear
echo "_______________________________ Résultats du script _______________________________"
if [ "$resultPartner" != '' ]; then
	echo "Activation des dépôts partenaires ---------------------------------------------- OK"
else
	echo "Activation des dépôts partenaires ---------------------------------------------- ERREUR"
fi
if [ $resultCurl == 0 ]; then
	echo "Installation de CURL------------------------------------------------------------ OK"
else
	echo "Installation de CURL------------------------------------------------------------ ERREUR"
fi
if [ $resultVideo == 0 ]; then
	echo "Téléchargement de la vidéo ----------------------------------------------------- OK"
else
	echo "Téléchargement de la vidéo ----------------------------------------------------- ERREUR"
fi
if [ $resultDoc == 0 ]; then
	echo "Téléchargement de la documentation --------------------------------------------- OK"
else
	echo "Téléchargement de la documentation --------------------------------------------- ERREUR"
fi

if [[ $soixantequatrebits == "true" ]]; then
	if [ $resultSkype == 0 ]; then
		echo "Installation de skype ---------------------------------------------------------- OK"
	else
		echo "Installation de skype ---------------------------------------------------------- ERREUR"
	fi
	if [ $resultDiscord == 0 ]; then
		echo "Installation de Discord -------------------------------------------------------- OK"
	else
		echo "Installation de Discord -------------------------------------------------------- ERREUR"
	fi
else
	if [ $resultVLC == 0 ]; then
		echo "Installation de VLC ------------------------------------------------------------- OK"
	else
		echo "Installation de VLC ------------------------------------------------------------- ERREUR"
	fi
	if [ $resultlibreoffice == 0 ]; then
		echo "Installation de LibreOffice-------------------------------------------------- OK"
	else
		echo "Installation de LibreOffice ------------------------------------------------- ERREUR"
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

exit 0
