debug=yes
include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME=AddressView

AddressView_VERSION=$(ETOILE_ADDRESSBOOK_VERSION)

AddressView_OBJC_FILES=\
			ADPersonView.m                 \
			ADImageView.m                  \
		       	ADPersonPropertyView.m         \
			ADPersonPropertyView+Private.m \
			ADPersonPropertyView+Events.m  \
			ADSinglePropertyView.m 
AddressView_HEADER_FILES=\
			AddressView.h                  \
			ADPersonView.h                 \
			ADImageView.h                  \
			ADPersonPropertyView.h         \
			ADSinglePropertyView.h 

AddressView_RESOURCE_FILES=\
			ScriptingInfo.plist              \
			UnknownImage.tiff                \
			Lock.tiff Share.tiff             \
			Add.tiff Remove.tiff Change.tiff \
			VCFImage.tiff                    \
			Labels.dict ISOCodeMapping.dict AddressLayouts.dict

AddressView_LOCALIZED_RESOURCE_FILES=Localizable.strings
AddressView_LANGUAGES=Dutch English French German Spanish

AddressView_OBJCFLAGS=-I..
AddressView_LDFLAGS=-L..

-include GNUmakefile.preamble
-include GNUmakefile.local
# NOTE: Include etoile.make include before framework.make otherwise the 
# compilation may fail if you type 'make; make' (see bug #8806).
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make
-include GNUmakefile.postamble

