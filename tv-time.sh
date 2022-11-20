#!/bin/bash

# Copyright 2022 Omer Ratsaby
#
# This is a BASH script that uses C# application to get the
# total length of given TV shows and find the 
# shortest and the longest from a given list.
#
# Please note: a path to GetTvShowTotalLength C# application (binary) 
# should be passed via environment variable GET _TVSHOW_ TOTAL _LENGTH_ BIN.
#
# By default, the variable is not set. Please set this variable in this way:
# export GET_TVSHOW_TOTAL_LENGTH_BIN ="./GetTvShowTotalLength/bin/Debug/net6.0/GetTvShowTotalLength"
#
# then you can run the script with the following command:
# ./tv-time.sh < tv-shows.txt

echoerr() { 
    echo "$@" 1>&2; 
}


function getUUID()
{
    local N B T

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%255 ))

        if (( N == 6 ))
        then
            printf '4%x' $(( B%15 ))
        elif (( N == 8 ))
        then
            local C='89ab'
            printf '%c%x' ${C:$(( $RANDOM%${#C} )):1} $(( B%15 ))
        else
            printf '%02x' $B
        fi

        for T in 3 5 7 9
        do
            if (( T == N ))
            then
                printf '-'
                break
            fi
        done
    done

    echo
}


function makeTempFolder() {
    folderId=$(getUUID);
    TEMP_FOLDER_PATH="./myTemp$folderId";
    mkdir "$TEMP_FOLDER_PATH/" 2> /dev/null;
}

#######################################
# Find the Maximal&Minimal Length of a TV-show
# using a parallel calls to a c# app 
# this recursive fucntion implements "divide and conquer" algorithm
# to achieve it in O(log(n)) time complexity.
# GLOBALS:
#  An Array containing TV-shows names
# ARGUMENTS:
#   Indexes of the first and the last elements of an array
# OUTPUTS:
#   The shortest/longest TV-shows and their durations
#######################################
function findMinMax { 
    local leftIndex=$1;
    local rightIndex=$2;

    local min=0;
    local max=0;
    local minShow="";
    local maxShow="";

    local dif=$((rightIndex-leftIndex))
    local absDif=${dif#-}

    # Base Case - if the length of the array is less or equal to 1
    # determine the min& max shows and updates the local varibles. 
    # this block also handles missing data occurrences
    if [[ $absDif -le 1 ]]
    then
        local leftShow=${arr[$leftIndex]};
        local rightShow=${arr[$rightIndex]};
        local leftTime=$(${app} "\"${leftShow}"\");
        local exitCodeLeft=$?
        local rightTime=$(${app} "\"${rightShow}"\");
        local exitCodeRight=$?
        
        if [[ $exitCodeLeft -ne 0 || $leftTime == "" ]] && [[ $exitCodeRight -ne 10 || $rightTime == "" ]]
        then
            echoerr "Could not get info for \"$leftShow\" $leftTime $exitCodeLeft and \"$rightShow\" $rightTime $exitCodeRight. "
            min=1000000000;
            minShow=none;
            max=-1;
            maxShow=none;
        elif [[ $exitCodeLeft -ne 0 || $leftTime == "" ]]
        then
            echoerr "Could not get info for $leftShow."
            min=$rightTime;
            minShow=$rightShow;
            max=$rightTime;
            maxShow=$rightShow;
        elif [[ $exitCodeRight -ne 0 || $rightTime == "" ]]
        then
            echoerr "Could not get info for $rightShow."
            min=$leftTime;
            minShow=$leftShow;
            max=$leftTime;
            maxShow=$leftShow;
        elif [[ $leftTime -lt $rightTime ]]
        then
            min=$leftTime;
            minShow=$leftShow;

            max=$rightTime;
            maxShow=$rightShow;
        else
            min=$rightTime;
            minShow=$rightShow;

            max=$leftTime;
            maxShow=$leftShow;
        fi
    
    
    else

        local min1=0;
        local max1=0;
        local minShow1;
        local maxShow1;

        local min2=0;
        local max2=0;
        local minShow2;
        local maxShow2;

        # creating files with UUID to store temporery data computed by the subprocceses.
        # since child processes can't feed back the results to the parent,the file are used
        # as an intermediate communicators
        local id=$(getUUID);
        local out1="$TEMP_FOLDER_PATH/out1_$id";
        local out2="$TEMP_FOLDER_PATH/out2_$id";

        # double call to the function with each half of the data
        local middle=$((leftIndex+absDif/2));
        findMinMax $leftIndex $middle > "$out1" &
        findMinMax $(($middle+1)) $rightIndex > "$out2" &

        # join-like command that waits for both calls to finish their calculations 
        wait

        # delete temp folders 
        local res1=$(< $out1);
        local res2=$(< $out2);
        rm $out1;
        rm $out2;
        read minShow1 min1 maxShow1 max1 < <(echo $res1);
        read minShow2 min2 maxShow2 max2 < <(echo $res2);
        
        # parse result by spliting ths string result according to the char ';'
        # for each half result
        
        local parsedRes1;
        IFS=';' read -ra parsedRes1 <<< $res1
        minShow1=${parsedRes1[0]};
        min1=${parsedRes1[1]};
        maxShow1=${parsedRes1[2]};
        max1=${parsedRes1[3]};

        local parsedRes2;
        IFS=';' read -ra parsedRes2 <<< $res2
        minShow2=${parsedRes2[0]};
        min2=${parsedRes2[1]};
        maxShow2=${parsedRes2[2]};
        max2=${parsedRes2[3]};
        
        if [[ $min1 -lt $min2 ]]
        then
            min=$min1;
            minShow=$minShow1;
        else
            min=$min2;
            minShow=$minShow2;
        fi

        if [[ "$max1" -gt "$max2" ]]
        then
            max=$max1;
            maxShow=$maxShow1;
        else
            max=$max2;
            maxShow=$maxShow2;
        fi

    fi

    # No return since the func desinged to output a batch of values
    echo "$minShow; $min; $maxShow; $max";
}


app=$GET_TVSHOW_TOTAL_LENGTH_BIN #"./GetTvShowTotalLength/bin/Debug/net6.0/GetTvShowTotalLength"

# read data fron .txt file and stores it in array line by line
filename=$(readlink /proc/self/fd/0);
mapfile -t arr;
while IFS= read -r line
do 
    arr+= $line; 
done

# tempFolder stores temporary files which used 
# by the subprocesses to r/w data
makeTempFolder;

arrLen=${#arr[@]};
# call the findMinMax func with the indexes
# of the first and the last elements of the shows array
result=$(findMinMax 0 $((arrLen-1)) )
rm -r $TEMP_FOLDER_PATH

# parse result by spliting ths string result according to
#  the char ';'
IFS=';' read -ra parsedRes <<< $result
minShow=${parsedRes[0]};
min=${parsedRes[1]};
maxShow=${parsedRes[2]};
max=${parsedRes[3]};

# print to stdout the requested result
printf "The shortest show: %s (%dh:%dm)\n" "$minShow" "$((min/60))" "$((min%60))"
printf "The longest show: %s (%dh:%dm)\n" "$maxShow" "$((max/60))" "$((max%60))"
