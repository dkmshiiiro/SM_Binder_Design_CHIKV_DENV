#! /bin/bash

i=1

#variables
silent_file=$1
req_file=$2

#filter
if [[ $# -ne 2 ]]
then
	echo "Usage ./filter_designs <silent file> <req file>
	req_file format:
	
	req net_charge value > -16	
	output sortmin dG_separated"
else

grep SCORE $silent_file > score.sc

	./DesignSelect.pl -d score.sc -c $req_file > score_filtered.sc

#renumber pdbs
	cat score_filtered.sc | awk '{print i++"_"$NF}' > pdbs.rank

#get pdbs from silent
	tags=$(cat score_filtered.sc | awk '{print $NF}' | xargs) 
	mkdir pdb_filtered
	extract_pdbs.mpi.linuxgccrelease -in:file:tags $tags -in:file:silent $silent_file -out:level 100
	mv *.pdb pdb_filtered
	
#rename pdbs
for LINE in $(cat pdbs.rank)
do	
	#echo $i
	#echo ${LINE: -16}
	mv pdb_filtered/"${LINE: -16}"".pdb" pdb_filtered/$i"_"${LINE: -16}".pdb"  

	i=$[$i + 1]
	
done
fi
