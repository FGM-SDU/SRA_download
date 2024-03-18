#!/bin/bash

## INPUT: List of SRRs file
LIST=${3?Missing input SRRs list file}

function print_help {
  echo -e "\n$(basename $0) -m MODE sr or pe list_SRR.txt"
  echo " -m MODE             - Where mode is one of"
  echo "        sr       		 - Default parameter: single-end sequencing"
  echo "        pe    			 - pair-end sequencing"
  echo " -h                  - Show this help message"
}

MODE="none"
LINE=""

while getopts m:h SETUP; do
  case $SETUP in
    m)
      MODE="${OPTARG}"
      ;;
    h)
      print_help
      exit 0
      ;;
    \?)
      echo "Unknown option ${SETUP}"
      print_help
      exit 1
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

case ${MODE} in
	#for single end reads only
  sr)
    LINE="-m sr"
    ;;
  pe)
    LINE="-m pe"
    ;;
  *)
    echo "Unknown mode: ${MODE}"
    print_help
    exit 1
esac

if [ "z${LINE}" == "z" ]; then
  echo "No mode found?"
  print_help
  exit 1
fi


#for every SRR in the list of SRRs file
for srr in $(cat ${LIST})
do
#call the bash script that does the fastq dump, passing it the SRR number next in file
sbatch --output slurm-%x.%A.%a.log inner_script.slurm ${LINE} $srr
sleep 1	
#wait 1 second between each job submission

done
