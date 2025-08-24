#! /bin/bash

#variables
csv_filtered=$1

if [[ $# -ne 1 ]]
then
        echo "Usage ./prepare_input_colab.sh <filtered_AFcomplexes.csv>"
else

echo "id,sequence" > input.csv

tail -n +2 $csv_filtered | awk -F ',' '{print $1"_m,"$NF}' >> input.csv

fi
