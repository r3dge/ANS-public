#!/bin/bash

# test si on est root ou sudo
test=`whoami`
if [ $test == "root" ]; then
  echo "Erreur : Ne pas lancer avec sudo"
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
curl google.fr
if [ $? != 0 ]; then
	echo "Erreur : La connexion internet doit être activée"
	exit
fi

# installation de homebrew + inxi
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install inxi

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

# Remontée de la configuration matérielle
hw=$(inxi -G -s -N -A -C -M -I -D --output json --output-file "./info.json")
json=$(cat ./info.json)

json_var="$nom_machine|HW|$json"
curl -X 'POST' \
  "$ANS_ADDR/api/config" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo " : Remontée de la configuration matérielle"

if [[ $skipFormating == 'false' ]]; then
	# Effacement des disques
	echo "Démarrage de l'effacement des données de l'espace libre du disque dur. Cette opération peut être longue si le débit en écriture est faible. Veuillez patienter et ne pas éteindre la machine..."
	echo ""
	json_var="$nom_machine|Effacement|{\"title\":\"Démarrage de l'effacement du disque\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée de la date-heure de démarrage du formatage"  

	./src/fillsystemdisk4mac
	rm -f ./remplissage
	rm -f ./thread_file*

	json_var="$nom_machine|Effacement|{\"title\":\"Fin de l'effacement du disque\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée de la date-heure de fin du formatage"

	json_var="$nom_machine|Effacement|{\"title\":\"Statut du disque\", \"description\": \"Effacé\"}"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée du statut de formatage"

	json_var="$nom_machine|Effacement|{\"title\":\"Méthode d'effacement du disque\", \"description\": \"random-fill one-pass\"}"
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
