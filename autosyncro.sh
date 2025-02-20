#!/bin/bash
#                                       ##############
#                                       # AutoSyncro #
#                                       ##############
#
# Configuration file for variable declaration
#
source ./autosyncro.conf
#
# Declaration of color code variables
#
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
#
# Logs
#
touch $LOG_FILE > /dev/null 2>&1
if [[ $? = 0 ]]; then
    exec > >(tee ${LOG_FILE}) 2>&1
else
    echo -e "${RED}Unable to create log file, check path and permissions${ENDCOLOR}"
    exit 2
fi
#
########## Functions ##########
#
### Alert functions ###
#
# Send an email in case of failure
#
warning_mail()
{
if [[ $MAILTO =~ "@" ]]; then
    echo "Backup failed, see $LOG_FILE"
    swaks -t $MAILTO -s $ASMTP:$PSMTP -tls -au $USMTP -ap $PASSMTP -f $MAILFROM --body "Backup failed" --h-Subject "AutoSyncro" --attach $LOG_FILE >> $LOG_FILE
else
    echo -e "${RED}Backup failed, see $LOG_FILE${ENDCOLOR}"
fi
}
#
# Check if commands executed successfully
#
check_cmd()
{
if [[ $? -eq 0 ]]; then
    	echo -e "${GREEN}OK${ENDCOLOR}"
else
    	echo -e "${RED}ERROR${ENDCOLOR}"
        warning_mail
fi
}
#
### Functions to check source, destination, and server targets ###
#
check_dir_fromdist ()
{
# Isolation of server, source directory, and user values
declare -r SERVER=$(echo $SOURCE | cut -d ':' -f1 | cut -d '@' -f2)
declare -r DIRECT=$(echo $SOURCE | cut -d ':' -f2)
declare -r SSHUSER=$(echo $SOURCE | cut -d ':' -f1 | cut -d '@' -f1)
# Check server availability
ping -c 2 $SERVER >> $LOG_FILE
if [[ $? != 0 ]]; then 
    echo -e "${RED}Server $SERVER is unreachable${ENDCOLOR}"
    warning_mail
    exit 112
else
    echo -e "${GREEN}Server $SERVER is responding${ENDCOLOR}"
fi
# Check if the remote source directory exists
ssh -p $PORT "$SSHUSER@$SERVER" "ls $DIRECT > /dev/null 2>&1" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "${RED}Directory $DIRECT does not exist on $SERVER or is inaccessible by $SSHUSER${ENDCOLOR}"
    warning_mail
    exit 2
fi
# Check if the local destination directory exists and has write permissions
if [[ ! -d "$DESTINATION" || ! -w "$DESTINATION" ]]; then
    echo -e "${RED}Directory $DESTINATION does not exist or is not writable${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
#
check_dir_todist ()
{
# Isolation of server, destination directory, and user values
declare -r SERVER=$(echo $DESTINATION | cut -d ':' -f1 | cut -d '@' -f2)
declare -r DIRECT=$(echo $DESTINATION | cut -d ':' -f2)
declare -r SSHUSER=$(echo $DESTINATION | cut -d ':' -f1 | cut -d '@' -f1)
# Check server availability
ping -c 2 $SERVER >> $LOG_FILE
if [[ $? != 0 ]]; then 
    echo -e "${RED}Server $SERVER is unreachable${ENDCOLOR}"
    warning_mail
    exit 112
else
    echo -e "${GREEN}Server $SERVER is responding${ENDCOLOR}"
fi
# Check if the remote destination directory exists
ssh -p $PORT "$SSHUSER@$SERVER" "touch $DIRECT/autosynchrotest.test && rm -f $DIRECT/autosynchrotest.test > /dev/null 2>&1" > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo -e "${RED}Directory $DIRECT does not exist on $SERVER or is not writable by $SSHUSER${ENDCOLOR}"
    warning_mail
    exit 2
fi
# Check if the local source directory exists and has read permissions
if [[ ! -d "$SOURCE" || ! -r "$SOURCE" ]]; then
    echo -e "${RED}Directory $SOURCE does not exist or is not readable${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
#
check_dir_loc2loc ()
{
# Check if the local source directory exists
if [[ ! -d "$SOURCE" || ! -r "$SOURCE" ]]; then
    echo -e "${RED}Directory $SOURCE does not exist or is not readable${ENDCOLOR}"
    warning_mail
    exit 2
# Check if the local destination directory exists
elif [[ ! -d "$DESTINATION" || ! -w "$DESTINATION" ]]; then
    echo -e "${RED}Directory $DESTINATION does not exist or is not writable${ENDCOLOR}"
    warning_mail
    exit 2
fi
}
### Function called for a backup from a remote server to a local directory ###
#
fromdist ()
{
#
check_dir_fromdist
#
# Check disk space
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir SPACE=$(rsync -arvn --delete --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
else
    declare -ir SPACE=$(rsync -arvn --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
fi
#
# Stop the script if there is insufficient space
#
if [[ "$FREE" -lt "$SPACE" ]]; then
    echo -e "${RED}Insufficient disk space${ENDCOLOR}"
    warning_mail
    exit 28
fi
#
# Number of items in the source directory
#
declare -r SERVER=$(echo $SOURCE | cut -d ':' -f1)
declare -r DIRECT=$(echo $SOURCE | cut -d ':' -f2)
declare -ir SOURCECONT=$(rsync -arvn --stats --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "Number of files" | awk '{print $4}' | sed s/[.]//g)-1
echo -e "${YELLOW}The source directory contains $SOURCECONT items${ENDCOLOR}"
#
# Number of items to synchronize
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir ELEMENTS=$(rsync -arvhn --delete --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
else
    declare -ir ELEMENTS=$(rsync -arvhn --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
fi
echo -e "${YELLOW}$ELEMENTS items to be modified${ENDCOLOR}"
#
# Stop the backup if more than n% or 0 items have been modified since the last backup
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [ "$ELEMENTS" -gt "$ELEMAXI" ]; then
    echo -e "${RED}Too many modifications: $ELEMENTS - backup interrupted${ENDCOLOR}"
    warning_mail
    exit 109
elif [ "$ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}No modifications to be made${ENDCOLOR}"
    exit 0
fi
#
# Start the backup
#
if [[ $SYNCRO == "yes" ]]; then
    echo -e "${GREEN}Synchronization in progress${ENDCOLOR}"
    rsync -arhv --delete --exclude={$EXCLUDE} --progress -e "ssh -p $PORT" $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
else
    echo -e "${GREEN}Backup in progress${ENDCOLOR}"
    rsync -arhv --exclude={$EXCLUDE} --progress -e "ssh -p $PORT" $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
### Function called for a backup from a local directory to a remote server ###
#
todist ()
{
#
check_dir_todist
#
# Retrieve server and directory values
#
declare -r SERVER=$(echo $DESTINATION | cut -d ':' -f1)
declare -r DIRECT=$(echo $DESTINATION | cut -d ':' -f2)
#
# Check disk space
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir SPACE=$(rsync -arvn --delete --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
    declare TMPFREE=$(ssh -p $PORT $SERVER "df -BK $DIRECT | grep "/" | sed 's/[a-z]//gI' | sed 's/[/]//g'")
    declare -ir FREE=$(echo $TMPFREE | awk '{print $4}')*1000
else
    declare -ir SPACE=$(rsync -arvn --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
    declare TMPFREE=$(ssh -p $PORT $SERVER "df -BK $DIRECT | grep "/" | sed 's/[a-z]//gI' | sed 's/[/]//g'")
    declare -ir FREE=$(echo $TMPFREE | awk '{print $4}')*1000
fi
#
# Stop the script if there is insufficient space
#
if [[ "$FREE" -lt "$SPACE" ]]; then
    echo -e "${RED}Insufficient disk space${ENDCOLOR}"
    warning_mail
    exit 28
fi
#
# Number of items in the source directory
#
declare -ir SOURCECONT=$(rsync -arvn --stats --exclude={$EXCLUDE} -e "ssh -p $PORT" $SOURCE $DESTINATION | grep "Number of files" | awk '{print $4}' | sed s/[.]//g)-1
echo -e "${YELLOW}The source directory contains $SOURCECONT items${ENDCOLOR}"
#
# Number of items to synchronize
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir ELEMENTS=$(rsync -arvn --delete --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS items to be modified${ENDCOLOR}"
else
    declare -ir ELEMENTS=$(rsync -arvn --exclude={$EXCLUDE} $SOURCE -e "ssh -p $PORT" $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS items to be modified${ENDCOLOR}"
fi
#
# Stop the backup if more than n% or 0 items have been modified since the last backup
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [ "$ELEMENTS" -gt "$ELEMAXI" ]; then
    echo -e "${RED}Too many modifications: $ELEMENTS - backup interrupted${ENDCOLOR}"
    warning_mail
    exit 109
elif [ "$ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}No modifications to be made${ENDCOLOR}"
    exit 0
fi
#
# Start the backup
#
if [[ $SYNCRO == "yes" ]]; then
    echo -e "${GREEN}Synchronization in progress${ENDCOLOR}"
    rsync -arhv --delete --exclude={$EXCLUDE} --progress $SOURCE -e "ssh -p $PORT" $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
else
    echo -e "${GREEN}Backup in progress${ENDCOLOR}"
    rsync -arhv --exclude={$EXCLUDE} --progress $SOURCE -e "ssh -p $PORT" $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
### Function called for a backup from a local directory to a local directory ###
#
loc2loc ()
{
#
check_dir_loc2loc
#
# Check disk space
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir SPACE=$(rsync -arvn --delete --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
else
    declare -ir SPACE=$(rsync -arvn --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep "size is" | awk '{print $4}' | sed 's/[.]//g')
    declare -ir FREE=$(df -BK "$DESTINATION" | grep "/" | awk '{print $4}' | sed 's/[a-z]//gI')*1000
fi
#
# Stop the script if there is insufficient space
#
if [[ "$FREE" -lt "$SPACE" ]]; then
    echo -e "${RED}Insufficient disk space${ENDCOLOR}"
    warning_mail
    exit 28
fi
#
# Number of items in the source directory
#
declare -ir SOURCECONT=$(rsync -arvn --stats --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep "Number of files" | awk '{print $4}' | sed s/[.]//g)-1
echo -e "${YELLOW}The source directory contains $SOURCECONT items${ENDCOLOR}"
#
# Number of items to synchronize
#
if [[ $SYNCRO == "yes" ]]; then
    declare -ir ELEMENTS=$(rsync -arvhn --delete --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS items to be modified${ENDCOLOR}"
else
    declare -ir ELEMENTS=$(rsync -arvhn --exclude={$EXCLUDE} $SOURCE $DESTINATION | grep -v -x "./" | wc -l)-4
    echo -e "${YELLOW}$ELEMENTS items to be modified${ENDCOLOR}"
fi
#
# Stop the backup if more than n% or 0 items have been modified since the last backup
declare -ir ELEMAXI=$(( $SOURCECONT*$MAXI/100 ))
#
if [ "$ELEMENTS" -gt "$ELEMAXI" ]; then
    echo -e "${RED}Too many modifications: $ELEMENTS - backup interrupted${ENDCOLOR}"
    warning_mail
    exit 109
elif [ "$ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}No modifications to be made${ENDCOLOR}"
    exit 0
fi
#
# Start the backup
#
if [[ $SYNCRO == "yes" ]]; then
    echo -e "${GREEN}Synchronization in progress${ENDCOLOR}"
    rsync -arhv --delete --exclude={$EXCLUDE} --progress $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
else
    echo -e "${GREEN}Synchronization in progress${ENDCOLOR}"
    rsync -arhv --exclude={$EXCLUDE} --progress $SOURCE $DESTINATION >> $LOG_FILE
    check_cmd
    exit 0
fi
}
#
##### Backup type #####
#
if [[ "$SOURCE" =~ "@" && ! "$DESTINATION" =~ "@"  ]]; then
    fromdist
elif [[ ! "$SOURCE" =~ "@" && "$DESTINATION" =~ "@"  ]]; then
    todist
elif [[ ! "$SOURCE" =~ "@" && ! "$DESTINATION" =~ "@"  ]]; then
    loc2loc
else 
    echo -e "${RED}Bad argument in config file (input and target)${ENDCOLOR}"
    exit 2
fi
