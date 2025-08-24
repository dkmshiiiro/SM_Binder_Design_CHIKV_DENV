#! /bin/bash

#variables
pdbs=$1

if [[ $# -ne 1 ]]
then
        echo "Usage ./change_HIS_HIP <directory with pdbs>"
else

for FILE in $(ls $pdbs/*.pdb)
do
	python pdb_rplresname.py -HIS:HIP $FILE > ${FILE::-4}"_temp.pdb"
	mv ${FILE::-4}"_temp.pdb" $FILE
done
fi
