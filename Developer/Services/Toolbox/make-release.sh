#!/bin/sh
# 
#	Copyright (C) 2011 Quentin Mathe
# 
#	Author:  Quentin Mathe <quentin.mathe@gmail.com>
#	Date:  June 2011
#	License:  MIT
#

DOC=
CODE=
WEBSITE_DIR=
ARCHIVE_BASE_NAME=
UPLOAD_DIR=
USER_NAME=

# Process script options

while test $# != 0
do
  option=
  case $1 in
    --help | -h)
      echo
      echo "`basename $0` - Script to create release archive and doc and upload them to "
      echo "the Etoile website"
      echo
      echo "Note: this script creates a directory named Products where the documentation "
      echo "and source code archive are ouput before uploading them. Once done, you have "
      echo "to manually delete this directory."
      echo
      echo "Argument:                - The path of the project to be released"
      echo
      echo "Actions:"
      echo
      echo "  --help                  - Print help"
      echo "  --doc                   - Generate and upload documentation"
      echo "                            (default: no documentation generation if omitted)"
      echo "  --code                  - Create and upload source code archive"
      echo "                            (default: no source code archive creation if omitted)"
      echo "  --upload                - Whether both documentation and source code archive" 
      echo "                            should be uploaded."
      echo "                            WARNING: Only use if you have checked the output "
      echo "                            is valid."
      echo "                            Source code archives are uploaded in the GNA "
      echo "                            download area, and documentation is committed on "
      echo "                            the website in /dev/api."
      echo "                            (default: no upload if omitted)"
      echo
      echo "Options:"
      echo "Type --option-name=value to set an option and quote the value when it contains "
      echo "spaces."
      echo
      echo "  --website-dir           - Path to a working copy of the Etoile website" 
      echo "                            (default: no documentation upload if omitted)"
      echo "  --download-dir          - Subpath to a directory in the GNA download area."
      echo "                            e.g. --download-dir=etoile-0.4.2" 
      echo "                            (default: upload into download.gna.org:/upload/etoile "
      echo "                            if omitted)"
      echo "  --templates-dir         - Path to DocGenerator Templates directory"
      echo "                            (default: none if omitted)"
      echo "  --name                  - Archive name for the source code."
      echo "                            Should include a version but no file extension. "
      echo "                            e.g. --name=etoile-foundation-0.5" 
      echo "                            (default: no source code archive creation and " 
      echo "                            upload if omitted)"

      echo "  --user-name             - The user name to upload into the GNA download area" 
      echo "                            (default: no source code upload if omitted)"
      echo
      echo
      exit 0
      ;;
    --doc)
      DOC="yes";;
    --code)
      CODE="yes";; 
    --upload)
      UPLOAD="yes";;
    --*=*)
      option=`expr "x$1" : 'x\([^=]*\)='`
      optionarg=`expr "x$1" : 'x[^=]*=\(.*\)'`
      ;;
    *)
      arg=$*
      ;;
  esac

  case $option in
    --website-dir)
      WEBSITE_DIR=$PWD/$optionarg;;
    --download-dir)
      DOWNLOAD_DIR=$optionarg;;
    --templates-dir)
      TEMPLATES_DIR=$PWD/$optionarg;;
    --name)
      ARCHIVE_BASE_NAME=$optionarg;;
    --user-name)
      USER_NAME=$optionarg;;
    *)
      ;;
  esac
  shift
done

if [ -z "$ARCHIVE_BASE_NAME" ]; then
	CODE=
fi

PROJECT_DIR=$arg
PRODUCT_DIR=$PWD/Products
PROJECT_NAME=`basename $PROJECT_DIR`
DOC_NAME=$ARCHIVE_BASE_NAME

if [ ! -d $PRODUCT_DIR ]; then
	mkdir $PRODUCT_DIR	
fi

