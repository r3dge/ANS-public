#!/bin/bash


# test si on est root ou sudo
test=`whoami`
if [ $test != "root" ]; then
  echo "A lancer avec sudo"
  exit 0
fi

echo "=============================================="                         
echo "====  ========================================"                         
echo "===    ======================================="                         
echo "==  ==  ===========  ========================="                         
echo "=  ====  ===   ===    ==  ===   ===  = ======="                         
echo "=  ====  ==  =  ===  =======     ==     ======"                         
echo "=        ==  ======  ===  ==  =  ==  =  ======"                        
echo "=  ====  ==  ======  ===  ==  =  ==  =  ======"                         
echo "=  ====  ==  =  ===  ===  ==  =  ==  =  ======"                         
echo "=  ====  ===   ====   ==  ===   ===  =  ======"                         
echo "=============================================="                         
echo "======================================================================="
echo "=  =======  ==========================================================="
echo "=   ======  ==========================================================="
echo "=    =====  ==========================================================="
echo "=  ==  ===  ==  =  ==  =  = ====   ===  =   ===  ===    ==  =  ===   =="
echo "=  ===  ==  ==  =  ==        ==  =  ==    =  ======  =  ==  =  ==  =  ="
echo "=  ====  =  ==  =  ==  =  =  ==     ==  =======  ==  =  ==  =  ==     ="
echo "=  =====    ==  =  ==  =  =  ==  =====  =======  ===    ==  =  ==  ===="
echo "=  ======   ==  =  ==  =  =  ==  =  ==  =======  =====  ==  =  ==  =  ="
echo "=  =======  ===    ==  =  =  ===   ===  =======  =====  ===    ===   =="
echo "======================================================================="
echo "==========================================================="            
echo "==      ==========  =========  ============================"            
echo "=  ====  =========  =========  ============================"            
echo "=  ====  =========  =========  ============================"            
echo "==  ========   ===  ==  =====  ===   ===  ==  =   ====   =="            
echo "====  =====     ==  =======    ==  =  ======    =  ==  =  ="            
echo "======  ===  =  ==  ==  ==  =  =====  ==  ==  =======     ="            
echo "=  ====  ==  =  ==  ==  ==  =  ===    ==  ==  =======  ===="            
echo "=  ====  ==  =  ==  ==  ==  =  ==  =  ==  ==  =======  =  ="            
echo "==      ====   ===  ==  ===    ===    ==  ==  ========   =="            
echo "==========================================================="            

echo ""

echo "Vous êtes sur le point de lancer un formatage bas niveau. Êtes-vous certain de vouloir poursuivre ? (o/n)"
read reponse
if [ $reponse != "o" ]; then
        exit 0
fi

echo "Souhaitez-vous que l'ordinateur s'éteigne automatiquement lorsque le formatage est terminé ? (o/n)"
read eteindre


nomfic=`date +%Y%m%d_%H%M%S`
timestamp=`date +%Y-%m-%d_%H-%M-%S`
echo $timestamp" Démarrage des opérations de formatage"
echo $timestamp" Démarrage des opérations de formatage" >> sortie.txt

# lancement des formatages
echo "Lancement du formatage bas niveau sur /dev/sda en arrière plan"
dd if=/dev/zero of=/dev/sda bs=4096 >> sortie.txt 2>&1 &
echo "Lancement du formatage bas niveau sur /dev/sdb en arrière plan"
dd if=/dev/zero of=/dev/sdb bs=4096 >> sortie.txt 2>&1 &
echo "Lancement du formatage bas niveau sur /dev/sdc en arrière plan"
dd if=/dev/zero of=/dev/sdc bs=4096 >> sortie.txt 2>&1 &
echo "Lancement du formatage bas niveau sur /dev/sdd en arrière plan"
dd if=/dev/zero of=/dev/sdd bs=4096 >> sortie.txt 2>&1 &
echo "Tous les formatages bas niveau ont été lancés. Veuillez patienter..."


result=$(ps -auf | grep -c "dd if=/dev/zero")
while [ $result != 1 ]
do
		result=$(ps -auf | grep -c "dd if=/dev/zero")
        sleep 60
done

timestamp=`date +%Y-%m-%d_%H-%M-%S`
echo $timestamp" Fin des opérations de formatage"
echo $timestamp" Fin des opérations de formatage" >> sortie.txt

mv ./result.txt ../$nomfic.txt

if [ $eteindre == "o" ]; then
        halt -p
fi

exit 0

