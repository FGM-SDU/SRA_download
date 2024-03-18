#!/bin/bash -l
#SBATCH -p CLOUD       # Names to use the serial partition
#SBATCH --output slurm-%x.%A.%a.log   # Names an output file for what would go to STDOUT, %x %A %a represent jobname jobid jobarrayindex  
#SBATCH --mail-user victorg@bmb.sdu.dk   # Names an address to be emailed when the job finishes
#SBATCH --mail-type END,FAIL,ARRAY_TASKS  # Specifies when the job finishes (either correctly or failed)
#SBATCH --job-name sra_download   # Gives the job a name, so you can find its log file & see it in the queue status, etc
#SBATCH --nodes 1         # How many nodes to be used, ie one compute nodes
#SBATCH --mem 44G        # The job can use up to __GB of ram. It is mutually exclusive with --mem-per-cpu.
#SBATCH --cpus-per-task 8    # How many cores on that node
#SBATCH -t 1-20:6:30       # Means to use up to days-hours:minutes:seconds of run time before it will get killed


# run in u1-standard-8 node

## Loading modules
module load SRA-Toolkit

## INPUT FILE
SRR=${3?Missing input SRR file}

function print_help {
  echo -e "\n$(basename $0) -m MODE sr or pe"
  echo " -m MODE                 - Where mode is one of"
  echo "        sr       		 - Default parameter: single-end sequencing"
  echo "        pe    			 - pair-end sequencing"
  echo " -h                      - Show this help message"
}

MODE="none"
OPT=""

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


## Estimating space requirements
echo "Estimating space requirements of ${SRR} ..."
vdb-dump --info "${SRR}"

## Downloading
echo "Downloading ${SRR} ..."
prefetch --max-size u "${SRR}" # unlimited (default maximum download-size of 20G)

SRAFILE="${SRR}.sra"

## Conversion to fastq
echo "Running fasterq-dump..."

case ${MODE} in
	#for single end reads only
  sr)
    OPT=""
    ;;
  # for pair-end sequencing  
  pe)
    OPT="--split-3"
    ;;
  *)
    echo "Unknown mode: ${MODE}"
    print_help
    exit 1
esac

if [ "z${OPT}" == "z" ]; then
  echo "No mode found?"
  print_help
  exit 1
fi

fasterq-dump -m ${SLURM_MEM_PER_NODE} --threads ${SLURM_CPUS_PER_TASK} "${OPT}" ./${SRR}/${SRAFILE}

## Compressing
echo "Compressing ${SRR}.fastq ..."

if [ "${MODE}" == "pe" ]; then
  gzip "${SRR}_1.fastq"
  gzip "${SRR}_2.fastq"
  # Renaming
  mv "${SRR}_1.fastq.gz" "${SRR}_R1_001.fastq.gz"
  mv "${SRR}_2.fastq.gz" "${SRR}_R2_001.fastq.gz"
else
 gzip "${SRR}.fastq"
 # Renaming
  mv "${SRR}.fastq.gz" "${SRR}_R1_001.fastq.gz"
fi

## Remove folder with sra file
if [ -e "${SRR}_R1_001.fastq.gz" ]; then
  rm -r "${SRR}"
fi

echo "DONE!!!"
