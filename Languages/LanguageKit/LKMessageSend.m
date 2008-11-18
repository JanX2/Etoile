#import "LKMessageSend.h"
#import "LKDeclRef.h"

static Class NSStringClass = Nil;
static NSMutableDictionary *SelectorConflicts = nil;


@implementation NSString (Print)
- (void) print
{
  printf("%s", [self UTF8String]);
}
@end
@implementation LKMessageSend 
+ (void) initialize
{
	if (self != [LKMessageSend class])
	{
		return;
	}
	NSStringClass = [NSString class];
	// Look up potential selector conflicts.
	void *state = NULL;
	Class nextClass;
	NSMutableDictionary *types = [NSMutableDictionary new];
	SelectorConflicts = [NSMutableDictionary new];
	while(Nil != (nextClass = objc_next_class(&state)))
	{
		Class class = nextClass;
		struct objc_method_list *methods = class->methods;
		if (methods != NULL)
		{
			for (unsigned i=0 ; i<methods->method_count ; i++)
			{
				Method *m = &methods->method_list[i];

				NSString *name =
				   	[NSString stringWithCString:sel_get_name(m->method_name)];
				NSString *type = [NSString stringWithCString:m->method_types];
				NSString *oldType = [types objectForKey:name];
				if (oldType && ![type isEqualToString:oldType])
				{
					[SelectorConflicts setObject:oldType forKey:name];
				}
				else
				{
					[types setObject:type forKey:name];
				}
			}
		}
	}
	[types release];
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
	NSString *types = [SelectorConflicts objectForKey:selector];
	if (nil != types)
	{
		NSLog(@"Warning: Selector '%@' is polymorphic.  Assuming %@", selector,
				types);
	}
	//SEL sel = sel_get_any_typed_uid([selector UTF8String]);
	//NSLog(@"Selector %s types: %s", sel_get_name(sel), sel_get_type(sel));
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
	// FIXME: Use methodSignatureForSelector in inferred target type if possible.
	const char *seltypes = sel_get_type(sel_get_any_typed_uid(sel));
	// FIXME: This is a really ugly hack.
	if ([selector isEqualToString:@"count"])
	{
		seltypes = "I8@0:4";
	}
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
			                           types:seltypes
			                        toObject:receiver
			                        withArgs:argv
			                           count:argc];
		}
		else if (scope == builtin)
		{
			if ([symbol isEqualToString:@"self"])
			{
				result = [aGenerator sendMessage:sel
				                           types:seltypes
				                        toObject:receiver
				                        withArgs:argv
				                           count:argc];
			}
			else if ([symbol isEqualToString:@"super"])
			{
				result = [aGenerator sendSuperMessage:sel
				                                types:seltypes
				                             withArgs:argv
				                                count:argc];
			}
		}
	}
	if (NULL == result)
	{
		result = [aGenerator sendMessage:sel
	                               types:seltypes
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
		seltypes = sel_get_type(sel_get_any_typed_uid(sel));
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
