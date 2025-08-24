#! /bin/bash

#variables
filtered_list=$1
pdb_filtered_dir1=$2
n_cores=$3

if [[ $# -ne 3 ]]
then
        echo "Usage ./script.sh <filtered_pdbs_list.csv> <pdb_filtered_dir1> <n_cores>"
else

function cp_complexes {
for LINE in $(tail -n +2 $filtered_list)
do
	name=$(echo $LINE | awk -F ',' '{print $1".pdb"}')
	cp $pdb_filtered_dir1/$name .  
done
}

function separate_monomer {

mkdir complexes
 
for FILE in $(ls *.pdb)
do
	pdb_selchain -A $FILE | grep ATOM > ${FILE::-4}"_m.pdb"
	mv $FILE complexes
done
}

function FastRelax {

mkdir temp
mv *_m.pdb temp
ls temp/* > list.txt

mpiexec -np $n_cores rosetta_scripts.mpi.linuxgccrelease -parser:protocol relax_monomer_no_cst.xml -beta_nov16 -in:file:l list.txt -no_nstruct_label

rm -r list.txt score.sc temp
mkdir monomers 
mv *_m.pdb monomers
}

cp_complexes
separate_monomer
FastRelax

fi
