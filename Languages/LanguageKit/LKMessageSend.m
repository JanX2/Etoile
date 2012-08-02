#import "LKMessageSend.h"
#import "LKDeclRef.h"
#import "LKModule.h"
#import "LKCompilerErrors.h"


static NSSet *ARCBannedMessages;

@implementation NSString (Print)
- (void) print
{
  printf("%s", [self UTF8String]);
}
@end

@implementation LKMessageSend 
+ (void)initialize
{
	ARCBannedMessages = [[NSSet alloc] initWithObjects: @"retain", @"release", @"autorelease", @"retainCount", @"dealloc", nil];
}
+ (id) message
{
	return AUTORELEASE([[self alloc] init]);
}
+ (id) messageWithSelectorName:(NSString*)aSelector
{
	return AUTORELEASE([[self alloc] initWithSelectorName:aSelector]);
}
- (id)initWithSelectorName: (NSString*)aSelector
                 arguments: (NSArray*)args
{
	SUPERINIT;
	ASSIGN(selector, aSelector);
	arguments = [args mutableCopy];
	return self;
}
+ (id)messageWithSelectorName: (NSString*)aSelector
                    arguments: (NSArray*)args
{
	return [[self alloc] initWithSelectorName: aSelector
	                                 arguments: args];
}
- (id) initWithSelectorName:(NSString*)aSelector
{
	SUPERINIT;
	ASSIGN(selector, aSelector);
	return self;
}
- (void) setTarget:(id)anObject
{
	ASSIGN(target, anObject);
}

- (void) addSelectorComponent:(NSString*)aSelector
{
	if(selector == nil)
	{
		ASSIGN(selector, aSelector);
	}
	else
	{
		NSString * sel = [selector stringByAppendingString:aSelector];
		ASSIGN(selector, sel);
	}
}

- (void) addArgument:(id)anObject
{
	if (arguments == nil)
	{
		arguments = [[NSMutableArray alloc] init];
	}
	[arguments addObject:anObject];
}
- (NSArray*) arguments
{
  	return arguments;
}
// FIXME: Rename to methodName or similar.
- (NSString*) selector
{
	return selector;
}

- (id) target
{
	return target;
}
- (BOOL)check
{
	[(LKAST*)target setParent:self];
	if ([ARCBannedMessages containsObject: selector])
	{
		NSDictionary *errorDetails = D(
			[NSString stringWithFormat: @"%@ may not be used in LanguageKit",
				selector], kLKHumanReadableDescription,
			self, kLKASTNode);
		if ([LKCompiler reportError: LKInvalidSelectorError
		                    details: errorDetails])
		{
			return [self check];
		}
		return NO;
	}

	BOOL success = (target == nil) || [target check];

	LKModule *module = [self module];

	ASSIGN(type, [module typesForMethod: selector]);

	FOREACH(arguments, arg, LKAST*)
	{
		[arg setParent:self];
		success &= [arg check];
	}
	return success;
}

