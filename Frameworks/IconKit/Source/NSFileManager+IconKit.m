/*
	NSFileManager+iconKit.m

	NSFileManager extension with convenient methods
	
	Copyright (C) 2004  Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import "IKCompat.h"
#import "NSFileManager+IconKit.h"

@implementation NSFileManager (IconKit)

- (BOOL) buildDirectoryStructureForPath: (NSString *)path
{
  NSArray *components = [path pathComponents];
  NSString *pathToCheck = [NSString string];
  int i;
  int cCount = [components count];
  BOOL result = NO;
  
  for (i = 0; i < cCount; i++)
    {
      pathToCheck = [pathToCheck stringByAppendingPathComponent: [components objectAtIndex: i]];     
      
      result = [self checkWithEventuallyCreatingDirectoryAtPath: pathToCheck];
      if (result == NO)
        {
          NSLog(@"Impossible to create directory structure for the path %@", path);
          break;
        }
        
     }
  return result;
}

- (BOOL) checkWithEventuallyCreatingDirectoryAtPath: (NSString *)path
{
  BOOL isDir;
  BOOL result; 
  NSFileManager *fm = [NSFileManager defaultManager];
  
  if ([fm fileExistsAtPath: path isDirectory: &isDir] == NO)
    {
      result = [fm createDirectoryAtPath: path attributes: nil] ;
      // May be shouldn't be nil
    }
  else if (isDir == NO) // A file exists for this path
    {
      NSLog(@"Impossible to create a directory named %@ at the path %@ \
        because there is already a file with this name", 
        [path lastPathComponent], [path stringByDeletingLastPathComponent]); 
      result = NO;
    }
  else if (isDir) // A directory exists already for this path, then nothing to do
    {
      result = YES;
    }
    
  return result;
}

@end
