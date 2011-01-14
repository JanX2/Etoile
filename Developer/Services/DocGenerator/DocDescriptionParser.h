/**
	<abstract>ETDoc markup parser.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>


/** @group ETDoc Parsing 

Parser to extract ETDoc markup located in method, function and macro 
descriptions. */
@interface DocDescriptionParser : NSObject 
{
	@private
	NSMutableDictionary *parsed;
	NSString *currentTag;
}

/** Returns the tags allowed before the main description.

The element order matters. e.g. @taskunit must preceded @task, otherwise 
@taskunit is parsed as @task. */
- (NSArray *) validTagsBeforeMainDescription;
/** Returns the tags allowed before the main description.

The element order matters, see -validTagsBeforeMainDescription. */
- (NSArray *) validTagsAfterMainDescription;
/** Resets the parser state and parses ETDoc markup in the given API description.

Query the receiver to retrieve the parsing result. */
- (void) parse: (NSString *)corpus;

/** @taskunit Parsing Result */

/** Returns the parsed main description. */
- (NSString *) description;
/** Returns the parsed content for <em>@task</em> tag. */
- (NSString *) task;
/** Returns the parsed content for <em>@taskunit</em> tag. */
- (NSString *) taskUnit;
/** Returns the parsed content for <em>@return</em> tag. */
- (NSString *) returnDescription;
/** Returns the parsed content for the <em>@param &lt;aName&gt;</em> tag sequence. */
- (NSString *) descriptionForParameter: (NSString *)aName;

@end

/** @group ETDoc Parsing 

Parser to extract ETDoc markup located in class, protocol or category 
descriptions. */
@interface DocMethodGroupDescriptionParser : DocDescriptionParser
{

}

/** @taskunit Parsing Result */

/** Returns the parsed content for <em>@group</em> tag. */
- (NSString *) group;

@end
