#!/bin/bash

# take the animal number, dicom directory, and task and convert them to bids format

#
# TODO: take in the name => done
# TODO: the task => done, you don't need to specify the task, it will be extracted from the dcm file
# TODO: cut the videos to match the name => done
# TODO: phase or magnitude => done
# TODO: normal phase or reverse phase => done
# TODO: how the dicom should be organized => done (the script takes in the zipped file)
# TODO: zeropad the earpunch number to 3 places => done
# TODO: list of possible answers for task (maybe write a new heuristic) => done
# TODO: take the TTL file as well (stimulus file)
# TODO: take the videos if the task matches whatever you define as video task => define manually
# TODO: add extra description to the script does => done
# TODO: test on Arthur's Brown data as well => done
# TODO: delete all unnecessary dirs => done (delete the DICOM dir)
# TODO: multiple sessions, maybe add an extra flag or make conditional if subject existed => done (works automatically)
# TODO: take in session number as well => done
# TODO: accept field maps as well => done
# TODO: add requirements file
# TODO: check that the runs are organized correctly => done
# TODO: extract useful info from the excel sheet => done, excel sheets get info from dcm header
# TODO: extract the subject's name and sessions from the zip or json
# TODO: check if the json files have acquisition date and start and duration => done unanonmize
# TODO: verify no of output files against no of input files # bad idea, some files are not necessary
# TODO: verify no of output files against no of dcm2niix files => done (verified manually)
# TODO: write a script to change dicom folders if the names of mag and phase like 430003 430004, not 001 and 002
# TODO: write a script to count the number of output from bids and input dcms # bad idea, some files are not necessary like single vol rs
# TODO: find out why rerunning heudiconv does not work and you have to delete .heudiconv and the data manually
# TODO: delete the videos with no functional runs

function Usage {
  cat <<USAGE

Usage:

Convert the dicom files from the discom server to BIDS format

$(basename "$0") -d DICOM_ZIP -i Animal_ID -s s1 -d BIDS_DIR

Compulsory arguments:


     -h:  display help message

     -z:  the dcm zip file that contains the dicom files from dcm server (abspath)

     -i:  animal ID, should be in this format EarPunchNo_CageNo_Gender

     -s:  session number

     -d:  directory where you want to put your nifti BIDS output (abspath)

     -f:  heurisitc file to use (heuristic_9T_rest_awake.py or heuristic_9T_Brown^TBI2AD.py)

     -c:  absolute path to config file



Example:

$(basename "$0") \
-z /Users/aeed/Documents/Work/Menon^AS-MBN/01_389630_M/20221119/DICOM \
-i 01_389630_M \
-s 1 \
-d /Users/aeed/Documents/Work/Menon^AS-MBN/01_389630_M/20221119/BIDS \
-f heuristic_9T.py
-c /Users/aeed/Documents/Work/bids_tools/bids_tools/dcm2niix_config.json

USAGE
  exit 1
}

# Check if first argument is "-h" OR if no arguments are passed to script
if [[ "$1" == "-h" || $# -eq 0 ]]; then
  Usage >&2
fi

while getopts "h:z:i:s:d:f:c:" OPT; do
  case $OPT in
  h) #help
    Usage
    exit 0
    ;;
  z) # zipped dcm file
    DICOM_ZIP=$OPTARG
    ;;
  i) # animal id
    ANIMAL_ID=$OPTARG
    ;;
  s) # animal id
    SESSION_NO=$OPTARG
    ;;
  d) # output bids dir
    BIDS_DIR=$OPTARG
    ;;
  f) # heuristic file
    HEURISTIC=$OPTARG
    ;;
  c) # config file
    CONFIG_FILE=$OPTARG
    ;;
  \?) # getopts issues an error message
    echo "$Usage" >&2
    exit 1
    ;;
  esac
done

# decompress the dcm file in the zipped file dir (it overwrites if exists automatically)
ZIP_DIR=$(dirname "${DICOM_ZIP}") # get the parent dir
mkdir "${ZIP_DIR}"/"${ANIMAL_ID}"_dcm
unzip -o "${DICOM_ZIP}" -d "${ZIP_DIR}"/"${ANIMAL_ID}"_dcm

# the animal id is earpunch_cagenumber_gender
# I zeropad the ear number to be three digits in case the number is 2 digits
# the heudiconv removes the underscore, so a zeropad will make it easier to identify
# aka 1st 3 places are ear number, next 6 digits are the cage number, anf the letter is the gender
heudiconv \
  --files "${ZIP_DIR}"/"${ANIMAL_ID}"_dcm \
  --outdir "${BIDS_DIR}" \
  --subjects $(zeropad "${ANIMAL_ID}" 11) \
  --ses $(zeropad "${SESSION_NO}" 2) \
  --heuristic "${HEURISTIC}" \
  --converter dcm2niix \
  --bids \
  --overwrite \
  --dcmconfig "${CONFIG_FILE}"

# If the corresponding folder exists for this subject, do nothing. Otherwise, move the dicom folder
# to the 'sourcedata' directory
if [ ! -d "${ZIP_DIR}"/"${ANIMAL_ID}"_dcm ]; then
  mv "${ZIP_DIR}"/"${ANIMAL_ID}"_dcm 
