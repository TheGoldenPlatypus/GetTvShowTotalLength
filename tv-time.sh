#!/bin/bash

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

function findMinMax { 
    local leftIndex=$1;
    local rightIndex=$2;

    local min=0;
    local max=0;
    local minShow="";
    local maxShow="";

    local dif=$((rightIndex-leftIndex))
    local absDif=${dif#-}

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

        # echo *indexes: $leftIndex $rightIndex, $minShow $min $maxShow $max, exitCodeLeft=$exitCodeLeft exitCodeRight=$exitCodeRight>> outpulMinMax.txt
    else

        local min1=0;
        local max1=0;
        local minShow1;
        local maxShow1;

        local min2=0;
        local max2=0;
        local minShow2;
        local maxShow2;

        local id=$(getUUID);
        local out1="$TEMP_FOLDER_PATH/out1_$id";
        local out2="$TEMP_FOLDER_PATH/out2_$id";
        # touch $out1;
        # touch $out2;
        local middle=$((leftIndex+absDif/2));
        findMinMax $leftIndex $middle > "$out1" &
        findMinMax $(($middle+1)) $rightIndex > "$out2" &
        wait

        local res1=$(< $out1);
        local res2=$(< $out2);
        rm $out1;
        rm $out2;
        read minShow1 min1 maxShow1 max1 < <(echo $res1);
        read minShow2 min2 maxShow2 max2 < <(echo $res2);
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

        # echo -indexes: $leftIndex $rightIndex res1=[$minShow1 $min1 $maxShow1 $max1] res2=[$minShow2 $min2 $maxShow2 $max2]>> outpulMinMax.txt
        
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

        # echo min1=$min1 max1=$max1 _ min2=$min2 max2=$max2 _ , indexes: $leftIndex $rightIndex, min=$min max=$max _ pid=$$>> outpulMinMax.txt
    fi

    echo "$minShow; $min; $maxShow; $max";
}



app=$GET_TVSHOW_TOTAL_LENGTH_BIN #"./GetTvShowTotalLength/bin/Debug/net6.0/GetTvShowTotalLength"

#echo "" > outpulMinMax.txt

filename=$(readlink /proc/self/fd/0);
mapfile -t arr;
while IFS= read -r line
do 
    arr+= $line; 
done

makeTempFolder;

arrLen=${#arr[@]};
# echo arr=[${arr[@]}] arrLen=$arrLen
result=$(findMinMax 0 $((arrLen-1)) )
# echo $result
rm -r $TEMP_FOLDER_PATH

#parse result
IFS=';' read -ra parsedRes <<< $result
minShow=${parsedRes[0]};
min=${parsedRes[1]};
maxShow=${parsedRes[2]};
max=${parsedRes[3]};

printf "The shortest show: %s (%dh:%dm)\n" "$minShow" "$((min/60))" "$((min%60))"
printf "The longest show: %s (%dh:%dm)\n" "$maxShow" "$((max/60))" "$((max%60))"
