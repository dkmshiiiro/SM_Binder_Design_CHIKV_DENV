import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import sys
import os
from matplotlib.ticker import AutoMinorLocator
import colorcet as cc

def read_pdb_file(filename):
    
    "Coordinates of the C-alpha atoms of chain A, B, C and D"
    with open(filename, 'r') as f:
        lines = f.readlines()

    coordinates_A = []
    coordinates_B = []
    residue_nums_A = []
    residue_nums_B = []
    for line in lines:
        if line.startswith('ATOM') and line[12:16].strip() == 'CA':
            chain_id = line[21]
            residue_num = int(line[22:26])
            x = float(line[30:38])
            y = float(line[38:46])
            z = float(line[46:54])
            if chain_id == 'A':
                coordinates_A.append([x, y, z])
                residue_nums_A.append(residue_num)
                #Target chains, add more of these of your receptor have more than 3 chains
            elif chain_id == 'B':
                coordinates_B.append([x, y, z])
                residue_nums_B.append(residue_num)
            elif chain_id == 'C':
                coordinates_B.append([x, y, z])
                residue_nums_B.append(residue_num)
            elif chain_id == 'D':
                coordinates_B.append([x, y, z])
                residue_nums_B.append(residue_num)

    return np.array(coordinates_A), np.array(coordinates_B), residue_nums_A, residue_nums_B

def calculate_residue_pairs(coordinates_A, coordinates_B, residue_nums_A, residue_nums_B, cutoff):
    
    "Calculate the residue pairs between chain A and B, C and D within the cutoff distance"
    residue_pairs = []
    for i in range(len(coordinates_A)):
        for j in range(len(coordinates_B)):
            distance = np.linalg.norm(coordinates_A[i] - coordinates_B[j])
            if distance < cutoff:
                pair = (residue_nums_A[i], residue_nums_B[j], distance)
                residue_pairs.append(pair)

    return residue_pairs

def calculate_deviation(pdb_list, residue_pairs):
    
    "C-alpha distance deviation relative to the original residue pair distance, for each residue pair"
    deviation_lists = []
    for pdb_file in pdb_list:
        coordinates_A, coordinates_B, residue_nums_A, residue_nums_B = read_pdb_file(pdb_file)
        deviation_list = []
        for pair in residue_pairs:
            residue_A = pair[0]
            residue_B = pair[1]
            original_distance = pair[2]
            coord_A_found = False
            coord_B_found = False
            for i in range(len(coordinates_A)):
                if residue_A == residue_nums_A[i]:
                    coord_A = coordinates_A[i]
                    coord_A_found = True
                    break
            for j in range(len(coordinates_B)):
                if residue_B == residue_nums_B[j]:
                    coord_B = coordinates_B[j]
                    coord_B_found = True
                    break
            if coord_A_found and coord_B_found:
                distance = np.linalg.norm(coord_A - coord_B)
                deviation = distance - original_distance
                deviation_list.append(abs(deviation))
        deviation_lists.append(deviation_list)	    
    return deviation_lists

def plot_deviation_matrix(deviation_lists, residue_pairs):
    # Create a matrix of the deviation lists
    deviation_matrix = np.array(deviation_lists).T
    mpl.rc('font',family='Arvo')
    # Create a list of residue pairs labels
    labels = []
    for pair in residue_pairs:
        label = str(pair[0]) + "-" + str(pair[1])
        labels.append(label)
    #plt.style.use("dark_background")
    # Create the plot
    fig, ax = plt.subplots(figsize=(7,8))

    im = ax.imshow(deviation_matrix, cmap="viridis", aspect='auto', vmax=8) #cc.cm.bmw
		#viridis
    # Set the axis labels
    #ax.set_xticks([1, len(deviation_lists)//5 , 2*(len(deviation_lists)//5), 3*(len(deviation_lists)//5), 4*(len(deviation_lists)//5), len(deviation_lists)-1])
    #ax.set_xticklabels(['0', '100', '200', '300', '400', '500'], fontdict={'fontsize': 20})
    
    ax.set_xticks([1, len(deviation_lists)//2, len(deviation_lists)-1])
    ax.set_xticklabels(['0', '1000', '2000'], fontdict={'fontsize': 25})    
    
    ax.xaxis.set_minor_locator(AutoMinorLocator(2))
    
    ax.set_xlabel("Time (ns)", fontsize=30)

    ax.set_yticks(range(len(residue_pairs)))
    ax.set_yticklabels(labels, fontdict={'fontsize': 11})
    ax.set_ylabel("Interaction Residue Pairs", fontsize=30)

#    ax.set_yticks(range(len(residue_pairs)))
#    ax.set_yticklabels(range(1, len(residue_pairs) + 1), fontdict={'fontsize': 5})
#    ax.set_ylabel("Interaction pairs")

    # Set the colorbar
    cbar = ax.figure.colorbar(im, ax=ax,  ticks=[0, 2, 4, 6, 8])
    cbar.ax.set_ylabel("C-alpha Distance Deviation (\u00c5)", rotation=-90, va="bottom", fontsize=30)
    #C-\u03B1 is C-alpha
    cbar.ax.set_yticklabels(['0', '2', '4', '6','>=8'], fontdict={'fontsize': 25})
    cbar.outline.set_linewidth(1.5)
    cbar.ax.tick_params(axis='y', which='major', length=10, width=2) 
    # Rotate the x-axis labels
    plt.setp(ax.get_xticklabels(), ha="center")
    ax.tick_params(axis='x', which='major', length=12, width=2)
    ax.tick_params(axis='x', which='minor', length=8, width=2)
    ax.tick_params(axis='y', which='both', length=8, width=2)
    ax.spines['bottom'].set_linewidth(2)
    ax.spines['top'].set_linewidth(2)
    ax.spines['left'].set_linewidth(2)
    ax.spines['right'].set_linewidth(2)
    # Add a title
    #ax.set_title("Deviation Matrix")

    # Show the plot
    plt.tight_layout()
    plt.savefig('CA_contact.svg', dpi=600)
    plt.show()


# Get input from command line
if len(sys.argv) < 3:
    print("Usage: python3 deviation_time.py <Reference_complex.pdb> <Frame_1.pdb> <Frame_2.pdb> ...")
    print("You can use [frames/Frame_*] for example to input all frames, but they will not be in order, so you can use something like this [$(ls frames/frame_* | sort -n -k 2 -t _)]")
    sys.exit()
pdb_list = sys.argv[1:]
cutoff = 8.0 

# Call functions to get residue pairs and print them
coordinates_A, coordinates_B, residue_nums_A, residue_nums_B = read_pdb_file(pdb_list[0])
residue_pairs = calculate_residue_pairs(coordinates_A, coordinates_B, residue_nums_A, residue_nums_B, cutoff)
deviation_lists = calculate_deviation(pdb_list, residue_pairs)
print("Number of contacts")
print(range(len(residue_pairs)))
#plot
plot_deviation_matrix(deviation_lists, residue_pairs)

print("REMEMBER TO RENAME YOUR .PNG SO YOU KNOW THE BINDER")



