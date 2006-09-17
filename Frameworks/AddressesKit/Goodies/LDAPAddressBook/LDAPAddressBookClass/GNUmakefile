include $(GNUSTEP_MAKEFILES)/common.make
BUNDLE_NAME=LDAPAddressBook
BUNDLE_EXTENSION=.abclass

LDAPAddressBook_INSTALL_DIR=$(GNUSTEP_ROOT)/Local/Library/Addresses
LDAPAddressBook_OBJC_FILES=LDAPAddressBook.m utils.m
LDAPAddressBook_RESOURCE_FILES=LDAPPersonMapping.plist
LDAPAddressBook_MAIN_CLASS=LDAPAddressBook
LDAPAddressBook_OBJCFLAGS=-I../../Frameworks -Wall
LDAPAddressBook_LDFLAGS=\
	-L../../Frameworks/Addresses/Addresses.framework/Versions/A     \
	-lAddresses -lgsldap

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
