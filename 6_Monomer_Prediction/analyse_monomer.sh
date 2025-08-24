#! /bin/bash
LC_NUMERIC=C

#find pdb2fasta script from rosetta
PDB2FASTA=$(locate /main/source/scripts/python/public/pdb2fasta.py | head -n 1)

#variables

pdb_filtered=$1
out=$2
n_cores=$3

if [[ $# -ne 3 ]]
then
        echo "Usage ./analyse.sh <dir. with input pdbs> <dir. with colab output> <n_cores>"
else

#functions

function unzip_outputs {
mkdir unzip_output

for FILE_1 in $(ls $out/*.zip)
do
	#change names
	unzip $FILE_1 *_unrelaxed_rank_001* *scores_rank_001*
	mv *rank_001* unzip_output
done
}

function FastRelax {
mkdir relaxed_output

ls unzip_output/*.pdb > list.txt

mpiexec -np $n_cores rosetta_scripts.mpi.linuxgccrelease -parser:protocol relax_monomer_cst.xml -beta_nov16 -out:path:pdb relaxed_output -in:file:l list.txt

rm score.sc list.txt
}

function get_data {
echo "model,plddt,RMSD,fasta"
for FILE_2 in $(ls $pdb_filtered)
do
	#average pLDDP
	plddp=$(cat unzip_output/${FILE_2::-4}*.json | jq '.plddt | map(tostring) | join(" ")' | grep -oE '[0-9]+(\.[0-9]+)?' | awk '{ sum += $1 } END { print sum / NR }')
	RMSD=$(TMscore $pdb_filtered/$FILE_2 unzip_output/${FILE_2::-4}*.pdb | grep RMSD | tr -d -c '[. [:digit:]]' | xargs -n1)
	fasta=$(python2 $PDB2FASTA $pdb_filtered/$FILE_2 | head -n 2 | tail -n 1) 
	
	echo ${FILE_2::-4}","$plddp","$RMSD","$fasta
done
}

function filter {
echo "model,plddp,RMSD,fasta"

for LINE in $(tail -n +2 data.csv)
do
	plddp=""
	RMSD=""
	
	plddp=$(echo $LINE | awk -F ',' '{print $2}')
	RMSD=$(echo $LINE | awk -F ',' '{print $3}')

	if [[ $(echo "$plddp > 90" | bc -l) -eq 1 && $(echo "$RMSD < 1.2" | bc -l) -eq 1 ]]
	then
		echo $LINE 
	fi
done 
}


#Execute the functions

unzip_outputs
FastRelax
get_data | sort -n > data.csv
filter | sort -n > filtered_data.csv

fi
