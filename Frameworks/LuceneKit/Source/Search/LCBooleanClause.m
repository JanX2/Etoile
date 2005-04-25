#include "Search/LCBooleanClause.h"
#include "Search/LCQuery.h"
#include "GNUstep/GNUstep.h"

@implementation LCBooleanClause
- (id) init
{
  self = [super init];
  occur = LCOccur_SHOULD;
  required = NO;
  prohibited = NO;
  return self;
}

- (id) initWithQuery: (LCQuery *) q
       require: (BOOL) r
       prohibited: (BOOL) p
{
  self = [self init];
  ASSIGN(query, q);
  required = r;
  prohibited = p;
  if (required) {
    if (prohibited) {
      occur = LCOccur_MUST_NOT;
    } else {
      occur = LCOccur_MUST;
    }
  } else {
    if (prohibited) {
      occur = LCOccur_MUST_NOT;
    } else {
      occur = LCOccur_SHOULD;
    }
  }
  return self;
}

- (id) initWithQuery: (LCQuery *) q
             occur: (LCOccurType) o
{
  self = [self init];
  ASSIGN(query, q);
  occur = o;
  [self setFields: occur];
  return self;
}

- (LCOccurType) occur { return occur; }
- (void) setOccur: (LCOccurType) o
{
  occur = o;
  [self setFields: occur];
}
- (NSString *) occurString
{
  switch (occur) {
    case LCOccur_MUST:
      return @"MUST";
    case LCOccur_SHOULD:
      return @"SHOULD";
    case LCOccur_MUST_NOT:
      return @"MUST_NOT";
    default:
      return nil;
  }
}

- (LCQuery *) query { return query; }
- (void) setQuery: (LCQuery *) q
{
  ASSIGN(query, q);
}

- (BOOL) isProhibited { return prohibited; }
- (BOOL) isRequired { return required; }
- (void) setFields: (LCOccurType) o
{
  switch(o) {
    case LCOccur_MUST:
      required = YES;
      prohibited = NO;
      break;
    case LCOccur_SHOULD:
      required = NO;
      prohibited = NO;
      break;
    case LCOccur_MUST_NOT:
      required = NO;
      prohibited = YES;
      break;
    default:
      NSLog(@"Unknown operator %@", [self occurString]);
      return;
  }
}

- (BOOL) isEqual: (id) o
{
  if ([o isKindOfClass: [self class]] == NO)
    return NO;
  LCBooleanClause *other = (LCBooleanClause *) o;
  if ([query isEqual: [other query]] &&
      (required == [other isRequired]) &&
      (prohibited == [other isProhibited]))
    return YES;
  else
    return NO;
}

- (unsigned) hash
{
  return [query hash] ^ (required ? 1 : 0) ^ (prohibited ? 2 : 0);
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@ %@", [self occurString], query];
}
@end
