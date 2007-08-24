/*
	NSFileManager+iconKit.m

	NSFileManager extension with convenient methods
	
	Copyright (C) 2004  Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	   this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.
	3. The name of the author may not be used to endorse or promote products
	   derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
	EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
	IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
	OF SUCH DAMAGE.
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
  BOOL result;
  
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
