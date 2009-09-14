/** <title>ETMailFolder.h</title>
 
	<abstract></abstract>
	
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  09-09-13
	License: Modified BSD (see COPYING)
 */

#import <Pantomime/Pantomime.h>
#import <EtoileFoundation/EtoileFoundation.h>


@interface ETMailFolder : NSObject <ETCollection>
{
	CWFolder *_folder;
	CWService *_service;
	NSString *_name;
	NSArray *_messages;
}

+ (ETMailFolder *)folderWithName: (NSString *)name service: (CWService *)service;

- (id)initWithName: (NSString *)name service: (CWService *)service;

- (NSString *)name;

- (void)setMessages: (NSArray *)messages;

@end
