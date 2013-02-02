/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>


@interface DocumentEditorController : ETDocumentController
{
	ETLayoutItemGroup *mainItem;
}

@end

@interface ETUIBuilderDemoController : ETController
- (IBAction)increment: (id)sender;
@end