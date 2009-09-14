/*
**  CWIMAPMessage.h
**
**  Copyright (c) 2001-2006
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

#ifndef _Pantomime_H_CWIMAPMessage
#define _Pantomime_H_CWIMAPMessage

#import <Foundation/NSCoder.h>

#include <Pantomime/CWMessage.h>

/*!
  @class CWIMAPMessage
  @discussion This class, which extends CWMessage, adds IMAP specific
              information and redefines the behavior of some methods
	      from its superclass.
*/
@interface CWIMAPMessage : CWMessage <NSCoding>
{
  @private
    BOOL _headers_were_prefetched;
    unsigned int _UID;
}

/*!
  @method UID
  @discussion This method is used to obtain the UID of a message.
              See 2.3.1.1. Unique Identifier (UID) Message Attribute
	      of RFC 3501 for a detailed description of the UID
	      attribute of a message.
  @result The UID, 0 if the receiver has no UID.
*/
- (unsigned int) UID;

/*!
  @method setUID:
  @discussion This method is used to set the UID of the receiver.
              Normally, you shouldn't invoke this method directly.
  @param theUID The UID of the message.
*/
- (void) setUID: (unsigned int) theUID;

/*!
  @method rawSource
  @discussion IMAP specific implementation of the rawSource method. This method
              is always non-blocking. It might return nil if the raw source of the
	      message hasn't yet been fetched from the IMAP server. The IMAPStore
	      notifies the delegate when the fetch has been completed.
  @result The raw source of the message, nil if not yet fully fetched.
*/
- (NSData *) rawSource;

/*!
  @method setFlags:
  @discussion This method overrides the one found in CWMessage.
              It will replace all the flags on the server
	      for this message with the flags specified in the argument.
  @param theFlags The new flags for the receiver.
*/
- (void) setFlags: (CWFlags *) theFlags;

@end

#endif // _Pantomime_H_CWIMAPMessage
