#! /bin/bash

#variables
ref=$1
traj=$2

function extract_frames {
#I'm using GROMACS 2022.6
source /usr/local/gromacs/bin/GMXRC

#Extract reference complex (C-alpha)
echo "3" > temp.sh
gmx trjconv -f $ref -s em.tpr -o ${ref::-4}.pdb < temp.sh


#Extract all frames from simulation (only C-alpha)
mkdir frames
gmx trjconv -f $traj -s md.tpr -o frames/frame_.pdb -sep < temp.sh

rm temp.sh
}

if [[ $# -ne 2 ]]
then
	echo "Usage ./deviation_time.sh <reference.gro (em.gro usually)> <trajectory.xtc>
	
	This will extract ALL FRAMES from simulation, I'm using ~5000 frames/500 ns
	Careful with the disk space
	
	deviation_time.py must be in the directory"
else

#Extract_frames
extract_frames

#Analyse contacts
python3 deviation_time_full.py ${ref::-4}.pdb $(ls frames/frame_* | sort -n -k 2 -t _)

fi
