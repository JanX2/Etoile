/*
    CKGroup.m
    Copyright (C) <2006> Yen-Ju Chen <gmail>
    Copyright (C) <2005> Bjoern Giesler <bjoern@giesler.de>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
   USA
*/


#import <CollectionKit/CKSearchElement.h>
#import <CollectionKit/CKMultiValue.h>

@interface CKEnvelopeSearchElement: CKSearchElement
{
  CKSearchConjunction _conj;
  NSArray *_children;
}

+ (CKSearchElement*) searchElementForConjunction: (CKSearchConjunction) conj
					children: (NSArray *) children;
- (id) initWithConjunction: (CKSearchConjunction) conj
                  children: (NSArray*) children;
- (void) dealloc;
- (BOOL) matchesRecord: (CKRecord *) record;
@end

@implementation CKEnvelopeSearchElement
+ (CKSearchElement*) searchElementForConjunction: (CKSearchConjunction) conj
					children: (NSArray*) children
{
  return AUTORELEASE([[self alloc] initWithConjunction: conj children: children]);
}

- (id) initWithConjunction: (CKSearchConjunction) conj
                  children: (NSArray *) children
{
  self = [super init];

  _conj = conj;
  ASSIGN(_children, AUTORELEASE([[NSArray alloc] initWithArray: children]));

  return self;
}

- (void) dealloc
{	     
  DESTROY(_children);
  [super dealloc];
}

- (BOOL) matchesRecord: (CKRecord*) record
{
  NSEnumerator *e;
  CKSearchElement *s;

  e = [_children objectEnumerator];

  while((s = [e nextObject]))
    {
      BOOL retval = [s matchesRecord: record];
      if(retval && (_conj == CKSearchOr))
	return YES;
      else if(!retval && (_conj == CKSearchAnd))
	return NO;
    }

  if (_conj == CKSearchOr) 
    return NO;
  else 
    return YES;
}
@end

@implementation CKRecordSearchElement
- (id) initWithProperty: (NSString*) property
                  label: (NSString*) label
                    key: (NSString*) key
                  value: (id) value
             comparison: (CKSearchComparison) comparison
{
  self = [super init];
  
  if(!property || !value)
    {
      NSLog(@"%@ initialized with nil property or value!\n", [self className]);
      return nil;
    }

  ASSIGNCOPY(_property, property);

  if (label)
    ASSIGNCOPY(_label, label);
  else 
    _label = nil;

  if (key)
    ASSIGNCOPY(_key, key);
  else
    _key = nil;

  ASSIGN(_val, value); 
  _comp = comparison;

  return self;
}

- (void) dealloc
{
  DESTROY(_property);
  DESTROY(_label);
  DESTROY(_key);
  DESTROY(_val);
  [super dealloc];
}

- (BOOL) matchesValue: (id) value
{
  if([value isKindOfClass: [NSString class]])
    {
      NSString *v = (NSString *) value;
      NSRange r;
      
      if(![_val isKindOfClass: [NSString class]])
	{
	  NSLog(@"Can't compare %@ instance to %@ instance\n",
		[v className], [_val className]);
	  return NO;
	}
  
      switch(_comp)
	{
	case CKEqual:
	  return [v isEqualToString: _val];
	case CKNotEqual:
	  return ![v isEqualToString: _val];
	case CKLessThan:
	  return [v compare: _val] < NSOrderedSame;
	case CKLessThanOrEqual:
	  return [v compare: _val] <= NSOrderedSame;
	case CKGreaterThan:
	  return [v compare: _val] > NSOrderedSame;
	case CKGreaterThanOrEqual:
	  return [v compare: _val] >= NSOrderedSame;

	case CKEqualCaseInsensitive:
	  return [v caseInsensitiveCompare: _val] == NSOrderedSame;
	case CKContainsSubString:
	  return [v rangeOfString: _val].location != NSNotFound;
	case CKContainsSubStringCaseInsensitive:
	  r = [v rangeOfString: _val options: NSCaseInsensitiveSearch];
	  return r.location != NSNotFound;
	case CKPrefixMatch:
	  return [v rangeOfString: _val].location == 0;
	case CKPrefixMatchCaseInsensitive:
	  r = [v rangeOfString: _val options: NSCaseInsensitiveSearch];
	  return r.location == 0;
	default:
	  NSLog(@"Unknown search comparison %d\n", _comp);
	  return NO;
	}
    }
  else if([value isKindOfClass: [NSDate class]])
    {
      NSDate *v = (NSDate *)value;
      if(![_val isKindOfClass: [NSString class]])
	{
	  NSLog(@"Can't compare %@ instance to %@ instance\n",
		[v className], [_val className]);
	  return NO;
	}
  
      switch(_comp)
	{
	case CKEqual:
	  return [v isEqualToDate: _val];
	case CKNotEqual:
	  return ![v isEqualToDate: _val];
	case CKLessThan:
	  return [v earlierDate: _val] == v;
	case CKLessThanOrEqual:
	  return [v isEqualToDate: _val] || ([v earlierDate: _val] == v);
	case CKGreaterThan:
	  return [v laterDate: _val] == v;
	case CKGreaterThanOrEqual:
	  return [v isEqualToDate: _val] || ([v laterDate: _val] == v);

	case CKEqualCaseInsensitive:
	case CKContainsSubString:
	case CKContainsSubStringCaseInsensitive:
	case CKPrefixMatch:
	case CKPrefixMatchCaseInsensitive:
	  NSLog(@"Can't apply comparison %d to date objects\n", _comp);
	  return NO;
	default:
	  NSLog(@"Unknown search comparison %d\n", _comp);
	  return NO;
	}
    }
  else
    {
      NSLog(@"Can't test value of class %@ for match\n", [value className]);
      return NO;
    }
}
    

- (BOOL) matchesRecord: (CKRecord*) record
{
  int i; 
  
  id v = [record valueForProperty: _property];
  if(!v) return NO;

  if([v isKindOfClass: [CKMultiValue class]])
    {
      CKMultiValue *val = (CKMultiValue *)v;
      id v2;
      
      for(i=0; i<[val count]; i++)
	{
	  if(_label)
	    {
	      // Have a label? Then, only regard values with the label
	      if([[val labelAtIndex: i] isEqualToString: _label])
		v2 = [val valueAtIndex: i];
	      else
		v2 = nil;
	    }
	  else
	    v2 = [val valueAtIndex: i];

	  if(!v2) continue;
	  
	  if([v2 isKindOfClass: [NSDictionary class]])
	    {
	      NSDictionary *val2 = (NSDictionary *) v2;
	      if(_key)
		return [self matchesValue: [val2 objectForKey: _key]];
	      else
		{
		  NSEnumerator *e = [val2 objectEnumerator];
		  id v;
		  while((v = [e nextObject]))
		    if([self matchesValue: v])
		      return YES;
		  return NO;
		}
	    }
	  else
	    {
	      return [self matchesValue: v2];
	    }
	}
    }
  else
    {
      return [self matchesValue: v];
    }
  return NO; // make compiler happy
}
@end

@implementation CKSearchElement
+ (CKSearchElement*) searchElementForConjunction: (CKSearchConjunction) conj
					children: (NSArray*) children
{
  return AUTORELEASE([[CKEnvelopeSearchElement alloc]
                                          initWithConjunction: conj
                                                     children: children]);
}

- (BOOL) matchesRecord: (CKRecord *) record
{
  [self subclassResponsibility: _cmd];
  return NO;
}
@end

