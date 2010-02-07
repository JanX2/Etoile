/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#include <AppKit/AppKit.h>

@class ModelClass;
@class ModelMethod;

@interface Controller : NSObject
{
  id categoriesList;
  id classesList;
  id methodsList;
  id content;
  id newClassNameField;
  id newCategoryNameField;
  id newPropertyNameField;
  id addClassNamePanel;
  id addCategoryNamePanel;
  id addPropertyNamePanel;
  id statusTextField;
  id classContent;
  id categoryContent;
  id methodContent;
  id infoPanel;
  id infoVersion;
  id infoAuthors;
  id historyTextField;

  id mainWindow;

  id codeTextView;
  id signatureTextField;
  id categoryDocTextView;
  id classDocTextView;
  NSView* currentView;
  BOOL doingPrettyPrint;
  BOOL newStatement;
  BOOL quotesOpened;
  NSUInteger cursorPosition;

  id historySlider;
}
- (void) updateGorm;
#ifdef COREOBJECT
- (void) updateHistory;
- (void) changeHistory: (id)sender;
- (void) setHistory: (id) sender;
#endif
- (void) generateBundle: (id) sender;
- (void) loadFile: (NSString*) path;
- (void) addCategory: (id)sender;
- (void) addClass: (id)sender;
- (void) addInstanceMethod: (id)sender;
- (void) addClassMethod: (id)sender;
- (void) addMethod: (BOOL)isInstanceMethod;
- (void) addProperty: (id)sender;
- (void) load: (id)sender;
- (void) removeCategory: (id)sender;
- (void) removeClass: (id)sender;
- (void) removeMethod: (id)sender;
- (void) removeProperty: (id)sender;
- (void) saveToFile: (id)sender;
- (void) save: (id)sender;
- (void) runClass: (id)sender;
- (void) update;
- (void) swapContentViewWith: (NSView*) aView;
- (void) showClassDetails;
- (void) showMethodDetails;
- (ModelClass*) currentClass;
- (NSMutableArray*) currentCategory;
- (ModelMethod*) currentMethod;
- (void) setTitle: (NSString*) title for: (NSTableView*) tv;
- (void) setStatus: (NSString*) text;
- (void) recreateMethodAST;
@end
