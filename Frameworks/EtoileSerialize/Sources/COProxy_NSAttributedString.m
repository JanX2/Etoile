#import "ESProxy.h"

@interface COProxy_NSAttributedString : ESProxy {}
@end

#define P0(type, s1) - (type) s1 { return [object s1]; }
#define P1(type, s1, t1, a1) - (type) s1:(t1)a1 { return [object s1:a1]; }
#define P2(type, s1, t1, a1, s2, t2, a2) - (type) s1:(t1)a1 s2:(t2)a2 { return [object s1:a1 s2:a2]; }
#define P3(type, s1, t1, a1, s2, t2, a2, s3, t3, a3) - (type) s1:(t1)a1 s2:(t2)a2 s3:(t3)a3 { return [object s1:a1 s2:a2 s3:a3]; }
#define P4(type, s1, t1, a1, s2, t2, a2, s3, t3, a3, s4, t4, a4) - (type) s1:(t1)a1 s2:(t2)a2 s3:(t3)a3 s4:(t4)a4 { return [object s1:a1 s2:a2 s3:a3 s4:a4]; }
@implementation COProxy_NSAttributedString
P0(NSUInteger, length)
P0(NSString*, string)
P0(NSUInteger, _editCount)
P1(BOOL,isEqualToAttributedString,NSAttributedString*, otherString)
P2(NSDictionary *, attributesAtIndex, NSUInteger, index, effectiveRange, NSRangePointer, aRange)
P3(NSDictionary *, attribute, NSString *, attributeName, atIndex, NSUInteger, index, effectiveRange, NSRangePointer, aRange)
P3(NSDictionary *, attributesAtIndex, NSUInteger, index, longestEffectiveRange, NSRangePointer, aRange, inRange,NSRange,rangeLimit)
P4(NSDictionary *, attribute, NSString *, attributeName, atIndex, NSUInteger, index, longestEffectiveRange, NSRangePointer, aRange, inRange,  NSRange,rangeLimit)
@end
