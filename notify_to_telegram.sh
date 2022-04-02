#!/bin/bash

#########################################################################
# Script to receive telegram notifications about Duplicati backup results
#########################################################################

# Duplicati is able to run scripts before and after backups. This 
# functionality is available in the advanced options of any backup job (UI) or
# as option (CLI). The (advanced) options to run scripts are
# --run-script-before = your/path/notify_to_telegram.sh
# --run-script-after = your/path/notify_to_telegram.sh

# To work, you need to set two required variables:
#  TELEGRAM_TOKEN
#  TELEGRAM_CHATID
# These variables can be set directly in the script file
# or added to environment variables using other methods.
#########################################################################

#TELEGRAM_TOKEN=<your telegram token>     Еnter without quotes!!!
#TELEGRAM_CHATID=<your telegram chatid>   Еnter without quotes!!!
TELEGRAM_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"

function getFriendlyFileSize() {
    size=$1
    if [ $size -eq "0" ]; then
        size='-'
    elif [ $size -ge 1099511627776 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1099511627776}')Tb
    elif [ $size -ge 1073741824 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1073741824}')Gb
    elif [ $size -ge 1048576 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1048576}')Mb
    elif [ $size -ge 1024 ]; then
        size=$(awk 'BEGIN {printf "%.1f",'$size'/1024}')Kb
    fi
    echo $size
}

CURRENT_STATUS=`echo "BEFORE=Started,AFTER=Finished" | sed "s/.*$DUPLICATI__EVENTNAME=\([^,]*\).*/\1/"`
MESSAGE="  DUPLICATI BACKUP
———————————————————————————
◉ Task:      $DUPLICATI__backup_name
◉ Operation: $DUPLICATI__OPERATIONNAME
◉ Status:    $CURRENT_STATUS"

if [ "$DUPLICATI__EVENTNAME" == "AFTER" ]; then
RESULT_ICON=`echo "Unknown=🟣,Success=🟢,Warning=🟡,Error=🔴,Fatal=🛑" | sed "s/.*$DUPLICATI__PARSED_RESULT=\([^,]*\).*/\1/"`
MESSAGE="$RESULT_ICON $MESSAGE
◉ Result:    $DUPLICATI__PARSED_RESULT
———————————————————————————"

if [ "$DUPLICATI__PARSED_RESULT" == "Fatal" ]; then
eval `sed -n "s/^\(\w*\):\s*\([^\"]*\)$/\1=\"\2\"/p" $DUPLICATI__RESULTFILE`
MESSAGE+="
⦿ Error: $Failed
⦿ Details: $Details
"
else # Not Fatal
eval `sed -n "s/^\(\w*\):\s*\(\w*\)$/\1=\2/p" $DUPLICATI__RESULTFILE`
MESSAGE+="
FILES:       count     size
⦿ Added:    `printf %*s 4 $AddedFiles` `printf %*s 10 $(getFriendlyFileSize $SizeOfAddedFiles)`
⦿ Deleted:  `printf %*s 4 $DeletedFiles` `printf %*s 10 $(getFriendlyFileSize 0)`
⦿ Changed:  `printf %*s 4 $ModifiedFiles` `printf %*s 10 $(getFriendlyFileSize $SizeOfModifiedFiles)`
⦿ Opened:   `printf %*s 4 $OpenedFiles` `printf %*s 10 $(getFriendlyFileSize $SizeOfOpenedFiles)`
⦿ Examined: `printf %*s 4 $ExaminedFiles` `printf %*s 10 $(getFriendlyFileSize $SizeOfExaminedFiles)`
———————————————————————————
FOLDERS:
⦿ Added:    `printf %*s 4 $AddedFolders` `printf %*s 10 $(getFriendlyFileSize 0)`
⦿ Deleted:  `printf %*s 4 $DeletedFolders` `printf %*s 10 $(getFriendlyFileSize 0)`
⦿ Changed:  `printf %*s 4 $ModifiedFolders` `printf %*s 10 $(getFriendlyFileSize 0)`
"
fi

else # Not AFTER
    MESSAGE="   $MESSAGE"
fi

MESSAGE=\`${MESSAGE}\`
curl -s $TELEGRAM_URL -d chat_id=$TELEGRAM_CHATID -d text="$MESSAGE" -d parse_mode="markdown" -k > /dev/null

exit 0