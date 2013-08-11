/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocDeclarationReorderer.h"
#import "DocHeader.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "DocTOCPage.h"
#import "DocPage.h"

static NSString *root = @"root";

@implementation DocDeclarationReorderer

- (id) initWithWeaver: (id <DocWeaving>)aWeaver
       orderedSymbols: (NSDictionary *)symbolArraysByKind
{
	NILARG_EXCEPTION_TEST(aWeaver);
	NILARG_EXCEPTION_TEST(symbolArraysByKind);

	SUPERINIT;
	weaver = aWeaver;
	orderedSymbols = symbolArraysByKind;
	accumulatedDocElements =
		[[NSMutableDictionary alloc] initWithObjectsAndKeys: [NSMutableArray array], root, nil];
	currentConstructName = root;
	return self;
}

- (void) dealloc
{
	weaver = nil;
	orderedSymbols = nil;
	accumulatedDocElements = nil;
}

// FIXME: Forwarding seems to be broken with -performSelector:withObject:

- (id) forwardingTargetForSelector: (SEL)aSelector
{
	return weaver;
}

- (void) forwardInvocation: (NSInvocation *)anInv
{
	[anInv invokeWithTarget: weaver];
}

- (NSArray *) orderedSymbolsWithinConstructNamed: (NSString *)aConstructName
{
	return [orderedSymbols objectForKey: aConstructName];
}

- (void) weaveAccumulatedDocElementsForConstructNamed: (NSString *)aConstructName
{
	NSArray *docElements = [accumulatedDocElements objectForKey: aConstructName];
	NSArray *docElementSymbols = [docElements valueForKey: @"refMarkup"];
	NSString *currentTaskUnit = nil;

	ETAssert([docElements count] == [[self orderedSymbolsWithinConstructNamed: aConstructName] count]);

	for (NSString *symbol in [self orderedSymbolsWithinConstructNamed: aConstructName])
	{
		NSInteger symbolIndex = [docElementSymbols indexOfObject: symbol];
		if (NSNotFound == symbolIndex)
		{
			continue;
			//FIXME: Do some sane thing if the symbol wasn't found.
		}
		DocMethod *docElement = [docElements objectAtIndex: symbolIndex];
		BOOL hasDefaultTask = [[docElement task] isEqualToString: [[docElement class] defaultTask]];

		currentTaskUnit = ([docElement taskUnit] != nil ? [docElement taskUnit] : currentTaskUnit);

		if (currentTaskUnit != nil && hasDefaultTask)
		{
			[docElement setTask: currentTaskUnit];
		}
		[weaver weaveMethod: docElement];
	}
}

- (void) resetAccumulatedDocElements
{
	accumulatedDocElements = [NSMutableDictionary dictionaryWithObject:
                                    [accumulatedDocElements objectForKey: root] forKey: root];
}

- (void) flushAccumulatedDocElementsForConstructNamed: (NSString *)aName
{
	if (currentConstructName == nil)
		return;

	[self weaveAccumulatedDocElementsForConstructNamed: aName];
	[self resetAccumulatedDocElements];
}

- (void) accumulateDocElement: (DocElement *)anElement
{
	NSMutableArray *elements = [accumulatedDocElements objectForKey: currentConstructName];
	if (elements == nil)
	{
		elements = [NSMutableArray array];
		[accumulatedDocElements setObject: elements forKey: currentConstructName];
	}
	[elements addObject: anElement];
}

- (void) weaveHeader: (DocHeader *)aHeader
{
	currentConstructName = root;
	[weaver weaveHeader: aHeader];
}

- (void) weaveClassNamed: (NSString *)aClassName
          superclassName: (NSString *)aSuperclassName
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	currentConstructName = aClassName;
	[weaver weaveClassNamed: aClassName superclassName: aSuperclassName];
}

- (void) weaveProtocolNamed: (NSString *)aProtocolName
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	NSString *symbol = [NSString stringWithFormat: @"(%@)", aProtocolName];
	currentConstructName = symbol;
	[weaver weaveProtocolNamed: aProtocolName];
}

- (void) weaveCategoryNamed: (NSString *)aCategoryName
                  className: (NSString *)aClassName
         isInformalProtocol: (BOOL)isInformalProtocol
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	NSString *symbol = [NSString stringWithFormat: @"%@(%@)", aClassName, aCategoryName];
	currentConstructName = symbol;
	[weaver weaveCategoryNamed: aCategoryName className: aClassName isInformalProtocol: isInformalProtocol];
}

- (void) weaveMethod: (DocMethod *)aMethod
{
	[self accumulateDocElement: aMethod];
	//[weaver weaveMethod: aMethod];
}

- (void) weaveFunction: (DocFunction *)aFunction
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	currentConstructName = root;
	[weaver weaveFunction: aFunction];
}

- (void) weaveMacro: (DocMacro *)aMacro
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	currentConstructName = root;
	[weaver weaveMacro: aMacro];
}

- (void) weaveConstant: (DocConstant *)aConstant
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	currentConstructName = root;
	[weaver weaveConstant: aConstant];
}

- (void) weaveOtherDataType: (DocCDataType *)aDataType
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	currentConstructName = root;
	[weaver weaveOtherDataType: aDataType];
}

- (void) finishWeaving
{
	[self flushAccumulatedDocElementsForConstructNamed: currentConstructName];
	currentConstructName = root;
}

- (DocHeader *) currentHeader
{
	return [weaver currentHeader];
}

@end
