//
//  MessageWindowController.m
//  Jabber
//
//  Created by David Chisnall on 18/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "MessageWindowController.h"
#import "Presence.h"
#import "TRUserDefaults.h"

NSMutableArray * messageWindowControllers = nil;

@implementation MessageWindowController

+ (void) initialize
{
	messageWindowControllers = [[NSMutableArray alloc] init];
}
+ (id) alloc
{
	id messageWindowController = [super alloc];
	if(messageWindowController != nil)
	{
		[messageWindowControllers addObject:messageWindowController];
	}
	return messageWindowController;
}

- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	hack = NO;
	unread = 0;
	return self;
}

- (void) resizeEditingBox:(id)_sender
{
	//Note:  The 2.0f may be cocoa-specific.
	NSSize editingBoxSize = [editingBox frame].size;
	NSSize editingBoxVisibleSize = [editingBoxBox frame].size;
	NSSize messageBoxSize = [messageBoxBox frame].size;
	NSRect windowSize = [[self window] frame];
	//Hack to get around the fact that Cocoa controls seem not to shrink by more than 2 pixels at a time, but will happily grow by as many as they need to.
	editingBoxSize.height = 1.0f;
	[editingBox setFrameSize:editingBoxSize];
	[editingBox sizeToFit];
	editingBoxSize = [editingBox frame].size;
	editingBoxSize.height += 3;
	//Resize the window
	float difference = editingBoxSize.height - editingBoxVisibleSize.height;
	if(difference != 0)
	{
		windowSize.size.height += difference;
		windowSize.origin.y -= difference;
		
		//Resize the NSScrollView and it's superview
		editingBoxSize.width = editingBoxVisibleSize.width;
		[editingBoxBox setFrameSize:editingBoxSize];
//		editingBoxSize.height += 2.0f;
//		[[[editingBox superview] setFrameSize:editingBoxSize];
		
		
		[messageBoxBox setFrameSize:messageBoxSize];
		
		//Redraw the window at the new size.
		hack = YES;
		[[self window] setFrame:windowSize display:YES animate:YES];
	}
}

- (void) awakeFromNib
{
	NSNotificationCenter * defaultCenter = [NSNotificationCenter defaultCenter];
	[editingBox setFieldEditor:YES];
	[editingBox setVerticallyResizable:YES];
	[defaultCenter addObserver:self
					   selector:@selector(redraw:)
						   name:@"NSUserDefaultsDidChangeNotification" 
						 object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(resizeEditingBox:)
						  name:@"NSTextDidChangeNotification"
						object:editingBox];
	[defaultCenter addObserver:self
					  selector:@selector(resizeWindow:)
						  name:@"NSWindowDidResizeNotification"
						object:[self window]];
	[[editingBox superview] setAutoresizesSubviews:YES];
	[self resizeEditingBox:self];
}

- (void) resizeWindow:(NSNotification*)notification
{
	if(hack)
	{
		hack = NO;
	}
	else
	{
		NSRect messageFrame = [messageBoxBox frame];
		NSRect editingFrame = [editingBoxBox frame];
		
		//	messageFrame.origin.y = [[[self window] contentView] bounds].size.height - 48;
		messageFrame.origin.y = editingFrame.origin.y + editingFrame.size.height + 8;
		messageFrame.size.height = [[[self window] contentView] bounds].size.height - messageFrame.origin.y - 48;
		[messageBoxBox setFrame:messageFrame];
		[[self window] displayIfNeeded];
	}
}

- (void) redraw:(NSNotification*)_notification
{
	[presenceBox setTextColor:[[NSUserDefaults standardUserDefaults] colourForPresence:presence]];
}

