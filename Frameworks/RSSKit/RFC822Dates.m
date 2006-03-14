
// -*-objc-*-

#import <Foundation/Foundation.h>


NSString* days[7] = {
  @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat", @"Sun"
};


unichar* str;
int position;
int length;

NSDate* parseRFC822Date ( NSString* dateStr )
{
  length = [dateStr length];
  
  str = (unichar*) malloc(length*sizeof(unichar));
  [dateStr getCharacters: str];
  
  
}

