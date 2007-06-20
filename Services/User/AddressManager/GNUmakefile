include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=AddressManager
AddressManager_APPLICATION_ICON=AddressManager.tiff
AddressManager_OBJC_FILES=\
			Controller.m \
			DragDropMatrix.m \
			main.m
AddressManager_HEADER_FILES=\
			Controller.h \
			DragDropMatrix.h
AddressManager_MAIN_MODEL_FILE=AddressManager.gorm

AddressManager_RESOURCE_FILES=                           \
			AddressManager.tiff              \
			VCFImage.tiff VCFImageMulti.tiff \
			VCFFile.tiff                     \
			AddressManagerInfo.plist
AddressManager_LOCALIZED_RESOURCE_FILES=\
			AddressManager.gorm \
			Localizable.strings \
			ISOCountryCodes.dict
AddressManager_LANGUAGES=Dutch English French German Spanish
#AddressManager_OBJCFLAGS=-I../Frameworks -Wall
AddressManager_LDFLAGS=\
	-L$(GNUSTEP_LOCAL_ROOT)/AddressView.framework/Versions/A \
	-L$(GNUSTEP_LOCAL_ROOT)/Addresses.framework/Versions/A     \
	-lAddressView -lAddresses

-include GNUmakefile.preamble
-include GNUmakefile.local
-include ../../../etoile.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

