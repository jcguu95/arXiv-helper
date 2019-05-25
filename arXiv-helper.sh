#!/bin/bash

## INPUTFILE must be in the example form:
## "1808.01059.pdf"		# I call it type A.
## "math---0503727.pdf"		# I call it type B.
## "q-alg---9503006.pdf"	# I call it type B.

## Usage: Simply put all files from arXiv in a folder, make sure
## 	  the name of the files are correct (as above), and run
## 	  for example:
## 	  	$ arXiv-helper 1808.01059.pdf
##  	  or for doing it in patch:
## 	  	$ for i in *.pdf; do arXiv-helper "$i"; done

## TODO
## 1.   I feel it is better to identify the file itself
##    by looking at its arXiv-id in the metadata, rather
##    than at its file name. Perhaps I will make a change.
## 2.   Before '1.' gets done, notice that the current script
##    has a drawback that it does not distinguish TYPE "A" files
##    and TYPE "neither" files quite well..
## 3.   Though it is quite important, the current script
##    does not pull the version info down! This will be updated
##    in the future.
## 4.   Am I sure that I want to change spaces to '-'?
## 5.   Write an arXiv downloader: only thing to do is to
##    input arXiv id!


INPUT_FILE=$1
ARXIV_ID=$(echo $INPUT_FILE | sed 's/\.pdf//')


# Determine which type is the arXiv-id
case $ARXIV_ID in
	*"."*) TYPE="A" ;;
	*"---"*) TYPE="B" ;;
	*) TYPE="neither" ;;
esac


# Download the metadata online (export.arxiv.org/...) with respect to TYPE (A, B, or neither)
case $TYPE in # require internet connection
	"A")
		echo "It is of type A."
		ACTUAL_ARXIV_ID=$ARXIV_ID
		wget -O "tmp.$ARXIV_ID.xml" "http://export.arxiv.org/oai2?verb=GetRecord&metadataPrefix=arXivRaw&identifier=oai:arXiv.org:$ACTUAL_ARXIV_ID"
		;;

	"B")
		echo "It is of type B"
		ARXIV_ID_TYPE_B1=$(echo $ARXIV_ID | sed 's/---.*//' )
		ARXIV_ID_TYPE_B2=$(echo $ARXIV_ID | sed 's/.*---//' )
		ACTUAL_ARXIV_ID="$ARXIV_ID_TYPE_B1/$ARXIV_ID_TYPE_B2"
		echo "Type b: B1=$ARXIV_ID_TYPE_B1 ; B2=$ARXIV_ID_TYPE_B2 "
		wget -O "tmp.$ARXIV_ID.xml" "http://export.arxiv.org/oai2?verb=GetRecord&metadataPrefix=arXivRaw&identifier=oai:arXiv.org:$ACTUAL_ARXIV_ID"
		;;

	"neither")
		echo "ERROR: File name is neither of type A nor B.. exit 1!" ;
		exit 1 ;;
esac


# Input data from the downloaded metafiles.
META_CONTENT=$(echo $(<tmp.$ARXIV_ID.xml) | sed 's/\n//g')

TITLE=$(echo $META_CONTENT | sed 's/.*<title>//' | sed 's/<\/title>.*//')
AUTHORS=$(echo $META_CONTENT | sed 's/.*<authors>//' | sed 's/<\/authors>.*//')
CATEGORIES="arXiv: $(echo $META_CONTENT | sed 's/.*<categories>//' | sed 's/<\/categories>.*//')"
ABSTRACT=$(echo $META_CONTENT | sed 's/.*<abstract>//' | sed 's/<\/abstract>.*//')

### Check if d.o.i exists
case $META_CONTENT in
	*"<doi>"*"</doi>"*)
		DOI_EXIST="true"
		DOI=$(echo $META_CONTENT | sed 's/.*<doi>//' | sed 's/<\/doi>.*//') ;;
	*)
		DOI_EXIST="false"
		DOI="unknown" ;;
esac

echo "ARXIV_ID = $ARXIV_ID"
echo "ACTUAL_ARXIV_ID = $ACTUAL_ARXIV_ID" # Differ from ARXIV_ID if it is of type B.
echo "TITLE = $TITLE"
echo "AUTHORS = $AUTHORS"
echo "CATEGORIES = $CATEGORIES"
echo "ABSTRACT = $ABSTRACT"
echo "DOI_EXIST = $DOI_EXIST"
echo "DOI = $DOI"

# Change metadata of our .pdf files with 'exiftool'.
exiftool $INPUT_FILE -title="$TITLE" -author="$AUTHORS" -categories="$CATEGORIES" -doi="$DOI" -description="arXiv-id: $ACTUAL_ARXIV_ID. Abstract: $ABSTRACT"


# Rename the file
### For the authors part
### special characters (currently '(' and ')') and spaces are transformed into '-'
### ', ' and ',' are transformed into '_'.
### AUTHORS=$(echo "$AUTHORS" | sed 's/, /_/g' | sed 's/,/_/g' | sed 's/ /-/g' | sed 's/(/-/g' | sed 's/)/-/g')
### For the title part
### special characters (currently '(' and ')') and spaces are transformed into '-'
### ', ' and ',' are transformed into ''.
### TITLE=$(echo "$TITLE" | sed 's/ /-/g' | sed 's/(/-/g' | sed 's/)/-/g' | sed 's/,//g')
AUTHORS=$(echo "$AUTHORS" | sed 's/ /-/g')
TITLE=$(echo "$TITLE" | sed 's/ /-/g' )
## Finally, we got the new name.
NEW_FILE_NAME=$(echo "[$AUTHORS]-$TITLE---[arXiv-id-$ARXIV_ID].pdf")
echo "new file name = $NEW_FILE_NAME"
## Renaming the files.
cp "$INPUT_FILE" "$NEW_FILE_NAME"
mv "$INPUT_FILE""_original" "$INPUT_FILE"
# Removing the temporary files.
rm -rf tmp.$ARXIV_ID.xml

exit
