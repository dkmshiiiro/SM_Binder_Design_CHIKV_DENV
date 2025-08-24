#! /bin/bash

#find pdb2fasta script from rosetta
PDB2FASTA=$(locate /main/source/scripts/python/public/pdb2fasta.py | head -n 1)

#variables
pdb_filtered=$1

if [[ $# -ne 1 ]]
then
        echo "Usage ./prepare_input_colab.sh <directory with pdbs>"
else

echo "id,sequence" > input.csv

for FILE in $(ls $pdb_filtered/*.pdb)
do
	complex=$(python2 $PDB2FASTA $FILE | head -n 1 | cut -c 2-)
	binder_fasta=$(python2 $PDB2FASTA $FILE | head -n 2 | tail -n 1)
	target_fasta_A=$(python2 $PDB2FASTA $FILE | tail -n 2 | head -n 1)
	target_fasta_B=$(python2 $PDB2FASTA $FILE | tail -n 1)
	echo ${complex::-4}","$binder_fasta":"$target_fasta_A":"$target_fasta_B >> input.csv
	
done
fi
