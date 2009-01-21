#import <EtoileFoundation/EtoileFoundation.h>
#import "LKAST.h"
#import "LKCategory.h"
#import "LKCompiler.h"
#import "LKMethod.h"
#import "LKModule.h"

static NSMutableDictionary *compilersByExtension;
static NSMutableDictionary *compilersByLanguage;

int DEBUG_DUMP_MODULES = 0;
@implementation LKCompiler
+ (void) loadBundles
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *dirs =
		NSSearchPathForDirectoriesInDomains(
			NSLibraryDirectory,
			NSAllDomainsMask,
			YES);
	FOREACH(dirs, dir, NSString*)
	{
		NSString *f =
			[[dir stringByAppendingPathComponent:@"Bundles"]
				stringByAppendingPathComponent:@"LanguageKit"];
		// Check that the framework exists and is a directory.
		NSArray *bundles = [fm directoryContentsAtPath:f];
		FOREACH(bundles, bundle, NSString*)
		{
			bundle = [f stringByAppendingPathComponent:bundle];
			BOOL isDir = NO;
			if ([fm fileExistsAtPath:bundle isDirectory:&isDir]
				&& isDir)
			{
				NSBundle *b = [NSBundle bundleWithPath:bundle];
				if ([b load])
				{
					// Message is ignored, just ensure that +initialize is
					// called and the class is connected to the hierarchy.
					[[b principalClass] description];
				}
			}
		}
	}
}
+ (void) initialize 
{
	if (self != [LKCompiler class])
	{
		return;
	}
	[self loadBundles];

	compilersByExtension = [NSMutableDictionary new];
	compilersByLanguage = [NSMutableDictionary new];
	NSArray *classes = [self directSubclasses];
	FOREACH(classes, nextClass, Class)
	{
		[compilersByLanguage setObject:nextClass
		                        forKey:[nextClass languageName]];
		[compilersByExtension setObject:nextClass
		                         forKey:[nextClass fileExtension]];
	}
}
+ (id) alloc
{
	if (self == [LKCompiler class])
	{
		[NSException raise:@"InstantiationError"
		            format:@"LKCompiler instances are invalid"];
		return nil;
	}
	return [super alloc];
}
+ (LKCompiler*) compiler
{
	return AUTORELEASE([[self alloc] init]);
}
+ (void) setDebugMode:(BOOL)aFlag
{
	DEBUG_DUMP_MODULES = (int) aFlag;
}

- (BOOL) compileString:(NSString*)source withGenerator:(id<LKCodeGenerator>)cg
{
	id p = AUTORELEASE([[[[self class] parser] alloc] init]);
	LKModule *ast;
	NS_DURING
		ast = [p parseString: source];
		[ast check];
	NS_HANDLER
		NSDictionary *e = [localException userInfo];
		if ([[localException name] isEqualToString:@"ParseError"])
		{
			NSLog(@"Parse error on line %@.  Unexpected token at character %@ while parsing:\n%@",
										   [e objectForKey:@"lineNumber"],
										   [e objectForKey:@"character"],
										   [e objectForKey:@"line"]);
		}
		else
		{
			NSLog(@"Semantic error: %@", [localException reason]);
		}
		return NO;
	NS_ENDHANDLER	
	if (nil == ast)
	{
		return NO;
	}
	[ast compileWith:cg];
	return YES;
}
- (BOOL) compileString:(NSString*)source output:(NSString*)bitcode;
{
	id<LKCodeGenerator> cg = defaultStaticCompilterWithFile(bitcode);
	return [self compileString:source withGenerator:cg];
}
- (BOOL) compileString:(NSString*)source
{
	return [self compileString:source withGenerator:defaultJIT()];
}

