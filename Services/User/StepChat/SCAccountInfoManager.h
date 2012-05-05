/**
Copyright (C) 2012 Alessandro Sangiuliano
         
Author: Alessandro Sangiuliano <alex22_7@hotmail.com>
Date: January 2012        
License: Modified BSD
*/



#import <Foundation/Foundation.h>
#import <XMPPKit/XMPPAccount.h>

@interface SCAccountInfoManager : NSObject
{
	NSMutableString *__strong filePath;
	NSString *fileName;
	NSMutableString *gPath;
}

@property (strong, nonatomic, readonly) NSString *filePath; 

- (NSString*) readJIDFromFileAtPath:(NSString*)aPath;
- (void) writeJIDToFile:(JID*)aJID atPath:(NSString*)aPath;
- (NSString*) composeNewJIDWithOldJID:(JID*)oldJID withServer:(NSString*)aServer;

@end
