#!/bin/bash
# Author: Rodney Yates (VRPC)
# Modified to actually function by Luke Leblanc
# Modified to work in Pterodactyl by tmunsch

if [ -z "$UPDATE_PLUGINS" ] || [ "$UPDATE_PLUGINS" == "true" ]; then
    function ProgressBar {
        #credit: Teddy Skarin (fearside) https://github.com/fearside/ProgressBar/blob/master/progressbar.sh
        let _progress=(${1}*100/${2}*100)/100
        let _done=(${_progress}*4)/10
        let _left=40-$_done

        _done=$(printf "%${_done}s")
        _left=$(printf "%${_left}s")

        printf "\rProgress : [${_done// /#}${_left// /-}] ${_progress}%%"
    }

    if [ $# -ne 2 ]; then
        basepath=$PWD
    else
        if [ "$1" != "-basepath" ]; then
            basepath=$1
        else
            basepath=$PWD
        fi
    fi

    logfile="${basepath}updater.log"
    FILES="${basepath}oxide/plugins/*.cs"
    n_items=$(ls 2>/dev/null -Ubad1 -- $FILES | wc -l)
    i=0
    updated=0
    url="https://umod.org/plugins/"

    # Cleaning out log file before run
    cat /dev/null > ${logfile}

    printf "%s - UMOD updater script.\n" "$(date +%F_%T)" |& tee -a ${logfile}
    printf "Found $n_items umod (oxide) files to be processed.\n" |& tee -a ${logfile}

    ProgressBar $i $n_items

    for f in $FILES
    do
        basenamefile=$(basename "${f}")
        tempfile="${basenamefile}.temp"

        #Download plugin to temp file. Umod web server does not have timestamping turned on so Last-Modified header is not available
        curl -s --fail --fail-early -o ${basepath}${tempfile} ${url}${basenamefile}

        # Check differences in downloaded plugin to plugin on disk
        DIFF=$(diff ${basepath}${tempfile} ${f})

        if [ "$DIFF" ]; then
            ((updated++))

            printf "Change detected, updating plugin ${basenamefile}.\n" &>> ${logfile}

            # Copy temp file of updated plugin
            mv "${basepath}${tempfile}" "${f}"

            if [ $? -ne 0 ]; then
                printf "\n$(date +%f_%T) - File copy failed, exiting. Check logs\n" |& tee -a ${logfile}
                exit 1
            fi
        else
            printf "No changes detected, no update required for ${basenamefile}.\n" &>> ${logfile}
            rm -rf "${basepath}${tempfile}"
        fi

        ((i++)) # increment progress

        ProgressBar $i $n_items #Update progress

        sleep 0.5 #Sleep to not spam the web server
    done

    printf "\n$(date +%f_%T) - Finished! Updated $updated plugins. Check updater.log for details.\n" |& tee -a ${logfile}
    printf "Starting Server..."
else
    printf "Starting Server..."
fi
