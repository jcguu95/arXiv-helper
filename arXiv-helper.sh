#!/bin/bash

## Dependencies: internet connection, exiftool, wget

## Input file must have identifier in the form:
##	 arXiv:[archive].[subject-class]/YYMM[number]{vV}
## 	 arXiv:YYMM.number{vV}
## For example 	arXiv:math.GT/0309136	or
##		arXiv:1501.00001	or
##		arXiv:0706.0001v2	.
## For more information about arXiv identifier, please refer to the official site:
## 	Understanding the arXiv identifier (https://arxiv.org/help/arxiv_identifier)
## To check the identifier of the file, enter the command
## 	$ exiftool TheFileName.pdf -Identifier

## TODO
## 1.   Though it is quite important, the current script
##    does not pull the version info down! This will be updated
##    in the future.
## 2.   Write an arXiv downloader: only thing to do is to
##    input arXiv id!

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

ArXivIdentifierAvoidingBackSlash=$(echo "$Identifier" | sed 's/\//--/' ) # Change '\' to '--' in those of Type-Prior2007.
ArXivIdentifierWithoutVersion=$(echo "$Identifier" | sed 's/arXiv://' | sed 's/v[0-9]*//' ) # TODO: check if this regex is correct
ArXivMetaDataSiteURL="http://export.arxiv.org/oai2?verb=GetRecord&metadataPrefix=arXivRaw&identifier=oai:arXiv.org:$ArXivIdentifierWithoutVersion"
TempMetaDataFileName="tmp.$ArXivIdentifierAvoidingBackSlash.xml"
wget -O "$TempMetaDataFileName" "$ArXivMetaDataSiteURL" # Fetch metadata from the URL and output as an .xml file.
MetaContent=$(echo $(<"$TempMetaDataFileName") | sed 's/\n//g') # The newlines are cut-off.

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
echo "ArXivIdentifier = $Identifier"
echo "Title= $Title"
echo "Authors = $Authors"
echo "Categories = $Categories"
echo "Abstract = $Abstract"
echo "DoiExist = $DoiExist"
echo "Doi = $Doi"

# Change metadata of our .pdf files with 'exiftool'.
exiftool $InputFile -title="$Title" -author="$Authors" -categories="$Categories" -doi="$Doi" -description="[$Identifier] [Abstract] $Abstract"


# Rename the file
NewFileName=$(echo "[$Authors]-$Title-[$ArXivIdentifierAvoidingBackSlash].pdf")
echo "new file name = $NewFileName"
cp "$InputFile" "$NewFileName" # Renaming the files.
mv "$InputFile""_original" "$InputFile"
# Removing the temporary files.
rm -rf $TempMetaDataFileName

exit
