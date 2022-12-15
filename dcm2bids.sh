#!/bin/bash

# take the animal number, dicom directory, and task and convert them to bids format

#
# TODO: take in the name => done
# TODO: the task
# TODO: cut the videos to match the name
# TODO: phase or magnitude => done
# TODO: normal phase or reverse phase => done
# TODO: how the dicom should be organized => done (the script takes in the zipped file)
# TODO: zeropad the earpunch number to 3 places => done
# TODO: list of possible answers for task (maybe write a new heuristic)
# TODO: take the TTL file as well
# TODO: take the videos if the task matches whatever you define as video task
# TODO: add extra desription to the script does => done
# TODO: test on Arthur's Brown data as well => done
# TODO: delete all unnecessary dirs => done (delet the DICOM dir)
# TODOL multiple sessions, maybe add an extra flag or make conditional if subject existed => done (works automatically)
# TODO: take in session number as well => done
# TODO: accept field maps as well => done
# TODO: add requirements file


function Usage {
    cat <<USAGE

Usage:

Convert the dicom files from the discom server to BIDS format

`basename $0` -d DICOM_ZIP -i Animal_ID -t Task -s s1 -d BIDS_DIR

Compulsory arguments:


     -h:  display help message

     -z:  the dcm zip file that contains the dicom files from dcm server (abspath)

     -i:  animal ID, should be in this format EarPunchNo_CageNo_Gender

     -s:  session number

     -t:  type of task (or lack of)

     -d:  directory where you want to put your nifti BIDS output (abspath)

     -f:  heurisitc file to use (heuristic_9T.py or heuristic_9T_Brown^TBI2AD.py)



Example:

`basename $0` \
-z /Users/aeed/Documents/Work/Menon^AS-MBN/01_389630_M/20221119/DICOM \
-i 01_389630_M \
-s s1 \
-t whisker_stimulation \
-d /Users/aeed/Documents/Work/Menon^AS-MBN/01_389630_M/20221119/BIDS \
-f heuristic_9T.py

USAGE
    exit 1
}


if [[ "$1" == "-h" || $# -eq 0 ]];
  then
    Usage >&2
  fi

while getopts "h:z:i:s:t:d:f:" OPT
  do
  case $OPT in
      h) #help
   Usage
   exit 0
   ;;
      z)  # zipped dcm file
   DICOM_ZIP=$OPTARG
   ;;
      i)  # animal id
   ANIMAL_ID=$OPTARG
   ;;
   s)  # animal id
   SESSION_NO=$OPTARG
   ;;
      t)  # task type
   TASK=$OPTARG
   ;;
      d)  # output bids dir
   BIDS_DIR=$OPTARG
   ;;
     f)  # output bids dir
   HEURISTIC=$OPTARG
   ;;
     \?) # getopts issues an error message
   echo "$Usage" >&2
   exit 1
   ;;
  esac
done


# decompress the dcm file in the zipped file dir
ZIP_DIR=`dirname ${DICOM_ZIP}` # get the parent dir
unzip ${DICOM_ZIP} -d ${ZIP_DIR}

# the animal id is earpunch_cagenumber_gender
# I zeropad the ear number to be three digits in case the number is 2 digits
# the heudiconv removes the underscore, so a zeropad will make it easier to identify
# aka 1st 3 places are ear number, next 6 digits are the cage number, anf the letter is the gender
heudiconv \
--files ${ZIP_DIR}  \
--outdir ${BIDS_DIR}  \
--subjects `zeropad ${ANIMAL_ID} 12`  \
--ses ${SESSION_NO} \
--heuristic ${HEURISTIC}  \
--converter dcm2niix \
--bids \
--overwrite


# delete the dicom folder
rm ${ZIP_DIR}
