#import "ScriptCenter.h"
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>

static ScriptCenter *sharedInstance;
@implementation ScriptCenter 
+ (void) initialize
{
	sharedInstance = [ScriptCenter new];
}
+ (ScriptCenter*) sharedInstance
{
	return sharedInstance;
}
- (void) enableScriptingWithObjects:(NSDictionary*) scriptObjects
{
	[dict release];
	dict = [[scriptObjects mutableCopy] retain];
	if (![dict objectForKey:@"Application"])
	{
		[dict setObject:NSApp forKey:@"Application"];
	}

	NSConnection *theConnection;
	theConnection = [NSConnection defaultConnection];
	[theConnection setRootObject:dict];
	NSString *name = [NSString stringWithFormat:@"Etoile/%@/Scripts",
			 [[NSProcessInfo processInfo] processName]];
	if ([theConnection registerName:name] == NO)
	{
		[NSException raise:@"DOException"
					format:@"Can't register with DO server"];
	}
}
- (void) enableScripting
{
	[self enableScriptingWithObjects:D(NSApp, @"Application")];
}
- (void) scriptObject:(id)anObject withName:(NSString*) aName
{
	[dict setObject:anObject forKey:aName];
}
+ (NSDictionary*) scriptDictionaryForApplication:(NSString*) anApp
{
	NSString *name = [NSString stringWithFormat:@"Etoile/%@/Scripts", anApp];
	id dict = [NSConnection rootProxyForConnectionWithRegisteredName:name
	                                                            host:nil];
	if (nil == dict)
	{
		[[NSWorkspace sharedWorkspace] launchApplication:anApp];
		dict = [NSConnection rootProxyForConnectionWithRegisteredName:name
	                                                             host:nil];
	}
	return dict;
}
@end
