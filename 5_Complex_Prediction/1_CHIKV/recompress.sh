#! /bin/bash

dir=$1

if [[ $# -ne 1 ]]
then
        echo "Usage ./recompress.sh <directory with zips>
        We noticed that the zip files produced by ColabFold could be extracted and compressed again to achive a smaller file size."
else

for FILE in $(ls $dir)
do
	mkdir temp
	echo $FILE
	mv output/$FILE temp/

	cd temp

	unzip $FILE 
	rm $FILE
	zip $FILE *
	mv $FILE ../output

	cd ..

	rm -r temp
done

fi
