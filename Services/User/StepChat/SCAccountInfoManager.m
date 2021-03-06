/**
Copyright (C) 2012 Alessandro Sangiuliano
         
Author: Alessandro Sangiuliano <alex22_7@hotmail.com>
Date: January 2012        
License: Modified BSD
*/

#import "SCAccountInfoManager.h"

@implementation SCAccountInfoManager

- (id)init
{
	self = [super init];
	NSString *home = NSHomeDirectory();
	gPath = [[NSMutableString alloc] initWithString:home];
	[gPath appendString:@"/GNUstep/Library/Addresses/"];
	fileName = @"waJID";
	filePath = [[NSMutableString alloc] initWithString:gPath];
	[filePath appendString:fileName];
	return self;
}

@synthesize filePath; 

-(NSString*)readJIDFromFileAtPath:(NSString*)aPath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSData *contents;
  
	if ([fileManager fileExistsAtPath:aPath] == YES)
	{
		NSFileHandle *fileHandler = [NSFileHandle fileHandleForReadingAtPath:aPath];
		contents = [fileHandler readDataToEndOfFile];
		[fileHandler closeFile];
	}
	else
	{
		BOOL done = [fileManager createFileAtPath:aPath contents:nil attributes:nil];
		return @"N";
	}
  
	if ([contents length] == 0)
	{
		return @"N";
	}
  
	NSString *jid = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
	return jid;
}

-(void)writeJIDToFile:(JID*)aJID atPath:(NSString*)aPath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
  
	if ([fileManager fileExistsAtPath:aPath] == YES)
	{
		NSString *jid = [aJID jidString];
		BOOL done = [jid writeToFile:aPath 
                          atomically:NO 
                            encoding:NSUTF8StringEncoding 
                               error:NULL];

		if (done == NO)
		{
			[NSAlert alertWithMessageText:@"Can't write to file"
                            defaultButton:@"OK"
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:@""];
		}
	}
	else
	{
		[fileManager createFileAtPath:aPath contents:nil attributes:nil];
		NSString *jid = [aJID jidString];
		BOOL done = [jid writeToFile:aPath 
                          atomically:NO 
                            encoding:NSUTF8StringEncoding 
                               error:NULL];
    
		if (done == NO)
		{
			[NSAlert alertWithMessageText:@"Can't write to file"
                            defaultButton:@"OK"
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:@""];
		}
	}
}

- (NSString*) composeNewJIDWithOldJID:(JID*)oldJID withServer:(NSString*)aServer
{
	NSString *oldJid;
	oldJid = [oldJID jidString];
	NSRange checker = [oldJid rangeOfString:@"@"];
	NSString *aux;
	NSMutableString *newJID;

	if (checker.location != NSNotFound || checker.length != 0)
	{
		aux = [oldJid substringToIndex:checker.location+1];
		newJID = [[NSMutableString alloc] initWithString:aux];
		[newJID appendString:aServer];
	}
	else
	{
		newJID = [[NSMutableString alloc] initWithString:oldJid];
		[newJID appendString:@"@"];
		[newJID appendString:aServer];
	}

	return newJID;
}


@end
    