- (NSString*) description
{
	NSMutableString *str = [NSMutableString string];
	if (target)
	{
		[str appendString: [target description]];
	}
	[str appendString:@" "];
	NSArray *sel = [selector componentsSeparatedByString:@":"];
	if ([sel count] == 1)
	{
		[str appendString:selector];
	}
	else
	{
		[str appendString:[sel objectAtIndex:0]];
	}
	if ([arguments count])
	{
		[str appendFormat:@": %@", [arguments objectAtIndex:0]];
	}
	for (unsigned int i=1 ; i<[arguments count] ; i++)
	{
		if (i<[sel count])
		{
			[str appendString:@" "];
			[str appendString:[sel objectAtIndex:i]];
		}
		[str appendFormat:@": %@", [arguments objectAtIndex:i]];
	}
	return str;
}
- (void*) compileWithGenerator: (id<LKCodeGenerator>)aGenerator forTarget:(void*)receiver
{
	unsigned int argc = [arguments count];
	void *argv[argc];
	for (unsigned int i=0 ; i<argc ; i++)
	{
		argv[i] = [[arguments objectAtIndex:i] compileWithGenerator: aGenerator];
	}
	void *result = NULL;
	// If the receiver is a global symbol, it is guaranteed to be an object.
	// TODO: The same is arguments if their type is @
	if ([target isKindOfClass:[LKDeclRef class]])
	{
		if ([target isKindOfClass:[LKSelfRef class]] ||
		    [target isKindOfClass:[LKBlockSelfRef class]])
		{
			result = [aGenerator sendMessage:selector
									   types:type
									toObject:receiver
									withArgs:argv
									   count:argc];
		}
		else if ([target isKindOfClass: [LKSuperRef class]])
		{
			// FIXME: We know the superclass, so we should be looking up the
			// type encoding properly!
			result = [aGenerator sendSuperMessage:selector
											types: [type objectAtIndex: 0]
										 withArgs:argv
											count:argc];
		}
		else if ([target isKindOfClass:[LKNilRef class]])
		{
			return [aGenerator nilConstant];
		}
		else
		{
			LKDeclRef *ref = SAFECAST(LKDeclRef, target);
			LKSymbol *symbol = [ref symbol];
			LKSymbolScope scope = [symbol scope];
			if (scope == LKSymbolScopeGlobal)
			{
				result = [aGenerator sendMessage:selector
										   types:type
										toObject:receiver
										withArgs:argv
										   count:argc];
			}
		}
	}
	if (NULL == result)
	{
		result = [aGenerator sendMessage: selector
		                           types: type
		                              to: receiver
		                        withArgs: argv
		                           count: argc];
	}
	return result;
}
- (void*) compileWithGenerator: (id<LKCodeGenerator>)aGenerator
{
	return [self compileWithGenerator: aGenerator
	               forTarget:[target compileWithGenerator: aGenerator]];
}
- (void) visitWithVisitor:(id<LKASTVisitor>)aVisitor
{
	if (nil != target)
	{
		id tmp = [aVisitor visitASTNode:target];
		ASSIGN(target, tmp);
		[target visitWithVisitor:aVisitor];
	}
	[self visitArray: arguments withVisitor: aVisitor];
}
@end
@implementation LKMessageCascade 
- (LKMessageCascade*) initWithTarget:(LKAST*) aTarget
                            messages:(NSMutableArray*) messageArray
{
	SELFINIT;
	ASSIGN(receiver, aTarget);
	ASSIGN(messages, messageArray);
	return self;
}
+ (LKMessageCascade*) messageCascadeWithTarget:(LKAST*) aTarget
                                      messages:(NSMutableArray*) messageArray
{
	return [[self alloc] initWithTarget:aTarget
	                            messages:messageArray];
}
- (void*) compileWithGenerator: (id<LKCodeGenerator>)aGenerator
{
	void *target = [receiver compileWithGenerator: aGenerator];
	void *result = NULL;
	FOREACH(messages, message, LKMessageSend*)
	{
		result = [message compileWithGenerator: aGenerator forTarget:target];
	}
	return result;
}
- (void) visitWithVisitor:(id<LKASTVisitor>)aVisitor
{
	id tmp = [aVisitor visitASTNode:receiver];
	ASSIGN(receiver, tmp);
	[receiver visitWithVisitor:aVisitor];
	[self visitArray: messages withVisitor: aVisitor];
}
- (void) addMessage:(LKMessageSend*)aMessage
{
	[messages addObject:aMessage];
}
- (BOOL) check
{
	[receiver setParent:self];
	BOOL success = [receiver check];
	FOREACH(messages, message, LKMessageSend*)
	{
		[message setParent:self];
		success &= [message check];
	}
	return success;
}
- (NSString*) description
{
	NSMutableString *str = [NSMutableString string];
	[str appendString: [receiver description]];
	[str appendString:@" "];
	for (int i=0; i<[messages count]; i++)
	{
		NSString* message = [[messages objectAtIndex: i] description];
		if (i>0)
		{
			[str appendString: @"; "];
		}
		[str appendString: message];
	}
	return str;
}
@end
