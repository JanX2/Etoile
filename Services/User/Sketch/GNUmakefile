include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Sketch

Sketch_OBJC_FILES = \
	Sketch_main.m \
	SKTFoundationExtras.m \
	SKTGridView.m \
	SKTDrawAppDelegate.m \
	SKTGraphicView.m \
	SKTInspectorController.m \
	SKTDrawWindowController.m \
	SKTGridPanelController.m \
	SKTToolPaletteController.m \
	SKTCircle.m \
	SKTGraphic.m \
	SKTLine.m \
	SKTRenderingView.m \
	SKTDrawDocument.m \
	SKTImage.m \
	SKTRectangle.m \
	SKTTextArea.m

Sketch_LANGUAGES = English

ifeq ($(FOUNDATION_LIB), apple)
Sketch_LOCALIZED_RESOURCE_FILES = \
	Draw2.nib \
	DrawWindow.nib \
	GridPanel.nib \
	Inspector.nib \
	ToolPalette.nib

Sketch_MAIN_MODEL_FILE = Draw2.nib
else
Sketch_LOCALIZED_RESOURCE_FILES = \
	GridPanel.nib \
	Inspector.nib \
	ToolPalette.nib \
	DrawWindow.gorm \
	Draw2.nib 
Sketch_MAIN_MODEL_FILE = Draw2.nib
endif
Sketch_RESOURCE_FILES = \
	Arrow.tiff \
	Curve.tiff \
	Line.tiff \
	Rectangle.tiff \
	Circle.tiff \
	Draw2App.tiff \
	Pencil.tiff \
	Scribble.tiff \
	Cross.tiff \
	Draw2File.tiff \
	Polygon.tiff \
	TextGraphic.tiff

include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
