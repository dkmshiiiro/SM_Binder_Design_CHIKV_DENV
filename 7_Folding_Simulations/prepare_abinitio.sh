#! /bin/bash

#find pdb2fasta script from rosetta
PDB2FASTA=$(locate /main/source/scripts/python/public/pdb2fasta.py | head -n 1)


#variables
n_cores=$1

if [[ $# -ne 1 ]]
then
        echo "Usage ./prepare_abinitio.sh <n_cores>
        You need to have in ~/Downloads:
        Fragment files named (name)_frags3.200_v1_3 and (name)_frags9.200_v1_3
        Sec. struct. pred. file named (name).psipred_ss2, remember to take out the first to line of this file
        
        Current dir:
        relax_monomer.xml
        pdb files of complexes"
else

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

mpiexec -np $n_cores rosetta_scripts.mpi.linuxgccrelease -parser:protocol relax_monomer.xml -beta_nov16 -in:file:l list.txt -no_nstruct_label

rm -r list.txt score.sc temp
}

function prepare {
for FILE in $(ls *.pdb)
do
	echo ${FILE::-4}
	mkdir ${FILE::-6}
	echo "-in:file:native $FILE
-in:file:fasta ${FILE::-6}.fasta 
-in:file:frag3 ${FILE::-6}_frags3.200_v1_3
-in:file:frag9 ${FILE::-6}_frags9.200_v1_3
-abinitio:relax 
-relax:fast
-relax:script MonomerRelax2019
-ex1
-ex2aro
-score:weights beta_nov16
-beta_nov16
-abinitio::increase_cycles 10 
-abinitio::rg_reweight 0.5 
-abinitio::rsd_wt_helix 0.5 
-abinitio::rsd_wt_loop 0.5 
-use_filters true 
-psipred_ss2 ${FILE::-6}.psipred_ss2" > ${FILE::-6}/flags_abinitio

	python2 $PDB2FASTA $FILE | head -n 2 > ${FILE::-6}/${FILE::-6}".fasta"
	
	mv ~/Downloads/${FILE::-6}_frags3.200_v1_3 ${FILE::-6}
	mv ~/Downloads/${FILE::-6}_frags9.200_v1_3 ${FILE::-6}
	mv ~/Downloads/${FILE::-6}.psipred_ss2 ${FILE::-6}
	mv $FILE ${FILE::-6}
done
}

separate_monomer
FastRelax
prepare

fi
