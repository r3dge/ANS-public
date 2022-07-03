#!/bin/bash

# test si on est root ou sudo
test=`whoami`
if [ $test != "root" ]; then
  echo "A lancer avec sudo"
  exit
fi


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
