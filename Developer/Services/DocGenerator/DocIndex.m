/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocIndex.h"

@implementation DocIndex

@synthesize externalRefs;

static DocIndex *currentIndex = nil;

+ (id) currentIndex
{
	return currentIndex;
}

+ (void) setCurrentIndex: (DocIndex *)anIndex
{
	ASSIGN(currentIndex, anIndex);
}

- (id) createRefDictionaryWithMutability: (BOOL)mutable
{
	Class dictClass = (mutable ? [NSMutableDictionary class] : [NSDictionary class]);
	return [[dictClass alloc] initWithObjectsAndKeys: 
		[NSMutableDictionary dictionary], @"classes", 
		[NSMutableDictionary dictionary], @"protocols",
		[NSMutableDictionary dictionary], @"categories", 
		[NSMutableDictionary dictionary], @"methods", 
		[NSMutableDictionary dictionary], @"functions",
		[NSMutableDictionary dictionary], @"macros", 
		[NSMutableDictionary dictionary], @"constants", nil];
}

- (id) initWithGSDocIndexFile: (NSString *)anIndexFile
{
	SUPERINIT;
    ASSIGN(indexContent, anIndexFile);
	externalRefs = [self createRefDictionaryWithMutability: NO];
	projectRefs = [self createRefDictionaryWithMutability: YES];
	mergedRefs = [self createRefDictionaryWithMutability: YES];
    return self;
}

- (void) dealloc
{
	DESTROY(indexContent);
    DESTROY(externalRefs);
    DESTROY(projectRefs);
	DESTROY(mergedRefs);
	[super dealloc];
}

- (void) mergeRefs: (NSDictionary *)otherRefs 
            ofKind: (NSString *)aKind 
          intoRefs: (NSMutableDictionary *)refs
   reportConflicts: (BOOL)warn
withDictionaryName: (NSString *)mergedDictName
{
	NSMutableDictionary *refSubset = [refs objectForKey: aKind];
	NSDictionary *otherRefSubset = [otherRefs objectForKey: aKind];

	for (NSString *symbolName in otherRefSubset)
	{
		if (warn && [refSubset objectForKey: symbolName] != nil)
		{
			ETLog(@"WARNING: Conflict between old ref %@ and new ref %@ "
				"named %@ while merging %@ from %@", [refSubset objectForKey: symbolName],
				[otherRefSubset objectForKey: symbolName] , symbolName, aKind, mergedDictName);
		}

		[refSubset setObject: [otherRefSubset objectForKey: symbolName] 
		              forKey: symbolName];
	}
}

- (void) regenerate
{
	NSArray *refKinds = [self symbolKinds];
	NSArray *refIVarNames = A(@"externalRefs", @"projectRefs");
	
	FOREACH(refKinds, kind, NSString *)
	{
		[[mergedRefs objectForKey: kind] removeAllObjects];
	}

	FOREACH(refIVarNames, dictName, NSString *)
	{
		FOREACH(refKinds, kind, NSString *)
		{
			[self mergeRefs: [self valueForKey: dictName]
			         ofKind: kind
			       intoRefs: mergedRefs
			reportConflicts: YES
		 withDictionaryName: dictName];	
		}
	}
}

- (void) setProjectRef: (NSString *)aRef
         forSymbolName: (NSString *)aSymbol
                ofKind: (NSString *)aKind
{
	/* Don't accept external refs */
	ETAssert([aRef hasSuffix: [self refFileExtension]] == NO);

	NSString *finalRef = [aRef stringByAppendingPathExtension: [self refFileExtension]];
	[[projectRefs objectForKey: aKind] setObject: finalRef forKey: aSymbol];
}

- (NSArray *) projectSymbolNamesOfKind: (NSString *)aKind
{
	return [[projectRefs objectForKey: aKind] allKeys];
}

- (NSArray *) symbolKinds
{
	return A(@"classes", @"protocols", @"categories", @"methods", 
		@"functions", @"macros", @"constants");
}

- (NSString *) linkWithName: (NSString *)aName ref: (NSString *)aRef
{
	return aName;
}

- (NSString *) linkForSymbolName: (NSString *)aSymbol
{
	return [self linkWithName: aSymbol forSymbolName: aSymbol];
}

- (NSString *) linkWithName: (NSString *)aName forSymbolName: (NSString *)aSymbol
{
	return [self linkWithName: aName forClassName: aSymbol];
}

- (NSString *) linkForClassName: (NSString *)aClassName
{
	return [self linkWithName: aClassName forClassName: aClassName];
}

- (NSString *) linkWithName: (NSString *)aName forClassName: (NSString *)aClassName
{
	return [self linkWithName: aClassName
                          ref: [[mergedRefs objectForKey: @"classes"] objectForKey: aClassName]
	                   anchor: aClassName];
}

- (NSString *) linkForProtocolName: (NSString *)aProtocolName
{
	return [self linkWithName: aProtocolName
                          ref: [[mergedRefs objectForKey: @"protocols"] objectForKey: aProtocolName]
	                   anchor: aProtocolName];
}

- (NSString *) linkForGSDocRef: (NSString *)aRef
{
	return nil;
}

- (NSString *) linkForMethodName: (NSString *)aMethodName 
                     inClassName: (NSString *)aClassName
                    categoryName: (NSString *)aCategoryName
                   isClassMethod: (BOOL)isClassMethod
{
	return nil;
}

- (NSString *) linkForMethodRef: (NSString *)aRef
{
	return nil;
}

- (NSString *) linkWithName: (NSString *)aName ref: (NSString *)aRef anchor: (NSString *)anAnchor
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

- (NSString *) refFileExtension
{
	return nil;
}

@end


@implementation HTMLDocIndex

- (NSString *) linkWithName: (NSString *)aName ref: (NSString *)aRef anchor: (NSString *)anAnchor
{
	if (aRef == nil)
    	return aName;

	if (anAnchor != nil)
	{
		return [NSString stringWithFormat: @"<a href=\"%@%#%@\">%@</a>", aRef, anAnchor, aName];
	}
	else
	{
		return [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", aRef, aName];	
	}
}

- (NSString *) refFileExtension
{
	return @"html";
}


@end