# For debugging
#echo $PROJECT_DIR
#echo $PRODUCT_DIR/$DOC_NAME
#echo $PRODUCT_DIR/$ARCHIVE_BASE_NAME
#exit

if [ "$DOC" = "yes" ]; then
	rm -rf $PRODUCT_DIR/$DOC_NAME*
fi

if [ "$CODE" = "yes" ]; then
	rm -rf $PRODUCT_DIR/$ARCHIVE_BASE_NAME*
fi

# Build and copy project doc into the Products dir

if [ "$DOC" = "yes" ]; then
	make -C $PROJECT_DIR clean-doc doc
	cp -r $PROJECT_DIR/Documentation $PRODUCT_DIR/$DOC_NAME
fi

# Clean and copy project code into the Products dir

if [ "$CODE" = "yes" ]; then
	make -C $PROJECT_DIR clean

	cp -r $PROJECT_DIR $PRODUCT_DIR/$ARCHIVE_BASE_NAME
	cp -r $PROJECT_DIR $PRODUCT_DIR/$ARCHIVE_BASE_NAME-svn
fi

cd $PRODUCT_DIR

# Remove .svn, GSDoc dir, add doc templates, and creates archives from the product code

if [ "$CODE" = "yes" ]; then
	find $ARCHIVE_BASE_NAME -name ".svn" -exec rm -rf {} \;

	# For subprojects e.g. EtoileFoundation/EtoileXML, we check subdirs that contain a Documentation dir
	for dir in $ARCHIVE_BASE_NAME $ARCHIVE_BASE_NAME-svn $ARCHIVE_BASE_NAME/* $ARCHIVE_BASE_NAME-svn/*; do
		if [ ! -d $dir ]; then
			continue
		fi
		rm -rf $dir/Documentation/GSDoc
		rm -f $dir/images $dir/_includes
		cp -rf $TEMPLATES_DIR/images $dir
		cp -rf $TEMPLATES_DIR/_includes $dir
	done

	tar -czf $ARCHIVE_BASE_NAME.tar.gz $ARCHIVE_BASE_NAME 
	tar -czf $ARCHIVE_BASE_NAME-svn.tar.gz $ARCHIVE_BASE_NAME-svn
fi

# Upload code

if [ "$CODE" = "yes" -a -n "$UPLOAD" -a -n "$USER_NAME" ]; then
	scp $ARCHIVE_BASE_NAME.tar.gz ${USER_NAME}@download.gna.org:/upload/etoile/${DOWNLOAD_DIR}
	scp $ARCHIVE_BASE_NAME-svn.tar.gz ${USER_NAME}@download.gna.org:/upload/etoile/${DOWNLOAD_DIR}
fi

cd ..

# Upload doc (including .svn and GSDoc dir removal)

if [ "$DOC" = "yes" -a -n "$UPLOAD" -a -n "$WEBSITE_DIR" ]; then
	echo
	echo "WARNING: Documentation $DOC_NAME is only 'svn added' to the website working copy currently."
	echo "You have to make the commit explicitly."
	echo

	# For debugging
	ls $WEBSITE_DIR
	ls $WEBSITE_DIR/dev/api

	cp -rf $PROJECT_NAME/Documentation $WEBSITE_DIR/dev/api/$DOC_NAME
	ln -sf ./$DOC_NAME $WEBSITE_DIR/dev/api/$PROJECT_NAME

	find $WEBSITE_DIR/dev/api/$DOC_NAME -name ".svn" -exec rm -rf {} \;
	rm -rf $WEBSITE_DIR/dev/api/$DOC_NAME/GSDoc

	svn add $WEBSITE_DIR/dev/api/$DOC_NAME
	svn add $WEBSITE_DIR/dev/api/$PROJECT_NAME
	#svn commit $WEBSITE_DIR/dev/api/$DOC_NAME $WEBSITE_DIR/dev/api/$PROJECT_NAME
fi

# Exit Products dir
cd ..
