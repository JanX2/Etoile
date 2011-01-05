/**
	<abstract>A DocPageWeaver decorator which can be used to reorder 
	GSDoc symbols declarations, in order to match the source header.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocPageWeaver.h"

/** @group GSDoc Parsing */
@interface DeclarationReorderer : NSObject <CodeDocWeaving>
{
	@private
	id <CodeDocWeaving> weaver;
	NSDictionary *orderedSymbols;
	/* The accumulated doc elements by nesting level.
	   Four key kinds are possible:
	   - "root"
	   - class symbol (a key per class)
	   - protocol symbol (a key per protocol)
	   - category symbol (a key per category) 
	   Each key is bound to a doc element array. 
	   Root can contain DocFunction, DocMacro and DocCDataType.
	   Other key kinds can contains DocMethod elements only. */
	NSMutableDictionary *accumulatedDocElements;
	NSString *currentConstructName;
}

- (id) initWithWeaver: (id <CodeDocWeaving>)aWeaver 
       orderedSymbols: (NSDictionary *)symbolArraysByKind;

@end