- (void) textDidEndEditing:(NSNotification *)aNotification
{
	if(![[editingBox string] isEqualToString:@""]
	   &&
	   [[[aNotification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
	{
		[conversation sendPlainText:[editingBox string]];
		[editingBox setString:@""];
		[self resizeEditingBox:self];
		[[self window] makeFirstResponder:editingBox];
		[messageBox display];
		[messageBox scrollRangeToVisible:NSMakeRange([[messageBox textStorage] length],0)];
	}
}


- (void) displayMessage:(Message*)_message incoming:(BOOL)_in
{
	if(_in)
	{
		if(![[self window] isVisible])
		{
			[self showWindow:self];
			[[[NSUserDefaults standardUserDefaults] soundForKey:@"MessageSound"] play];
			[[self window] setTitle:[NSString stringWithFormat:@"%@ (%d unread)", [conversation name], ++unread]];
		}
		if(![NSApp isActive])
		{
			if([[self window] canBecomeMainWindow])
			{
				[[self window] makeMainWindow];
			}
			[NSApp requestUserAttention:NSCriticalRequest];
			[[[NSUserDefaults standardUserDefaults] soundForKey:@"MessageSound"] play];
			[[self window] setTitle:[NSString stringWithFormat:@"%@ (%d unread)", [conversation name], ++unread]];
		}
		else if(![[self window] isMainWindow])
		{
			[[[NSUserDefaults standardUserDefaults] soundForKey:@"MessageSound"] play];
			[[self window] orderFront:self];
			[[self window] setTitle:[NSString stringWithFormat:@"%@ (%d unread)", [conversation name], ++unread]];
		}
	}
	[[messageBox textStorage] appendAttributedString:[log logMessage:_message]];
	[messageBox display];
	[messageBox scrollRangeToVisible:NSMakeRange([[messageBox textStorage] length],0)];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	unread = 0;
	[[self window] setTitle:[conversation name]];
}

- (void) activate:(id)_sender
{
	[self showWindow:_sender];
}

- (void) conversation:(id)_conversation
{
	[conversation release];
	conversation = _conversation;
	NSWindow * window = [self window];
	NSString * name = [conversation name];
	JID * jid = [conversation remoteJID];
	log = [[ChatLog chatLogWithPerson:[conversation remotePerson]] retain];
	[window setTitle:name];
	[window setFrameFromString:name];
	[window setFrameAutosaveName:name];
	[self showWindow:self];
	//Load and display log
	[[messageBox textStorage] appendAttributedString:[log getLogForToday]];
	[messageBox display];
	[messageBox scrollRangeToVisible:NSMakeRange([[messageBox textStorage] length],0)];
	//Set presence and current resource
	Presence * remotePresence = [[[conversation remotePerson] identityForJID:jid] presence];
	[self setPresence:[remotePresence show] withMessage:[remotePresence status]];
}

- (void) setPresence:(unsigned char)_status withMessage:(NSString*)_message
{
	presence = _status;
	NSString * statusString = [Presence displayStringForPresence:_status];
	if(_message != nil && ![statusString isEqualToString:_message])
	{
		[presenceBox setStringValue:[NSString stringWithFormat:@"%@: %@",statusString, _message]];
	}
	else
	{
		[presenceBox setStringValue:[Presence displayStringForPresence:_status]];
	}
	[presenceBox setTextColor:[[NSUserDefaults standardUserDefaults] colourForPresence:_status]];
	[presenceBox setToolTip:_message];
	//Set the available identities
	NSString * currentJID = [[recipientBox titleOfSelectedItem] retain];
	[recipientBox removeAllItems];
	NSArray * identities = [[conversation remotePerson] identityList];
	for(unsigned int i=0 ; i<[[conversation remotePerson] identities] ; i++)
	{
		JabberIdentity * identity =  [identities objectAtIndex:i];
		NSString * title = [[identity jid] jidString];
		NSMutableAttributedString * colouredTitle = [NSMutableAttributedString alloc];
		NSDictionary * colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:[[identity presence] show]]
														  forKey:NSForegroundColorAttributeName];

		[colouredTitle initWithString:title
						   attributes:colour];
		[recipientBox addItemWithTitle:title];
		[[[recipientBox menu] itemWithTitle:title] setAttributedTitle:colouredTitle];
		[colouredTitle release];
	}
	[recipientBox selectItemWithTitle:currentJID];
	[currentJID release];
}

- (BOOL) newRemoteJID:(JID*)jid
{
	if(![[jid jidString] isEqual:[recipientBox titleOfSelectedItem]])
	{
		[recipientBox selectItemWithTitle:[jid jidString]];
	}
	return YES;
}

- (Conversation*) conversation
{
	return conversation;
}

- (IBAction) changeRemoteJid:(id)sender
{
	[conversation setJID:[JID jidWithString:[recipientBox titleOfSelectedItem]]];
}

- (void) dealloc
{
	[messageWindowControllers removeObject:self];
	[super dealloc];
}
@end

