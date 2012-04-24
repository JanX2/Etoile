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
  NSMutableString *filePath;
  NSString *fileName;
  NSMutableString *gPath;
}

@property (nonatomic, readonly) NSString *filePath; 

-(NSString*)readJIDFromFileAtPath:(NSString*)aPath;
-(void)writeJIDToFile:(JID*)aJID atPath:(NSString*)aPath;

@end
