
include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = InspectorKit
InspectorKit_OBJC_FILES = \
	AttributesPane.m \
	OSDateView.m \
	Inspector.m \
	PermissionsView.m

InspectorKit_HEADER_FILES = \
	AttributesPane.h \
	OSDateView.h \
	Inspector.h \
	PermissionsView.h

InspectorKit_RESOURCE_FILES = \
	$(wildcard Images/*)

#InspectorKit_LOCALIZED_RESOURCE_FILES = \
	AttributesInspector.gorm \
	NoContentsInspector.gorm \
	Inspector.gorm \
	PermissionsInspector.gorm \
	MultipleSelectionInspectorView.gorm \
	ToolsInspector.gorm

#InspectorKit_LANGUAGES = English
InspectorKit_LIBRARIES_DEPEND_UPON = -lIconKit -lPaneKit

include $(GNUSTEP_MAKEFILES)/framework.make

-include ../../../../etoile.make

