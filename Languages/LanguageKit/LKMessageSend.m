#import "LKMessageSend.h"
#import "LKDeclRef.h"
#import "LKModule.h"

static NSMutableDictionary *SelectorConflicts = nil;


@implementation NSString (Print)
- (void) print
{
  printf("%s", [self UTF8String]);
}
@end
@implementation LKMessageSend 
+ (id) message
{
	return AUTORELEASE([[self alloc] init]);
}
+ (id) message:(NSString*)aSelector
{
	return AUTORELEASE([[self alloc] initWithSelectorName:aSelector]);
}
- (id) initWithSelectorName:(NSString*)aSelector
{
	SELFINIT;
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
- (NSMutableArray*) arguments
{
  return arguments;
}
- (NSString*) selector
{
	return selector;
}

- (void) check
{
	[target setParent:self];
	[target check];
	// This will generate a warning on polymorphic selectors.
	type = [[self module] typeForMethod:selector];
	FOREACH(arguments, arg, LKAST*)
	{
		[arg setParent:self];
		[arg check];
	}
}

- (NSString*) description
{
	NSMutableString *str = [NSMutableString string];
	[str appendString:[target description]];
	[str appendString:@" "];
	NSArray *sel = [selector componentsSeparatedByString:@":"];
	int i;
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
	for (i=1 ; i<[arguments count] ; i++)
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
- (void*) compileWith:(id<LKCodeGenerator>)aGenerator forTarget:(void*)receiver
{
	unsigned argc = [arguments count];
	void *argv[argc];
	for (unsigned i=0 ; i<argc ; i++)
	{
		argv[i] = [[arguments objectAtIndex:i] compileWith:aGenerator];
	}
	const char *sel = [selector UTF8String];
	void *result = NULL;
	// If the receiver is a global symbol, it is guaranteed to be an object.
	// TODO: The same is arguments if their type is @
	if ([target isKindOfClass:[LKDeclRef class]])
	{
		LKDeclRef *ref = SAFECAST(LKDeclRef, target);
		NSString *symbol = ref->symbol;
		LKSymbolScope scope = [symbols scopeOfSymbol:symbol];
		if (scope == global)
		{
			result = [aGenerator sendMessage:sel
			                           types:type
			                        toObject:receiver
			                        withArgs:argv
			                           count:argc];
		}
		else if (scope == builtin)
		{
			if ([symbol isEqualToString:@"self"])
			{
				result = [aGenerator sendMessage:sel
				                           types:type
				                        toObject:receiver
				                        withArgs:argv
				                           count:argc];
			}
			else if ([symbol isEqualToString:@"super"])
			{
				result = [aGenerator sendSuperMessage:sel
				                                types:type
				                             withArgs:argv
				                                count:argc];
			}
		}
	}
	if (NULL == result)
	{
		result = [aGenerator sendMessage:sel
	                               types:type
	                                  to:receiver
	                            withArgs:argv
	                               count:argc];
	}
	// If an object is created with new then send it an autorelease message
	// immediately after construction.  This ensures that any new object always
	// has a retain count of 1 and an autorelease count of 1 unless explicitly
	// created using alloc init to bypass this.
	if ([selector isEqualToString:@"new"])
	{
		sel = "autorelease";
		const char *seltypes = sel_get_type(sel_get_any_typed_uid(sel));
		[aGenerator sendMessage:sel
		                  types:seltypes
		               toObject:result
		               withArgs:NULL
		                  count:0];
	}
	return result;
}
- (void*) compileWith:(id<LKCodeGenerator>)aGenerator
{
	return [self compileWith:aGenerator
	               forTarget:[target compileWith:aGenerator]];
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
	LKMessageCascade *obj = [[self alloc] initWithTarget:aTarget
	                                            messages:messageArray];
	[obj autorelease];
	return obj;
}
- (void*) compileWith:(id<LKCodeGenerator>)aGenerator
{
	id target = [receiver compileWith:aGenerator];
	id result;
	FOREACH(messages, message, LKMessageSend*)
	{
		result = [message compileWith:aGenerator forTarget:target];
	}
	return result;
}
- (void) addMessage:(LKMessageSend*)aMessage
{
	[messages addObject:aMessage];
}
- (void) check
{
	[receiver setParent:self];
	[receiver check];
	FOREACH(messages, message, LKMessageSend*)
	{
		[message setParent:self];
		[message check];
	}
}
- (void) dealloc
{
	[receiver release];
	[messages release];
	[super dealloc];
}
@end
