/*
**  NSString+Extensions.m
**
**  Copyright (c) 2001-2007
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#include <Pantomime/NSString+Extensions.h>

#include <Pantomime/CWCharset.h>
#include <Pantomime/CWConstants.h>
#include <Pantomime/CWInternetAddress.h>
#include <Pantomime/CWPart.h>
#include <Pantomime/NSData+Extensions.h>

#include <Foundation/NSBundle.h>

//
// We include the CoreFoundation headers under Mac OS X so we can support
// more string encodings.
//
#ifdef MACOSX
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFStringEncodingExt.h>
#else
#include <GNUstepBase/GSCategories.h>
#endif

#include <ctype.h>

#ifdef HAVE_ICONV
#include <iconv.h>
#endif

#define IS_PRINTABLE(c) (isascii(c) && isprint(c))

//
//
//
@implementation NSString (PantomimeStringExtensions)

#ifdef MACOSX
- (NSString *) stringByTrimmingWhiteSpaces
{
  NSMutableString *aMutableString;

  aMutableString = [[NSMutableString alloc] initWithString: self];
  CFStringTrimWhitespace((CFMutableStringRef)aMutableString);
  
  return AUTORELEASE(aMutableString);
}
#endif


//
//
//
- (int) indexOfCharacter: (unichar) theCharacter
{
  return [self indexOfCharacter: theCharacter  fromIndex: 0];
}


//
//
//
- (int) indexOfCharacter: (unichar) theCharacter
               fromIndex: (unsigned int) theIndex
{
  int i, len;
  
  len = [self length];
  
  for (i = theIndex; i < len; i++)
    {
      if ([self characterAtIndex: i] == theCharacter)
	{
	  return i;
	}
    }
  
  return -1;
}


//
//
//
- (BOOL) hasCaseInsensitivePrefix: (NSString *) thePrefix
{
  if (thePrefix)
    {
      return [[self uppercaseString] hasPrefix: [thePrefix uppercaseString]];
    }
  
  return NO;
}


//
//
//
- (BOOL) hasCaseInsensitiveSuffix: (NSString *) theSuffix
{
  if (theSuffix)
    {
      return [[self uppercaseString] hasSuffix: [theSuffix uppercaseString]];
    }
  
  return NO;
}


//
//
//
- (NSString *) stringFromQuotedString
{
  int len;

  len = [self length];
  
  if (len > 1 &&
      [self characterAtIndex: 0] == '"' &&
      [self characterAtIndex: (len-1)] == '"')
    {
      return [self substringWithRange: NSMakeRange(1, len-2)];
    }
  
  return self;
}


//
//
//
+ (NSString *) stringValueOfTransferEncoding: (int) theEncoding
{
  switch (theEncoding)
    {
    case PantomimeEncodingNone:
      break;
    case PantomimeEncodingQuotedPrintable:
      return @"quoted-printable";
    case PantomimeEncodingBase64:
      return @"base64";
    case PantomimeEncoding8bit:
      return @"8bit";
    case PantomimeEncodingBinary:
      return @"binary";
    default:
      break;
    }

  // PantomimeEncoding7bit will also fall back here.
  return @"7bit";
}

//
//
//
+ (int) encodingForCharset: (NSData *) theCharset
{
  return [self encodingForCharset: theCharset convertToNSStringEncoding: YES];
}

//
// Convenience to be able to use CoreFoundation conversion instead of NSString
//
+ (int) encodingForCharset: (NSData *) theCharset
 convertToNSStringEncoding: (BOOL) shouldConvert
{
  // We define some aliases for the string encoding.
  static struct { NSString *name; int encoding; BOOL fromCoreFoundation; } encodings[] = {
    {@"ascii"         ,NSASCIIStringEncoding          ,NO},
    {@"us-ascii"      ,NSASCIIStringEncoding          ,NO},
    {@"default"       ,NSASCIIStringEncoding          ,NO},  // Ah... spammers.
    {@"utf-8"         ,NSUTF8StringEncoding           ,NO},
    {@"iso-8859-1"    ,NSISOLatin1StringEncoding      ,NO},
    {@"x-user-defined",NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Outlook.
    {@"unknown"       ,NSISOLatin1StringEncoding      ,NO},  // Once more, blame Outlook.
    {@"x-unknown"     ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Pine 4.21.
    {@"unknown-8bit"  ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Mutt/1.3.28i
    {@"0"             ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in QUALCOMM Windows Eudora Version 6.0.1.1
    {@""              ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Ximian Evolution
    {@"iso8859_1"     ,NSISOLatin1StringEncoding      ,NO},  // To prevent a lame bug in Openwave WebEngine
    {@"iso-8859-2"    ,NSISOLatin2StringEncoding      ,NO},
#ifndef MACOSX
    {@"iso-8859-3"   ,NSISOLatin3StringEncoding                 ,NO},
    {@"iso-8859-4"   ,NSISOLatin4StringEncoding                 ,NO},
    {@"iso-8859-5"   ,NSISOCyrillicStringEncoding               ,NO},
    {@"iso-8859-6"   ,NSISOArabicStringEncoding                 ,NO},
    {@"iso-8859-7"   ,NSISOGreekStringEncoding                  ,NO},
    {@"iso-8859-8"   ,NSISOHebrewStringEncoding                 ,NO},
    {@"iso-8859-9"   ,NSISOLatin5StringEncoding                 ,NO},
    {@"iso-8859-10"  ,NSISOLatin6StringEncoding                 ,NO},
    {@"iso-8859-11"  ,NSISOThaiStringEncoding                   ,NO},
    {@"iso-8859-13"  ,NSISOLatin7StringEncoding                 ,NO},
    {@"iso-8859-14"  ,NSISOLatin8StringEncoding                 ,NO},
    {@"iso-8859-15"  ,NSISOLatin9StringEncoding                 ,NO},
    {@"koi8-r"       ,NSKOI8RStringEncoding                     ,NO},
    {@"big5"         ,NSBIG5StringEncoding                      ,NO},
    {@"gb2312"       ,NSGB2312StringEncoding                    ,NO},
    {@"utf-7"        ,NSUTF7StringEncoding                      ,NO},
    {@"unicode-1-1-utf-7", NSUTF7StringEncoding                 ,NO},  // To prever a bug (sort of) in MS Hotmail
#endif
    {@"windows-1250" ,NSWindowsCP1250StringEncoding             ,NO},
    {@"windows-1251" ,NSWindowsCP1251StringEncoding             ,NO},
    {@"cyrillic (windows-1251)", NSWindowsCP1251StringEncoding  ,NO},  // To prevent a bug in MS Hotmail
    {@"windows-1252" ,NSWindowsCP1252StringEncoding             ,NO},
    {@"windows-1253" ,NSWindowsCP1253StringEncoding             ,NO},
    {@"windows-1254" ,NSWindowsCP1254StringEncoding             ,NO},
    {@"iso-2022-jp"  ,NSISO2022JPStringEncoding                 ,NO},
    {@"euc-jp"       ,NSJapaneseEUCStringEncoding               ,NO},
  };
  
  NSString *name;
  int i;

  name = [[NSString stringWithCString: [theCharset bytes] length: [theCharset length]] lowercaseString];
  
  for (i = 0; i < sizeof(encodings)/sizeof(encodings[0]); i++)
    {
      if ([name isEqualToString: encodings[i].name])
        {
          int enc = encodings[i].encoding;
          // Under OS X, we use CoreFoundation if necessary to convert the encoding
          // to a NSString encoding.
#ifdef MACOSX
          if (encodings[i].fromCoreFoundation)
            {
              if (shouldConvert)
		{
		  return CFStringConvertEncodingToNSStringEncoding(enc);
		}
	      else
		{
		  return enc;
		}
	    }
          else
            {
              if (!shouldConvert)
		{
		  return CFStringConvertNSStringEncodingToEncoding(enc);
		}
              else
		{
		  return enc;
		}
	    }
#else
          return enc;
#endif
        }
    }
  
#ifdef MACOSX
  // Last resort: try using CoreFoundation...
  CFStringEncoding enc;
  
  enc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)name);
  if (kCFStringEncodingInvalidId != enc)
    {
      if (shouldConvert)
	{
	  return CFStringConvertEncodingToNSStringEncoding(enc);
	}
      else
	{
	  return enc;
	}
    }
#endif
  
  return -1;
}

//
//
//
+ (int) encodingForPart: (CWPart *) thePart
{
  return [self encodingForPart: thePart convertToNSStringEncoding: YES];
}

//
// Convenience to be able to use CoreFoundation conversion instead of NSString
//
+ (int)    encodingForPart: (CWPart *) thePart
 convertToNSStringEncoding: (BOOL) shouldConvert
{
  int encoding;
  
  // We get the encoding we are gonna use. We always favor the default encoding.
  encoding = -1;
  
  if ([thePart defaultCharset])
    {
      encoding = [self encodingForCharset: [[thePart defaultCharset] dataUsingEncoding: NSASCIIStringEncoding]
		       convertToNSStringEncoding: shouldConvert];
    }
  else if ([thePart charset])
    {
      encoding = [self encodingForCharset: [[thePart charset] dataUsingEncoding: NSASCIIStringEncoding]
		       convertToNSStringEncoding: shouldConvert];
    }
  else
    {
      encoding = [NSString defaultCStringEncoding];
    }
  
  if (encoding == -1 || encoding == NSASCIIStringEncoding)
    {
      encoding = NSISOLatin1StringEncoding;
    }
  
  return encoding;
}


//
//
//
+ (NSString *) stringWithData: (NSData *) theData
                      charset: (NSData *) theCharset
{
  int encoding;
  
  if (theData == nil)
    {
      return nil;
    }
  
#ifdef MACOSX
  encoding = [NSString encodingForCharset: theCharset
                convertToNSStringEncoding: NO];
#else
  encoding = [NSString encodingForCharset: theCharset];
#endif

  if (encoding == -1)
    {
#ifdef HAVE_ICONV
      NSString *aString;

      const char *i_bytes, *from_code;
      char *o_bytes;

      size_t i_length, o_length;
      int total_length, ret;
      iconv_t conv;
      
      // Instead of calling cString directly on theCharset, we first try
      // to obtain the ASCII string of the data object.
      from_code = [[theCharset asciiString] cString];
      
      if (!from_code)
	{
	  return nil;
	}
      
      conv = iconv_open("UTF-8", from_code);
      
      if ((int)conv < 0)
	{
	  // Let's assume we got US-ASCII here.
	  return AUTORELEASE([[NSString alloc] initWithData: theData  encoding: NSASCIIStringEncoding]);
	}
      
      i_bytes = [theData bytes];
      i_length = [theData length];
      
      total_length = o_length = sizeof(unichar)*i_length;
      o_bytes = (char *)malloc(o_length);
      
      if (o_bytes == NULL) return nil;

      while (i_length > 0)
	{
	  ret = iconv(conv, (char **)&i_bytes, &i_length, &o_bytes, &o_length);
	  
	  if (ret == (size_t)-1)
	    {
	      iconv_close(conv);
	      
	      total_length = total_length - o_length;
	      o_bytes -= total_length;
	      free(o_bytes);
	      return nil;
	    }
	}
      
      total_length = total_length - o_length;
      o_bytes -= total_length;
      
      // If we haven't used all our allocated buffer, we shrink it.
      if (o_length > 0)
	{
	  realloc(o_bytes, total_length);
	}
      
      aString = [[NSString alloc] initWithData: [NSData dataWithBytesNoCopy: o_bytes
							length: total_length]
				  encoding: NSUTF8StringEncoding];
      iconv_close(conv);
      
      return AUTORELEASE(aString);
#else
      return nil;
#endif
    }

#ifdef MACOSX
  return AUTORELEASE((NSString *)CFStringCreateFromExternalRepresentation(NULL, (CFDataRef)theData, encoding));
#else
  return AUTORELEASE([[NSString alloc] initWithData: theData  encoding: encoding]);
#endif
}


//
//
//
#warning return Charset instead?
- (NSString *) charset
{
  NSMutableArray *aMutableArray;
  NSString *aString;
  CWCharset *aCharset;

  unsigned int i, j;

  aMutableArray = [[NSMutableArray alloc] initWithCapacity: 21];

  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-1"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-2"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-3"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-4"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-5"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-6"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-7"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-8"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-9"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-10"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-11"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-13"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-14"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"iso-8859-15"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"koi8-r"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"koi8-u"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1250"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1251"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1252"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1253"]];
  [aMutableArray addObject: [CWCharset charsetForName: @"windows-1254"]];


  for (i = 0; i < [self length]; i++)
    {
      for (j = 0; j < [aMutableArray count]; j++)
        {
          if (![[aMutableArray objectAtIndex: j] characterIsInCharset: [self characterAtIndex: i]])
            {
              // Character is not in the charset
              [aMutableArray removeObjectAtIndex: j];
              j--;
            }
        }

      // FIXME: can't break even if there is only one left. First we have to check
      //        whether that encoding will actually work for the entire string. If it
      //	doesn't we'll need to fall back to utf-8 (or something else that can encode
      //        _everything_).
      // 
      // Intelligent string splitting would help, of course
      //
      if ([aMutableArray count] < 1)
        {
          // We have zero or one charset
          break;
        }
    }

  if ([aMutableArray count])
    {
      aCharset = [aMutableArray objectAtIndex: 0];
      [aMutableArray removeAllObjects];
      aString = [aCharset name];
    }
  else
    {
      // We have no charset, we try to "guess" a default charset
      if ([self canBeConvertedToEncoding: NSISO2022JPStringEncoding])
	{      
	  // ISO-2022-JP is the standard of Japanese character encoding
	  aString = @"iso-2022-jp";
	}
      else
	{ 
	  // We have no charset, we return a default charset
	  aString = @"utf-8";
	}
    }

  RELEASE(aMutableArray);
  
  return aString;
}


//
//
//
- (NSString *) modifiedUTF7String
{
#ifndef MACOSX
  NSMutableData *aMutableData, *modifiedData;
  NSString *aString;

  const char *b;
  BOOL escaped;
  unichar ch;
  int i, len;

  //
  // We UTF-7 encode _only_ the non-ASCII parts.
  //
  aMutableData = [[NSMutableData alloc] init];
  AUTORELEASE(aMutableData);
  len = [self length];
  
  for (i = 0; i < len; i++)
    {
      ch = [self characterAtIndex: i];
      
      if (IS_PRINTABLE(ch))
	{
	  [aMutableData appendCFormat: @"%c", ch];
	}
      else
	{
	  int j;

	  j = i+1;
	  // We got a non-ASCII character, let's get the substring and encode it using UTF-7.
	  while (j < len && !IS_PRINTABLE([self characterAtIndex: j]))
	    {
	      j++;
	    }
	  
	  // Get the substring.
	  [aMutableData appendData: [[self substringWithRange: NSMakeRange(i,j-i)] dataUsingEncoding: NSUTF7StringEncoding]];
	  i = j-1;
	}
    }

  b = [aMutableData bytes];
  len = [aMutableData length];
  escaped = NO;

  //
  // We replace:
  //
  // &   ->  &-
  // +   ->  &
  // +-  ->  +
  // /   ->  ,
  //
  // in order to produce our modified UTF-7 string.
  //
  modifiedData = [[NSMutableData alloc] init];
  AUTORELEASE(modifiedData);

  for (i = 0; i < len; i++, b++)
    {
      if (!escaped && *b == '&')
	{
	  [modifiedData appendCString: "&-"];
	}
      else if (!escaped && *b == '+')
	{
	  if (*(b+1) == '-')
	    {
	      [modifiedData appendCString: "+"];
	    }
	  else
	    {
	      [modifiedData appendCString: "&"];

	      // We enter the escaped mode.
	      escaped = YES;
	    }
	}
      else if (escaped && *b == '/')
	{
	  [modifiedData appendCString: ","];
	}
      else if (escaped && *b == '-')
	{
	  [modifiedData appendCString: "-"];

	  // We leave the escaped mode.
	  escaped = NO;
	}
      else
	{
	  [modifiedData appendCFormat: @"%c", *b];
	}
    }
  
  // If we're still in the escaped mode we haven't added our trailing -,
  // let's add it right now.
  if (escaped)
    {
      [modifiedData appendCString: "-"];
    }

  aString = AUTORELEASE([[NSString alloc] initWithData: modifiedData  encoding: NSASCIIStringEncoding]);

  return (aString != nil ? aString : self);
#else
  return self;
#endif
}

//
//
//
- (NSString *) stringFromModifiedUTF7
{
#ifndef MACOSX
  NSMutableData *aMutableData;

  BOOL escaped;
  unichar ch;
  int i, len;

  aMutableData = [[NSMutableData alloc] init];
  AUTORELEASE(aMutableData);

  len = [self length];
  escaped = NO;

  //
  // We replace:
  //
  // &   ->  +
  // &-  ->  &
  // ,   ->  /
  //
  // If we are in escaped mode. That is, between a &....-
  //
  for (i = 0; i < len; i++)
    {
      ch = [self characterAtIndex: i];
      
      if (!escaped && ch == '&')
	{
	  if ( (i+1) < len && [self characterAtIndex: (i+1)] != '-' )
	    {
	      [aMutableData appendCString: "+"];
	      
	      // We enter the escaped mode.
	      escaped = YES;
	    }
	  else
	    {
	      // We replace &- by &
	      [aMutableData appendCString: "&"];
	      i++;
	    }
	}
      else if (escaped && ch == ',')
	{
	  [aMutableData appendCString: "/"];
	}
      else if (escaped && ch == '-')
	{
	  [aMutableData appendCString: "-"];

	  // We leave the escaped mode.
	  escaped = NO;
	}
      else
	{
	  [aMutableData appendCFormat: @"%c", ch];
	}
    }

  return AUTORELEASE([[NSString alloc] initWithData: aMutableData  encoding: NSUTF7StringEncoding]);
#else
  return nil;
#endif
}


//
//
//
- (BOOL) hasREPrefix
{
  if ([self hasCaseInsensitivePrefix: @"re:"] ||
      [self hasCaseInsensitivePrefix: @"re :"] ||
      [self hasCaseInsensitivePrefix: _(@"PantomimeReferencePrefix")] ||
      [self hasCaseInsensitivePrefix: _(@"PantomimeResponsePrefix")])
    {
      return YES;
    }
  
  return NO;
}



//
//
//
- (NSString *) stringByReplacingOccurrencesOfCharacter: (unichar) theTarget
                                         withCharacter: (unichar) theReplacement
{
  NSMutableString *aMutableString;
  int len, i;
  unichar c;

  if (!theTarget || !theReplacement || theTarget == theReplacement)
    {
      return self;
    }

  len = [self length];
  
  aMutableString = [NSMutableString stringWithCapacity: len];

  for (i = 0; i < len; i++)
    {
      c = [self characterAtIndex: i];
      
      if (c == theTarget)
	{
	  [aMutableString appendFormat: @"%c", theReplacement];
	}
      else
	{
	  [aMutableString appendFormat: @"%c", c];
	}
    }

  return aMutableString;
}

//
//
//
- (NSString *) stringByDeletingLastPathComponentWithSeparator: (unsigned char) theSeparator
{
  int i, c;
  
  c = [self length];

  for (i = c-1; i >= 0; i--)
    {
      if ([self characterAtIndex: i] == theSeparator)
	{
	  return [self substringToIndex: i];
	}
    }

  return @"";
}

//
// 
//
- (NSString *) stringByDeletingFirstPathSeparator: (unsigned char) theSeparator
{
  if ([self length] && [self characterAtIndex: 0] == theSeparator)
    {
      return [self substringFromIndex: 1];
    }
  
  return self;
}

//
//
//
- (BOOL) is7bitSafe
{
  int i, len;
  
  // We search for a non-ASCII character.
  len = [self length];
  
  for (i = 0; i < len; i++)
    {
      if ([self characterAtIndex: i] > 0x007E)
	{
	  return NO;
	}
    }
  
  return YES;
}

//
//
//
- (NSData *) dataUsingEncodingFromPart: (CWPart *) thePart
{
  return [self dataUsingEncodingFromPart: thePart  allowLossyConversion: NO];
}

//
//
//
- (NSData *) dataUsingEncodingFromPart: (CWPart *) thePart
                  allowLossyConversion: (BOOL) lossy
{
#ifdef MACOSX
  // Use the CF decoding to get the data, bypassing Foundation...
  CFStringEncoding enc;
  NSData *data;
  
  enc = [isa encodingForPart: thePart convertToNSStringEncoding: NO];
  data = (NSData *)CFStringCreateExternalRepresentation(NULL, (CFStringRef)self,
							enc, (lossy) ? '?' : 0);
  return [data autorelease];
#else
  return [self dataUsingEncoding: [isa encodingForPart: thePart]
	       allowLossyConversion: lossy];
#endif
}


//
//
//
- (NSData *) dataUsingEncodingWithCharset: (NSString *) theCharset
{
  return [self dataUsingEncodingWithCharset: theCharset  allowLossyConversion: NO];
}


//
//
//
- (NSData *) dataUsingEncodingWithCharset: (NSString *) theCharset
                     allowLossyConversion: (BOOL)lossy
{
#ifdef MACOSX
  // Use the CF decoding to get the data, bypassing Foundation...
  CFStringEncoding enc;
  NSData *data;
  
  enc = [isa encodingForCharset: [theCharset dataUsingEncoding: NSASCIIStringEncoding]
	     convertToNSStringEncoding: NO];
  data = (NSData *)CFStringCreateExternalRepresentation(NULL, (CFStringRef)self,
							enc, (lossy) ? '?' : 0);
  return [data autorelease];
#else
  return [self dataUsingEncoding: [isa encodingForCharset: [theCharset dataUsingEncoding: NSASCIIStringEncoding]]
	       allowLossyConversion: lossy];
#endif
}


//
//
//
+ (NSString *) stringFromRecipients: (NSArray *) theRecipients
			       type: (PantomimeRecipientType) theRecipientType
{
  CWInternetAddress *anInternetAddress;
  NSMutableString *aMutableString;
  int i, count;
  
  aMutableString = [[NSMutableString alloc] init];
  count = [theRecipients count];

  for (i = 0; i < count; i++)
    {
      anInternetAddress = [theRecipients objectAtIndex: i];
      
      if ([anInternetAddress type] == theRecipientType)
	{
	  [aMutableString appendFormat: @"%@, ", [anInternetAddress stringValue]];
	}
    }
  
  return AUTORELEASE(aMutableString); 
}

@end
