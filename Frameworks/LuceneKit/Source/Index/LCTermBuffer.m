#include "LuceneKit/Index/LCTermBuffer.h"
#include "LuceneKit/Index/LCTerm.h"
#include "LuceneKit/Index/LCFieldInfos.h"
#include "LuceneKit/Store/LCIndexInput.h"
#include "GNUstep.h"

@implementation LCTermBuffer

- (id) init
{
  self = [super init];
  text = [[NSMutableString alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(text);
  [super dealloc];
}

- (NSComparisonResult) compareTo: (LCTermBuffer *) other
{
  if ([field isEqualToString: [other field]])
    [self compareChars: text to: [other text]];
  else
    [field compare: [other field]]; 
}

- (NSComparisonResult) compareChars: (NSString *) v1 to: (NSString *) v2
{
  int end = ([v1 length] < [v2 length]) ? [v1 length] : [v2 length];
  int k;
  unichar c1, c2;
  for (k = 0; k < end; k++) {
	  c1 = [v1 characterAtIndex: k];
	  c2 = [v2 characterAtIndex: k];
	if (c1 < c2)
		return NSOrderedAscending;
	else if (c1 == c2)
		return NSOrderedSame;
	else
		return NSOrderedDescending;
    }
  if ([v1 length] < [v2 length])
	  return NSOrderedAscending;
  else if ([v1 length] < [v2 length])
	  return NSOrderedSame;
  else
	  return NSOrderedDescending;
}

- (void) setTextLength: (int) newLength
{
  textLength = newLength;
}

- (void) read: (LCIndexInput *) input
         fieldInfos: (LCFieldInfos *) fieldInfos
{
  term = nil;                           // invalidate cache
  int start = [input readVInt];
  int length = [input readVInt];
  int totalLength = start + length;
  [self setTextLength: totalLength];
  [input readChars: text start: start length: length];
  NSString *s3 = [fieldInfos fieldName: [input readVInt]];
  ASSIGN(field, s3);
}

- (void) setTerm: (LCTerm *) t
{
  if (t == nil)
  {
	  [self reset];
	  return;
  }

    // copy text into the buffer
  [self setTextLength: [[t text] length]];
  [text setString: [term text]];
  ASSIGN(field, [term field]);
  ASSIGN(term, t);
 }

- (int) textLength
{
  return textLength;
}

- (NSString *) text
{
  return text;
}

- (NSString *) field
{
  return field;
}

- (LCTerm *) term
{
  return term;
}

- (void) setTermBuffer: (LCTermBuffer *) other
{
  [self setTextLength: [other textLength]];
  [text setString: [other text]];
  ASSIGN(field, [other field]);
  ASSIGN(term, [other term]);
}

- (void) reset
{
  DESTROY(field);
  textLength = 0;
  DESTROY(term);
}

- (LCTerm *) toTerm
{
  if (field == nil)                            // unset
      return nil;

    if (term == nil)
    {
      ASSIGN(term, [[LCTerm alloc] initWithField: field
		                   text: text]);
    }

    return term;
  }

- (void) setField: (NSString *) f text: (NSString *) t
{
  ASSIGN(field, f);
  ASSIGN(text, t);
}

- (id) copyWithZone: (NSZone *) zone
{
  LCTermBuffer *clone = [[LCTermBuffer allocWithZone: zone] init];
  [clone setTermBuffer: self];
  return clone;
}

@end
