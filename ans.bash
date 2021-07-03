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

#vérifie la distrib
distrib="$(lsb_release -a | grep Description)"
if [[ $distrib == *"Ubuntu 20"* ]]; then
	soixantequatrebits="true"
	depotpartenaire="deb http://archive.canonical.com/ubuntu focal partner"
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
add-apt-repository "$depotpartenaire"


# Mises à jour
apt update
apt -y upgrade


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


# Passe libreoffice en français
apt-get -y install libreoffice-l10n-fr

# Passe Firefox en Français
locale-gen fr_FR fr_FR.UTF-8
apt-get -y --fix-missing install firefox-locale-fr
LC_ALL=fr_FR firefox -no-remote

#télécharge la vidéo et la documentation sur le bureau
if [ $localServer == "true" ]; then
	fileName=Lubuntu-introduction.avi
	docName=EDV-Documentation-Lubuntu.odp
	test -d Desktop
	if [[ $? == 0 ]] ; then
		wget http://$serveur/ubuntu/Packages/${fileName}
		mv Lubuntu-introduction.avi /home/user/Desktop/.
		wget http://$serveur/ubuntu/Packages/${docName}
		mv EDV-Documentation-Lubuntu.odp /home/user/Desktop/.
	else
		wget http://$serveur/ubuntu/Packages/${fileName}
		mv Lubuntu-introduction.avi /home/user/Bureau/.
		wget http://$serveur/ubuntu/Packages/${docName}
		mv EDV-Documentation-Lubuntu.odp /home/user/Bureau/.
	fi
else
	fileName=Lubuntu-Introduction.avi
	docName=ANS-Documentation.odp
	wget https://actionnumeriquesolidaire.org/resources/Lubuntu-Introduction.avi
	mv Lubuntu-Introduction.avi /home/user/Desktop/.
	wget https://actionnumeriquesolidaire.org/resources/ANS-Documentation.odp
	mv ANS-Documentation.odp /home/user/Desktop/.
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


# vérifications
test -e /home/user/Desktop/$fileName
resultVideo=$?
test -e /home/user/Desktop/$docName
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

clear
echo "Test en lecture du disque dur..."
hdparm -t -T /dev/sda
echo "Veuillez vérifier les valeurs de performance en lecture du disque dur et appuyer sur la touche Entrée"
read

echo "Mémoire vive disponible : "
lsmem
echo "Veuillez vérifier que la machine dispose bien de 2Go de RAM et appuyer sur Entrée"
read

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
