#! /bin/bash

SCAFFOLD_DIR=$1
TARGET=$2
TARGET_RES=$3
RMSD=$4
OUTPUT=$5

if [[ $# -ne 5 ]]
then
	echo "Usage ./patchdock_run <scaffolds_directory/> <target.pdb> <target_res_file> <rmsd> <output_directory/>
	Directories must have the / in the end. RMSD is usually 3"
else

for FILE in $(ls $SCAFFOLD_DIR)
do
	echo $FILE
	buildParams.pl $TARGET "$SCAFFOLD_DIR""$FILE" $RMSD
	sed -i "8s/.*/receptorActiveSite "$TARGET_RES"/" params.txt
	patch_dock.Linux params.txt "$OUTPUT""${FILE::-4}"".out"
done
fi
