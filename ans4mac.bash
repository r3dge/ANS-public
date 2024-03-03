#!/bin/bash

# test si on est root ou sudo
test=`whoami`
if [ $test != "root" ]; then
  echo "Erreur : A lancer avec sudo"
  exit
fi

# récupération de paramètre(s)
skipFormating='false'
if [[ $1 == "-s" ]]; then
    skipFormating='true'
fi

if [[ $2 == "-s" ]]; then
    skipFormating='true'
fi

# test si on a une connexion internet
ping -q -w1 -c1 google.com &>/dev/null
if [ $? != 0 ]; then
	echo "Erreur : La connexion internet doit être activée"
	exit
fi

# activation des dépôts partenaires
add-apt-repository "$depotpartenaire"

# install pré-requis
sudo apt-get -y install curl

# Demande à l'utilisateur de saisir le chemin du périphérique
echo "Veuillez indiquer le numéro ANS de la machine : "
read nom_machine
echo "Vérification de la machine..."

# vérification du nom de la nom_machine
ANS_ADDR='https://actionnumeriquesolidaire.org'
result_machine=$(curl -X GET "$ANS_ADDR/api/materiels?page=1&AnsId=$nom_machine" -H 'accept: application/ld+json')

if [[ $result_machine == *"\"hydra:totalItems\":0"* ]]; then
    echo "Cette machine n'est pas référencée chez ANS. Veuillez recommancer en saisissant le numéro de machine figurant sur l'étiquette ANS (exemple : 2021071900075)"
	exit
else
    echo "Cette machine est référencée chez ANS."
fi

# Vérifier si le répertoire de montage existe déjà
if [ ! -d "/media/macos" ]; then
    sudo mkdir -p /media/macos
fi

# Démonter le disque au cas où il serait déjà monté
sudo umount "$device_path"

# Monter le disque
sudo mount -t hfsplus -o force,rw "$device_path" /media/macos

# Vérifier si le montage a réussi
if [ $? -eq 0 ]; then
    echo "Le disque dur macOS a été monté avec succès sur /media/macos"
else
    echo "Erreur lors du montage du disque dur macOS : impossible de poursuivre l'exécution du script"
	exit 
fi

# Diagnostics
apt-get -y install memtester hdparm
apt-get -y install libcpanel-json-xs-perl
apt-get -y install inxi

clear
echo "------------------------------------------------------- Diagnostique et effacement des données -------------------------------------------------------------"
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

	# Se positionner sur la partition macos
	mkdir /media/macos/ANS
	cd /media/macos/ANS

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
fi

clear
echo "_______________________"
echo "< Effacement terminé ! >"
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