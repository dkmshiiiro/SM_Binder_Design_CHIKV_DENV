#! /bin/bash

#activate enviroment
#eval "$(conda shell.bash hook)"
#conda activate mlfold

#variables
pdb_full=$1
cores=$2
n_cycles=$3

if [[ $# -ne 3 ]]
then
	echo "Usage ./design_acid <directory with pdbs> <n_cores> <n_cycles>"
else

#functions
function FastRelax {
	for FILE in $(ls $j"_temp"/*.pdb)
	do
	seq=$(tail -n 1 ${FILE::-4}".fa")
	echo "Designed sequence:"$seq
	echo "Running FastRelax..."
	/scratch/imeb/softwares/app/rosetta/3.13/main/source/bin/rosetta_scripts.default.linuxgccrelease -parser:protocol relax.xml -s $FILE -beta_nov16 -parser:script_vars seq=$seq -out:no_nstruct_label -extra_res_fa HIS_P.params -out:path:pdb pdb_2 -out:path:score . -out:level 100  
        done
}

cp -r $pdb_full pdb_1

for x in `seq 1 $n_cycles`
do 
	mkdir pdb_2

	#pdb to json
	python /scratch/imeb/softwares/app/ProteinMPNN/helper_scripts/parse_multiple_chains.py --input_path=pdb_1 --output_path="parsed.jsonl"

	#chains to design
	python /scratch/imeb/softwares/app/ProteinMPNN/helper_scripts/assign_fixed_chains.py --input_path="parsed.jsonl" --output_path="chains.jsonl" --chain_list "A"

	#run ProteinMPNN (no histidine)
	python /scratch/imeb/softwares/app/ProteinMPNN/protein_mpnn_run.py --jsonl_path "parsed.jsonl" --chain_id_jsonl "chains.jsonl" --out_folder "." --num_seq_per_target 1 --sampling_temp "0.1" --seed 0 --omit_AAs "CH" --batch_size 1 --bias_AA_json "bias.jsonl" --model_name "v_48_030" 

	#Rename HIS for HIP 
	for FILE in $(ls pdb_1/*)
	do
		python pdb_rplresname.py -HIS:HIP $FILE > ${FILE::-4}"_temp.pdb"
		mv ${FILE::-4}"_temp.pdb" $FILE
	done

	#divide the designs into directories to parallelize the across multiple cores

	num_files=$(ls pdb_1 | wc -l)
	div=$(($num_files/$cores))
	max_files_per_dir=$((div + 1))

	for i in `seq 1 $cores`
	do
		mkdir $i"_temp"
		for FILE in $(ls pdb_1 | head -n $max_files_per_dir)
		do
			mv pdb_1/$FILE $i"_temp" 
			mv seqs/${FILE::-4}.fa $i"_temp" 
		done
	done

	#run FastRelax

	for j in `seq 1 $cores`
	do
		FastRelax &
	done
	wait

	#clean
	rm -r pdb_1 seqs 
	rm -r *_temp
	rm parsed.jsonl chains.jsonl score.sc
	
	#rename HIP for HIS 
	for FILE in $(ls pdb_2/*)
	do
		python pdb_rplresname.py -HIP:HIS $FILE > ${FILE::-4}"_temp.pdb"
		mv ${FILE::-4}"_temp.pdb" $FILE
	done
	
	mv pdb_2 pdb_1
done

mv pdb_1 pdb_ok
fi
