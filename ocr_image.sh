

if ["$1" = ""]
then
    echo "ERROR!: please give the filename or path to extract the text";
    exit 1
else
    if ["$2" = ""]
    then    
        echo "ERROR!: please give the filename for the output textfile";
        exit 1
    else
        tesseract -l spa $1 $2
    fi
fi