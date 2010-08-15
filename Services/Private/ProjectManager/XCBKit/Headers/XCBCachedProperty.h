/*
 * Étoilé ProjectManager - XCBProperty.h
 *
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import <EtoileFoundation/EtoileFoundation.h>
#import <XCBKit/XCBConnection.h>

/**
  * This exception is thrown when a type conversion method
  * on [XCBCachedProperty] (such as -[XCBCachedProperty asText])
  * is called, but the cached data is not of that type.
  */
extern const NSString* XCBInvalidTypeException;

@interface XCBCachedProperty : NSObject
{
	NSString *propertyName;
	NSData *propertyData;
	xcb_atom_t type;
	uint8_t format;
	uint32_t format_length;
	uint32_t bytes_after;
}

- (id)initWithGetPropertyReply: (xcb_get_property_reply_t*)reply
                  propertyName: (NSString*)name;
- (void)dealloc;
- (NSString*)propertyName;
- (xcb_atom_t)type;
- (uint8_t)format;
- (uint32_t)lengthInFormatUnits;
- (NSData*)data;
- (BOOL)isEmpty;

- (uint8_t*)asBytes;
- (uint16_t*)asShorts;
- (uint32_t*)asLongs;
- (xcb_atom_t)asAtom;
- (NSArray*)asAtomArray;

/**
  * Check if the atom is of the specified
  * expectedType, and throws an XCBInvalidTypeException
  * if it is not.
  */
- (void)checkAtomType: (NSString*)expectedType;

/**
  * Return the cached property as
  * a STRING type
  */
- (NSString*)asString;
@end
