function panic()
{
    echo "$1" 1>&2
    exit 1
}

function checkSoftware()
{
    SW="`which avconv; which ffmpeg`"

    if [ -n "`echo $SW | grep avconv`" ]
    then
    CONVERTSOFTWARE="avconv"
    elif [ -n "`echo $SW | grep ffmpeg`" ]
    then
    CONVERTSOFTWARE="ffmpeg"
    else
    panic "Failed to search conversion software in remote server"
    fi
}

function getVideoInfo()
{
    $CONVERTSOFTWARE -i "$1" 2>&1
}

function getAllData()
{
    FILE="$1"
    if [ ! -r "$FILE" ]
    then
    panic "File $FILE not found"
    fi
    FILEINFO="`getVideoInfo "$FILE"`"
    DURATION=$(echo "$FILEINFO" | sed -n "s/.* Duration: \([^,]*\), start: .*/\1/p")
    BITRATE=$(echo "$FILEINFO" | sed -n "s/.* bitrate: \([^,]*\) kb\/s/\1/p")
    FPS=$(echo "$FILEINFO" | sed -n "s/.*, \(.*\) fps.*/\1/p")
    FRAMES=$(echo $DURATION | awk -F':' "{ FRAMES=(\$1*3600+\$2*60+\$3)*$FPS; print FRAMES }")
}

function convertsecs() 
{
    h=$(bc <<< "${1}/3600")
    m=$(bc <<< "(${1}%3600)/60")
    s=$(bc <<< "${1}%60")
    printf "%02d:%02d:%05.2f\n" $h $m $s
}

function generateImages()
{   
    FILE="$1"
    CUT_TIME=$2
    if [ ! -r "$FILE" ]
    then
    panic "File $FILE not found"
    fi
    getAllData "$FILE"
    PROGRESS=0
    PROGRESS_SECONDS=0
    DURATION_SECONDS=$(date +'%s' -d $DURATION)
    PERIOD=0
    while [ $PROGRESS_SECONDS -le $DURATION_SECONDS ]
    do
        PROGRESS=$(convertsecs $PERIOD) 
        $CONVERTSOFTWARE -ss $PROGRESS -i "$1" -vframes 1 -q:v 2 "outputs/output_$PROGRESS".jpg
        PERIOD=$[$PERIOD+$CUT_TIME]
        PROGRESS_SECONDS=$(date +'%s' -d $PROGRESS)
    done
}

checkSoftware

if [ -z "$1" ]
then
    panic "No input file"
fi

if [ -z "$3" ]
then
    FILE="$1"
    SECONDS="$2"
    DATA="all"
else
    FILE="$2"
    DATA="$1"
fi

case "$DATA" in
    "all")
    generateImages "$FILE" "$SECONDS"
    getAllData "$FILE"
    #echo "Duration: $DURATION"
    #echo "FPS: $FPS"
    #echo "Bitrate: $BITRATE kb/s"
    #echo "Total frames: $FRAMES"
    ;;
    "duration")
    getAllData "$FILE"
    #echo "$DURATION"
    ;;
    "seconds")
    getAllData "$FILE"
    SECS=$(($FRAMES/$FPS+$(($FRAMES%$FPS!=0))))
    #echo $SECS
    ;;
    "fps")
    getAllData "$FILE"
    #echo "$FPS"
    ;;
    "bitrate")
    getAllData "$FILE"
    #echo "$BITRATE"
    ;;
    "frames")
    getAllData "$FILE"
    #echo "$FRAMES"
    ;;
    *)
    panic "Element to extract not recognized: $DATA"
esac
