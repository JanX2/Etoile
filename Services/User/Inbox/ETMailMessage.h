/** <title>ETMailMessage.h</title>
 
	<abstract></abstract>
	
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  09-09-13
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <Pantomime/Pantomime.h>
#import "ETMessage.h"

@interface ETMailMessage : ETMessage
{
	CWMessage *_message;
}

+ (ETMailMessage *)messageWithCWMessage: (CWMessage *)message;

- (id)initWithCWMessage: (CWMessage *)message;

@end
