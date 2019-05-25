#!/bin/bash

## InputFile must be in the example form:
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
##    has a drawback that it does not distinguish Type "A" files
##    and Type "neither" files quite well..
## 3.   Though it is quite important, the current script
##    does not pull the version info down! This will be updated
##    in the future.
## 4.   Write an arXiv downloader: only thing to do is to
##    input arXiv id!
## 5.   Add description: dependencies-- exiftool and wget.

InputFile=$1
Identifier=$(exiftool $1 -identifier | sed 's/Identifier *: //')

case $Identifier in # TODO: the regex is not good. fix it!
	"arXiv:"*"/"*)
		IdentifierType="Prior2007" ;;
	"arXiv:"*"."*)
		IdentifierType="After2007" ;;
	*)
		echo "ERROR: Not an arXiv identifier.. exit 1."
		exit 1 ;;
esac

ArXivIdentifierWithoutBackSlash=$(echo "$Identifier" | sed 's/\//---/' ) # Change '\' to '---' in those of Type-Prior2007.
ArXivIdentifierWithoutVersion=$(echo "$Identifier" | sed 's/arXiv://' | sed 's/v[0-9]*//' ) # TODO: check if this regex is correct
ArXivMetaDataSiteURL="http://export.arxiv.org/oai2?verb=GetRecord&metadataPrefix=arXivRaw&identifier=oai:arXiv.org:$ArXivIdentifierWithoutVersion"
TempMetaDataFileName="tmp.$ArXivIdentifierWithoutBackSlash.xml"
wget -O "$TempMetaDataFileName" "$ArXivMetaDataSiteURL" # Fetch metadata from the URL and output as an .xml file.
MetaContent=$(echo $(<"$TempMetaDataFileName") | sed 's/\n//g') # The newlines are cut-off.

#	ArXivID=$(echo $InputFile | sed 's/\.pdf//')
#
#	#
#	# Determine which type is the arXiv-id
#	case $ArXivID in
	#	*"."*) Type="A" ;;
	#	*"---"*) Type="B" ;;
	#	*) Type="neither" ;;
#	esac
#
#
#	# Download the metadata online (export.arxiv.org/...) with respect to Type (A, B, or neither)
#	case $Type in # require internet connection
	#	"A")
		#	echo "It is of type A."
		#	ActualAxXivID=$ArXivID
		#	wget -O "tmp.$ArXivID.xml" "http://export.arxiv.org/oai2?verb=GetRecord&metadataPrefix=arXivRaw&identifier=oai:arXiv.org:$ActualAxXivID"
		#	;;
#
	#	"B")
		#	echo "It is of type B"
		#	ArXivIDTypeB1=$(echo $ArXivID | sed 's/---.*//' )
		#	ArXivIDTypeB2=$(echo $ArXivID | sed 's/.*---//' )
		#	ActualAxXivID="$ArXivIDTypeB1/$ArXivIDTypeB2"
		#	echo "Type b: B1=$ArXivIDTypeB1 ; B2=$ArXivIDTypeB2 "
		#	wget -O "tmp.$ArXivID.xml" "http://export.arxiv.org/oai2?verb=GetRecord&metadataPrefix=arXivRaw&identifier=oai:arXiv.org:$ActualAxXivID"
		#	;;
#
	#	"neither")
		#	echo "ERROR: File name is neither of type A nor B.. exit 1!" ;
		#	exit 1 ;;
#	esac
#
#
#	# Input data from the downloaded metafiles.
#	MetaContent=$(echo $(<tmp.$ArXivID.xml) | sed 's/\n//g')

Title=$(echo $MetaContent | sed 's/.*<title>//' | sed 's/<\/title>.*//')
Authors=$(echo $MetaContent | sed 's/.*<authors>//' | sed 's/<\/authors>.*//')
Categories="arXiv: $(echo $MetaContent | sed 's/.*<categories>//' | sed 's/<\/categories>.*//')"
Abstract=$(echo $MetaContent | sed 's/.*<abstract>//' | sed 's/<\/abstract>.*//')

### Check if d.o.i exists
case $MetaContent in
	*"<doi>"*"</doi>"*)
		DoiExist="true"
		Doi=$(echo $MetaContent | sed 's/.*<doi>//' | sed 's/<\/doi>.*//') ;;
	*)
		DoiExist="false"
		Doi="unknown" ;;
esac

echo "ArXivID = $ArXivID"
echo "ActualAxXivID = $ActualAxXivID" # Differ from ARXIV_ID if it is of type B.
echo "Title= $Title"
echo "Authors = $Authors"
echo "Categories = $Categories"
echo "Abstract = $Abstract"
echo "DoiExist = $DoiExist"
echo "Doi = $Doi"

# Change metadata of our .pdf files with 'exiftool'.
exiftool $InputFile -title="$Title" -author="$Authors" -categories="$Categories" -doi="$Doi" -description="arXiv-id: $ActualAxXivID. Abstract: $Abstract"


# Rename the file
NewFileName=$(echo "[$Authors]-$Title---[arXiv-id-$ArXivID].pdf")
echo "new file name = $NewFileName"
## Renaming the files.
cp "$InputFile" "$NewFileName"
mv "$InputFile""_original" "$InputFile"
# Removing the temporary files.
rm -rf tmp.$ArXivID.xml

exit