- (BOOL) compileMethod:(NSString*)source
               onClass:(NSString*)name
         withGenerator:(id<LKCodeGenerator>)cg
{
	id p = AUTORELEASE([[[[self class] parser] alloc] init]);
	LKAST *ast;
	LKModule *module;
	NS_DURING
		ast = [p parseMethod: source];
		ast = [LKCategoryDef categoryWithClass:name
		                               methods:[NSArray arrayWithObject:ast]];
		module = [LKModule module];
		[module addCategory:ast];
		[module check];
	NS_HANDLER
		NSDictionary *e = [localException userInfo];
		if ([[localException name] isEqualToString:@"ParseError"])
		{
			NSLog(@"Parse error on line %@.  Unexpected token at character %@ while parsing:\n%@",
										   [e objectForKey:@"lineNumber"],
										   [e objectForKey:@"character"],
										   [e objectForKey:@"line"]);
		}
		else
		{
			NSLog(@"Semantic error: %@", [localException reason]);
		}
		return NO;
	NS_ENDHANDLER	
	if (nil == ast)
	{
		return NO;
	}
	[module compileWith:cg];
	return YES;
}
- (BOOL) compileMethod:(NSString*)source
               onClass:(NSString*)name
                output:(NSString*)bitcode
{
	id<LKCodeGenerator> cg = defaultStaticCompilterWithFile(bitcode);
	return [self compileMethod:source onClass:name withGenerator:cg];
}
- (BOOL) compileMethod:(NSString*)source onClass:(NSString*)name
{
	return [self compileMethod:source onClass:name withGenerator:defaultJIT()];
}

+ (BOOL) loadFramework:(NSString*)framework
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
			NSAllDomainsMask, YES);
	FOREACH(dirs, dir, NSString*)
	{
		NSString *f = [NSString stringWithFormat:@"%@/Frameworks/%@.framework",
				 dir, framework];
		// Check that the framework exists and is a directory.
		BOOL isDir = NO;
		if ([fm fileExistsAtPath:f isDirectory:&isDir] && isDir)
		{
			NSBundle *bundle = [NSBundle bundleWithPath:f];
			if ([bundle load]) 
			{
				NSLog(@"Loaded bundle %@", f);
				return YES;
			}
		}
	}
	return NO;
}

+ (BOOL) loadScriptInBundle:(NSBundle*)bundle named:(NSString*)fileName
{
	NSString *name = [fileName stringByDeletingPathExtension];
	NSString *extension = [fileName pathExtension];
	id compiler = [[compilersByExtension objectForKey: extension] compiler];
	return [compiler loadScriptInBundle: bundle named: name];
}
- (BOOL) loadScriptInBundle:(NSBundle*)bundle named:(NSString*)name
{
	NSString *extension = [[self class] fileExtension];
	NSString *path = [bundle pathForResource:name ofType:extension];
	if (nil == path)
	{
		NSLog(@"Unable to find %@.%@ in bundle %@.", name, extension, bundle);
		return NO;
	}
	return [self compileString:[NSString stringWithContentsOfFile:path]];
}

+ (BOOL) loadApplicationScriptNamed:(NSString*)fileName
{
	return [self loadScriptInBundle: [NSBundle mainBundle] named: fileName];
}
- (BOOL) loadApplicationScriptNamed:(NSString*)name
{
	return [self loadScriptInBundle: [NSBundle mainBundle] named: name];
}

+ (BOOL) loadScriptsInBundle:(NSBundle*) aBundle
{
	BOOL success = YES;
	FOREACH(compilersByLanguage, class, Class)
	{
		id compiler = [[class alloc] init];
		success &= [compiler loadScriptsInBundle: aBundle];
		RELEASE(compiler);
	}
	return success;
}
- (BOOL) loadScriptsInBundle:(NSBundle*) aBundle
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSString *extension = [[self class] fileExtension];
	NSArray *scripts = [aBundle pathsForResourcesOfType:extension
	                                        inDirectory:nil];
	BOOL success = YES;
	FOREACH(scripts, scriptFile, NSString*)
	{
		NSString *script = [NSString stringWithContentsOfFile: scriptFile];
		success &= [self compileString:script];
	}
	[pool release];
	return success;
}

+ (BOOL) loadAllScriptsForApplication
{
	return [self loadScriptsInBundle:[NSBundle mainBundle]];
}
- (BOOL) loadAllScriptsForApplication
{
	return [self loadScriptsInBundle:[NSBundle mainBundle]];
}

+ (NSString*) fileExtension
{
	[self subclassResponsibility:_cmd];
	return nil;
}
+ (NSString*) languageName
{
	[self subclassResponsibility:_cmd];
	return nil;
}
+ (NSArray*) supportedLanguages
{
	return [compilersByLanguage allKeys];
}
+ (Class) compilerForLanguage:(NSString*) aLanguage
{
	return [compilersByLanguage objectForKey:aLanguage];
}
+ (Class) compilerForExtension:(NSString*) anExtension
{
	return [compilersByExtension objectForKey:anExtension];
}
+ (Class) parser
{
	[self subclassResponsibility:_cmd];
	return Nil;
}
@end
