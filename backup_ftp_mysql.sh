#!/bin/sh

#---------------------------------------------------------------#
# Script de sauvegarde MySQL XENETIS.ORG
#
# Nécessite le client FTP NCFTP
#       #apt-get install ncftp
#
# Crontab / tous les jours ? 01h05
#       #crontab -e
#
# 05 01 * * * /home/backup_mysql/backup_ftp_mysql.sh
#---------------------------------------------------------------#

# Configuration du FTP distant
loginftp="sd-161401"
passftp="NancyCloud54!"
hostftp="dedibackup-dc3.online.net"
portftp=21
dossierdistantftp="/home/backup_serveur_mysql"
dossierlocalsql="/home/backup_mysql"

# Configuration SQL LOCAL
loginsql="root"
passsql="NancyCloud54!"

# On liste les databases
DATABASES="$(mysql -u $loginsql -p$passsql -Bse 'show databases;')";

# Si une erreur survient pendant la liste des bases
if [ ! $? -eq 0 ]; then
       echo " - Une erreur s'est produite pendant le listage des bases de données";
       exit 1;
fi

# Boucle : pour créer le sql de chaque base
for BASE in $DATABASES
do
    # Analyse de la base
    mysqlcheck -u $loginsql -p$passsql -c -a $BASE > /dev/null

    echo " - Sauvegarde de la base "$BASE;

    mysqldump -u $loginsql -p$passsql --add-drop-database -B  --add-drop-table --complete-insert --routines --triggers --allow-keywords --max_allowed_packet=50M --force $BASE -R > $dossierlocalsql"/"$BASE".sql";
done

# Boucle : pour créer le tar.gz de chaque base
for BASE in $DATABASES
do
    tar -czf $dossierlocalsql"/"$BASE".tar.gz"  $dossierlocalsql"/"$BASE".sql";  
    ncftpput -u $loginftp -p $passftp -P $portftp -F $hostftp $dossierdistantftp $dossierlocalsql"/"$BASE".tar.gz";  
  
done

# Boucle : pour effacer les fichiers de sauvegarde du serveur de production
for BASE in $DATABASES
do
    rm $dossierlocalsql"/"$BASE".sql"
    rm $dossierlocalsql"/"$BASE".tar.gz";  
done