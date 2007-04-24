
include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = InspectorKit

InspectorKit_SUBPROJECTS += Source

#InspectorKit_OBJC_FILES = \
#	FilePopUpPresentation.m \
#	ToolsPane.m \
#	AttributesPane.m \
#	OSDateView.m \
#	Inspector.m \
#	PermissionsView.m

InspectorKit_HEADER_FILES_DIR = Headers
InspectorKit_HEADER_FILES = \
	FilePopUpPresentation.h \
	ToolsPane.h \
	AttributesPane.h \
	OSDateView.h \
	Inspector.h \
	PermissionsView.h \
	InspectorKit.h 

InspectorKit_RESOURCE_FILES = \
	$(wildcard Images/*)

#InspectorKit_LOCALIZED_RESOURCE_FILES = \
	NoContentsInspector.gorm \
	PermissionsInspector.gorm \
	MultipleSelectionInspectorView.gorm \
	ToolsInspector.gorm

#InspectorKit_LANGUAGES = English
InspectorKit_LIBRARIES_DEPEND_UPON = -lIconKit -lPaneKit

include $(GNUSTEP_MAKEFILES)/framework.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include ../../etoile.make

