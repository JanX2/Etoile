
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = VCFViewer
BUNDLE_EXTENSION = .inspector
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_DIR)/Library/GWorkspace

# hack -- GWorkspace won't find bundles if they weren't installed in
#   ~/GNUstep/Library/GWorkspace 
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_DIR)

VCFViewer_HAS_RESOURCE_BUNDLE = yes

VCFViewer_OBJCFLAGS += -Wall
VCFViewer_LDFLAGS += -lGWorkspace -lAddresses -lAddressView

VCFViewer_OBJC_FILES = VCFViewer.m 
VCFViewer_PRINCIPAL_CLASS = VCFViewer
VCFViewer_RESOURCE_FILES = InspectorInfo.plist VCFImage.tiff

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

after-install::
	@echo -en "\007"
	@echo "***"
	@echo "***"
	@echo "*** WARNING: Due to a GWorkspace limitation, VCFViewer.inspector"
	@echo "***          currently MUST be installed at ~/GNUstep/Library/GWorkspace"
	@echo "***          (in your case, $(BUNDLE_INSTALL_DIR))."
	@echo "***          Your settings for GNUSTEP_INSTALLATION_DIR (if any)"
	@echo "***          have been overridden."
	@echo "***"
	@echo "***"
	@echo -en "\007"
