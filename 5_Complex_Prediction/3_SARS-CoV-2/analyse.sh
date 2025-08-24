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
	unzip $FILE_1 *rank_1*
	mv *rank_1* unzip_output 
done
}

function FastRelax {
mkdir relaxed_output

ls unzip_output/*.pdb > list.txt

mpiexec -np $n_cores rosetta_scripts.mpi.linuxgccrelease -parser:protocol relax.xml -beta_nov16 -out:path:pdb relaxed_output -in:file:l list.txt

rm score.sc list.txt
}

function get_data {
echo "model,iptm,ptm,confidence,RMSD,binder_fasta"
for FILE_2 in $(ls $pdb_filtered)
do
	#iptm
	iptm=$(cat unzip_output/${FILE_2::-4}*.json | jq '.iptm')
	ptm=$(cat unzip_output/${FILE_2::-4}*.json | jq '.ptm')
	conf=$(python3 -c "print(($iptm * 0.8) + ($ptm * 0.2))")
	RMSD=$(TMscore -c -ter -2 $pdb_filtered/$FILE_2 relaxed_output/${FILE_2::-4}*.pdb | grep RMSD | tr -d -c '[. [:digit:]]' | xargs -n1)
	binder_fasta=$(python2 $PDB2FASTA $pdb_filtered/$FILE_2 | head -n 2 | tail -n 1) 
	
	echo ${FILE_2::-4}","$iptm","$ptm","$conf","$RMSD","$binder_fasta
done
}

function filter {
echo "model,iptm,ptm,confidence,RMSD,binder_fasta"

for LINE in $(tail -n +2 data.csv)
do
	confidance=""
	RMSD=""
	
	confidance=$(echo $LINE | awk -F ',' '{print $4}')
	RMSD=$(echo $LINE | awk -F ',' '{print $5}')

	if [[ $(echo "$confidance > 0.8" | bc -l) -eq 1 && $(echo "$RMSD < 1.5" | bc -l) -eq 1 ]]
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
