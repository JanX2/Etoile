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
  id addClassNamePanel;
  id addCategoryNamePanel;
  id statusTextField;

  NSMutableArray* classes;
}
- (void) addCategory: (id)sender;
- (void) addClass: (id)sender;
- (void) addMethod: (id)sender;
- (void) load: (id)sender;
- (void) removeCategory: (id)sender;
- (void) removeClass: (id)sender;
- (void) removeMethod: (id)sender;
- (void) save: (id)sender;
- (void) update;
- (ModelClass*) currentClass;
- (NSMutableArray*) currentCategory;
- (ModelMethod*) currentMethod;
- (void) setTitle: (NSString*) title for: (NSTableView*) tv;
- (void) setStatus: (NSString*) text;
@end
