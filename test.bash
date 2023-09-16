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
if [ $timezone == "Europe/Kiev" ]; then
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
fi

fileName=undefined
# si la langue installée est le français --> vidéo et doc en français
if [ $language == 'LANG=fr_FR.UTF-8' ]; then
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
fi

if [ $language == 'LANG=en_*' ] ; then
    fileName=lubuntu-quick-start.mp4
	mv /home/user/ANS-public/vdo/en/*.* /home/user/Desktop/
	mkdir /home/user/Desktop/Documentation/
	mv /home/user/ANS-public/Documentation/* /home/user/Desktop/Documentation/
	
	wget https://actionnumeriquesolidaire.org/resources/applaudissements.wav
	mv applaudissements.wav /home/user/Desktop/.
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
