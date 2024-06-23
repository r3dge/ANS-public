#!/bin/bash

# test si on est root ou sudo
#test=`whoami`
#if [ $test == "root" ]; then
#  echo "Erreur : Ne pas lancer avec sudo"
#  exit
#fi

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

# Vérification que la version du script est à jour
git_status=$(git status --porcelain)

if [ -n "$git_status" ]; then
  echo "Cette version du script n'est pas à jour. Veuillez faire un "git pull" ou un commit des modifications"
  exit 1
else
  echo "Le script est à jour."
fi

# Nom du fichier où le numéro ANS sera stocké
fichier_ans="ansid.txt"

# Vérifie si le fichier existe et contient un numéro ANS
if [ -f "$fichier_ans" ]; then
    # Lire le contenu du fichier
    nom_machine=$(cat "$fichier_ans")
    echo "Le numéro ANS de la machine est : $nom_machine"
else
    # Demande à l'utilisateur de saisir le numéro ANS
    echo "Veuillez indiquer le numéro ANS de la machine : "
    read nom_machine
    
    # Sauvegarde le numéro ANS dans le fichier
    echo "$nom_machine" > "$fichier_ans"
    echo "Le numéro ANS $nom_machine a été sauvegardé dans $fichier_ans"
fi

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
hw=$(system_profiler SPHardwareDataType > "/Users/user/Ans-public/info.txt")
txt=$(cat ./info.txt)

json_var="$nom_machine|HW|$txt"
curl -X 'POST' \
  "$ANS_ADDR/api/config/mac" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo " : Remontée de la configuration matérielle"

# Remontée des infos sur les disques
disk=$(system_profiler SPSerialATADataType)
json_var="$nom_machine|Disque|$disk"
curl -X 'POST' \
  "$ANS_ADDR/api/config/mac" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "$json_var"
echo " : Remontée des informations sur les disques"

if [[ $skipFormating == 'false' ]]; then
	# Effacement des disques
	echo "Démarrage de l'effacement des données de l'espace libre du disque dur. Cette opération peut être longue si le débit en écriture est faible. Veuillez patienter et ne pas éteindre la machine..."
	echo ""
	json_var="$nom_machine|Effacement|{\"title\":\"Démarrage de l'effacement du disque 1\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée de la date-heure de démarrage du formatage"  

	./bin/fillsystemdisk4mac
	rm -f ./remplissage
	rm -f ./thread_file*

	json_var="$nom_machine|Effacement|{\"title\":\"Fin de l'effacement du disque 1\", \"description\": \"$(date +"%d-%m-%Y %H-%M-%S")\"}"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée de la date-heure de fin du formatage"

	json_var="$nom_machine|Effacement|{\"title\":\"Statut du disque 1\", \"description\": \"Effacé\"}"
	curl -X 'POST' \
	"$ANS_ADDR/api/config" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d "$json_var"
	echo " : Remontée du statut de formatage"

	json_var="$nom_machine|Effacement|{\"title\":\"Méthode d'effacement du disque 1\", \"description\": \"zero-fill one-pass\"}"
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
