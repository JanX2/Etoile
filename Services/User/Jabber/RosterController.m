//
//  RosterController.m
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "RosterController.h"
#import "RosterGroup.h"
#import "JabberPerson.h"
#import "JabberIdentity.h"
#import "JabberApp.h"
#import "CustomPresenceWindowController.h"
#import "Conversation.h"
#import "TRUserDefaults.h"
#import "MessageWindowController.h"

#define AUTO_RESIZE

#ifdef NO_ATTRIBUTED_TITLES
#define setAttributedTitle(x) setTitle:[x string]
#else
#define setAttributedTitle(x) setAttributedTitle:x
#endif

//Don't animate the window on GNUstep; it breaks
#ifdef GNUSTEP
#define ANIMATE_WINDOW NO
#else
#define ANIMATE_WINDOW YES
#endif

#ifdef AUTO_RESIZE
#define RESIZE_ROSTER [[self window] setFrame:[self optimalSize] display:YES animate:ANIMATE_WINDOW]
#else
#define RESIZE_ROSTER
#endif

NSMutableArray * rosterControllers = nil;

@implementation RosterController

+ (id) alloc
{
	if(rosterControllers == nil)
	{
		rosterControllers = [[NSMutableArray alloc] init];
	}
	id rosterController = [super alloc];
	if(rosterController != nil)
	{
		[rosterControllers addObject:rosterController];
	}
	return rosterController;
}

#ifdef GNUSTEP
- (void)windowDidLoad
{
	[super windowDidLoad];
	[view setHeaderView: nil];
	[view setCornerView: nil];
	[[self window] setShowsResizeIndicator:YES];
}
#endif

- (void) redraw:(NSNotification*)_notification
{
	NSString * title;
	NSMutableAttributedString * colouredTitle;
	title = [[[presenceBox menu] itemAtIndex:0] title];
	NSDictionary * colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_CHAT] 
														forKey:NSForegroundColorAttributeName];
	colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
														   attributes:colour];
	[[[presenceBox menu] itemAtIndex:0] setAttributedTitle(colouredTitle)];
	[colouredTitle release];

	title = [[[presenceBox menu] itemAtIndex:1] title];
	colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_ONLINE]
										 forKey:NSForegroundColorAttributeName];
	colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
														   attributes:colour];
	[[[presenceBox menu] itemAtIndex:1] setAttributedTitle(colouredTitle)];
	[colouredTitle release];
	
	title = [[[presenceBox menu] itemAtIndex:2] title];
	colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_AWAY]
										 forKey:NSForegroundColorAttributeName];
	colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
														   attributes:colour];
	[[[presenceBox menu] itemAtIndex:2] setAttributedTitle(colouredTitle)];
	[colouredTitle release];
	
	title = [[[presenceBox menu] itemAtIndex:3] title];
	colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_XA] 
										 forKey:NSForegroundColorAttributeName];
	colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
														   attributes:colour];
	[[[presenceBox menu] itemAtIndex:3] setAttributedTitle(colouredTitle)];
	[colouredTitle release];
	
	title = [[[presenceBox menu] itemAtIndex:4] title];
	colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_DND] 
										 forKey:NSForegroundColorAttributeName];
	colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
														   attributes:colour];
	[[[presenceBox menu] itemAtIndex:4] setAttributedTitle(colouredTitle)];
	[colouredTitle release];
	
	title = [[[presenceBox menu] itemAtIndex:6] title];
	colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_OFFLINE] 
										 forKey:NSForegroundColorAttributeName];
	colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
														   attributes:colour];
	[[[presenceBox menu] itemAtIndex:6] setAttributedTitle(colouredTitle)];
	[colouredTitle release];
}

- (NSAttributedString*) displayStringForObject:(id)anObject
{
	NSMutableDictionary * attributes = [[NSMutableDictionary alloc] init];
	NSAttributedString * text = [NSAttributedString alloc];
	if([anObject isKindOfClass:[RosterGroup class]])
	{
		[text initWithString:[anObject groupName]];
	}
	else if([anObject isKindOfClass:[JabberPerson class]])
	{
		unsigned char onlineState = [[[anObject defaultIdentity] presence] show];
		NSColor * foreground = [[NSUserDefaults standardUserDefaults] colourForPresence:onlineState];
		if(foreground != nil)
		{
			[attributes setValue:foreground
						  forKey:NSForegroundColorAttributeName];
		}
		NSString * iconString = [NSString stringWithFormat:@"%C %@", 
			PRESENCE_ICONS[(onlineState / 10) - 1], 
			[(JabberPerson*)anObject name]];
		[[text initWithString:iconString attributes:attributes] autorelease];
	}
	else if([anObject isKindOfClass:[JabberIdentity class]])
	{
		NSColor * foreground = [[NSUserDefaults standardUserDefaults] colourForPresence:[[anObject presence] show]];
		if(foreground != nil)
		{
			[attributes setValue:foreground 
						  forKey:NSForegroundColorAttributeName];
		}
		[[text initWithString:[[anObject jid] jidString] attributes:attributes] autorelease];
	}
	else 
	{
		[text init];
	}
	[attributes release];
	return text;
}

- (float) widthOfItemAndChildren:(id) anObject withIndent:(float)anIndent
{
	NSAttributedString * attributedText= [self displayStringForObject:anObject];
	float myWidth = [attributedText size].width;
	for(unsigned int i=0 ; i<[self outlineView:view numberOfChildrenOfItem:anObject] ; i++)
	{
		attributedText = [self displayStringForObject:[self outlineView:view child:i ofItem:anObject]];
		float width = [attributedText size].width + anIndent;
		if(width > myWidth)
		{
			myWidth = width;
		}
	}
	return myWidth;
}

- (NSSize) calculateRosterSize;
{
	NSSize size;
	//Calculate width
	float interCellHorizontalSpacing = [view intercellSpacing].width;
	float indent = [view indentationPerLevel] + (4*interCellHorizontalSpacing);
	size.width = [self widthOfItemAndChildren:nil withIndent:indent];
	size.width += interCellHorizontalSpacing;
	[[[view tableColumns] objectAtIndex:0] setWidth:size.width];
	size.width += interCellHorizontalSpacing;

	//Calculate height
	size.height = [view numberOfRows] * ([view rowHeight] + [view intercellSpacing].height);
	return size;
}

- (void) subscriptionChanged:(NSNotification*)_notification
{
	if([[_notification name] isEqualToString:@"TRXMPPSubscriptionRequest"])
	{
		NSLog(@"Subscription request received");
		//TODO:  Ask permission first
		[data authorise:[(Presence*)[_notification object] jid]];
	}
}
- (void) presenceChanged:(NSNotification *)notification
{
	NSDictionary * dict = [notification userInfo];
	[self setPresence:[[dict objectForKey:@"show"] unsignedCharValue]
		  withMessage:[dict objectForKey:@"status"]];
}

- (id) initWithNibName:(NSString*)_nib forAccount:(id)_account withRoster:(id)_roster
{
	NSLog(@"Loading roster nib...");
	self = [self initWithWindowNibName:_nib];
	if(self == nil)
	{
		[self release];
		return nil;
	}
	NSNotificationCenter * defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
					  selector:@selector(updatePresence:)
						  name:@"TRXMPPPresenceChanged"
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(updateIdentities:)
						  name:@"TRXMPPIdentityPresenceChanged"
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(redraw:)
						  name:@"NSUserDefaultsDidChangeNotification"
						object:[NSUserDefaults standardUserDefaults]];
	[defaultCenter addObserver:self
					  selector:@selector(subscriptionChanged:)
						  name:@"TRXMPPSubscriptionRequest"
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(subscriptionChanged:)
						  name:@"TRXMPPSubscription"
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(subscriptionChanged:)
						  name:@"TRXMPPUnsubscriptionRequest"
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(subscriptionChanged:)
						  name:@"TRXMPPUnubscription"
						object:nil];
	
	
	[[self window] setFrameFromString:@"Jabber Roster"];
	[[self window] setFrameAutosaveName:@"Jabber Roster"];
	data = _roster;
	account = _account;
	//Note: nil must be changed to account if permitting multiple accounts
	NSNotificationCenter * localCenter = [NSNotificationCenter defaultCenter];
	[localCenter addObserver:self
					selector:@selector(presenceChanged:)
						name:@"LocalPresenceChangedNotification"
					  object:nil];	
	return self;
}
- (void) updateIdentities:(NSNotification*)_notification
{
	[self update:[_notification object]];
}

- (void) updatePresence:(NSNotification*)_notification
{
	unsigned char old = (unsigned char)[[[_notification userInfo] objectForKey:@"OldPresence"] intValue];
	unsigned char new = (unsigned char)[[[_notification userInfo] objectForKey:@"NewPresence"] intValue];
	if(old >= PRESENCE_OFFLINE && new < PRESENCE_OFFLINE)
	{
		[[[NSUserDefaults standardUserDefaults] soundForKey:@"OnlineSound"] play];
	}
	else if(old < PRESENCE_OFFLINE && new >= PRESENCE_OFFLINE)
	{
		[[[NSUserDefaults standardUserDefaults] soundForKey:@"OfflineSound"] play];
	}
	id changedObject = [_notification object];
	if([changedObject isKindOfClass:[JabberPerson class]])
	{
		unsigned int hiddenPresence = [[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"];
		RosterGroup * group = [[account roster] groupNamed:[changedObject group]];
		//If we making a group appear
		if(old >= hiddenPresence && 
		    [group numberOfPeopleInGroupMoreOnlineThan:hiddenPresence])
		{
			[self update:nil];
		}
		[self update:group];
	}
	[self update:[_notification object]];
}

- (NSRect)optimalSize
{
	NSRect windowFrameDimensions = [[self window] frame];
	float oldHeight = windowFrameDimensions.size.height;
	
	NSSize rosterSize = [self calculateRosterSize];
	
	windowFrameDimensions.size.height =  rosterSize.height + 
		(windowFrameDimensions.size.height - [[view superview] frame].size.height);
	
	windowFrameDimensions.size.width = rosterSize.width;
	
	NSSize minimumSize = [[self window] minSize];
	if(windowFrameDimensions.size.height < minimumSize.height)
	{
		windowFrameDimensions.size.height = minimumSize.height;
	}
	if(windowFrameDimensions.size.width < minimumSize.width)
	{
		windowFrameDimensions.size.width = minimumSize.width;
	}
	windowFrameDimensions.origin.y -= windowFrameDimensions.size.height - oldHeight;
	if(windowFrameDimensions.origin.y < 0)
	{
		windowFrameDimensions.origin.y = 0;
	}
	if(windowFrameDimensions.size.height > [[[self window] screen] visibleFrame].size.height)
	{
		windowFrameDimensions.size.height = [[[self window] screen] visibleFrame].size.height;
	}
	return windowFrameDimensions;
}

- (void) update:(id)_object
{
#ifdef GNUSTEP
	/* GNUSTEP BUG:
	 * [NSOutlineView -reloadItem] is badly broken on GNUstep.
	 * Remove this work-around when it is fixed.
	 */
	[view reloadData];
#else
	if(_object == nil)
	{
		[view reloadData];
	}
	else
	{
		[view reloadItem:_object reloadChildren:YES];
		//TODO:  Work out why I thought this crashed, and had it all commented out.
		if([view isItemExpanded:_object])
		{
			[view reloadItem:_object reloadChildren:YES];
		}
		else if([_object isKindOfClass:[RosterGroup class]] && 
				[[NSUserDefaults standardUserDefaults] expandedGroup:[_object groupName]])
		{
			if([view isExpandable:_object])
			{
				[view expandItem:_object];
			}
		}
	}
#endif
	/* These exception handlers were a work around for a now-fixed bug.
	 * They can probably be removed.
	 */
	RESIZE_ROSTER;
	NS_DURING
	[view display];
	NS_HANDLER
		NSLog(@"Exception while displaying roster: %@", [localException reason]);
	NS_ENDHANDLER
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	return [self optimalSize];
}

- (id) outlineView:(NSOutlineView *)_outlineView child:(int)_index ofItem:(id)_item
{
	if(_item == nil)
	{
		return [data groupForIndex:_index ignoringPeopleLessOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]];
	}
	if([_item isKindOfClass:[RosterGroup class]])
	{
		return [_item personAtIndex:_index];
	}
	if([_item isKindOfClass:[JabberPerson class]])
	{
		NSArray *list = [_item identityList];
		if ((_index > -1) && (_index < (int)[list count]))
			return [list objectAtIndex:_index];
	}	
	return nil;
}

- (NSString *)outlineView:(NSOutlineView *)ov
		   toolTipForCell:(NSCell *)cell
					 rect:(NSRectPointer)rect
			  tableColumn:(NSTableColumn *)tc
					 item:(id)item
			mouseLocation:(NSPoint)mouseLocation
{
	if([item isKindOfClass:[RosterGroup class]])
	{
		return [NSString stringWithFormat:@"%d/%d %@",
			[item numberOfPeopleInGroupMoreOnlineThan:PRESENCE_OFFLINE],
			[item numberOfPeopleInGroupMoreOnlineThan:PRESENCE_UNKNOWN + 10],
			[Presence displayStringForPresence:PRESENCE_ONLINE]];
	}
	NSString * toolTipMessage = nil;
	Presence * selectedPresence = nil;
	if([item isKindOfClass:[JabberPerson class]])
	{
		selectedPresence = [[(JabberPerson*)item defaultIdentity] presence];
	}
	else if([item isKindOfClass:[JabberIdentity class]])
	{
		selectedPresence = [(JabberIdentity*)item presence];
	}
	if(selectedPresence != nil)
	{
		toolTipMessage = [selectedPresence status];
		if(toolTipMessage == nil)
		{
			toolTipMessage = [Presence displayStringForPresence:[selectedPresence show]];
		}		
	}
	return toolTipMessage;
}

- (BOOL) outlineView:(NSOutlineView *)_outlineView isItemExpandable:(id)_item
{
	if(data == nil)
	{
		return NO;		
	}
	if([_item isKindOfClass:[RosterGroup class]])
	{
		if([_item numberOfPeopleInGroupMoreOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]] > 0)
		{
			return YES;			
		}
		else
		{
			return NO;
		}
	}
	if(_item == nil)
	{
		return YES;
	}
	if([_item isKindOfClass:[JabberPerson class]])
	{
		if([_item identities] > 1)
		{
			return YES;
		}
	}
	return NO;
}

- (int)outlineView:(NSOutlineView *)_outlineView numberOfChildrenOfItem:(id)_item
{
	//Root node.  Children are all groups
	if(_item == nil)
	{
		return [data numberOfGroupsContainingPeopleMoreOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]];
	}
	if([_item isKindOfClass:[RosterGroup class]])
	{
		return [_item numberOfPeopleInGroupMoreOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]];
	}
	if([_item isKindOfClass:[JabberPerson class]])
	{
		return [_item identities];
	}
	return 0;
}

- (void)outlineView:(NSOutlineView *)_outlineView willDisplayCell:(id)_cell forTableColumn:(NSTableColumn *)_tableColumn item:(id)_item
{
	if([_item isKindOfClass:[RosterGroup class]])
	{
		/* Nothing to change */
	}
	else if([_item isKindOfClass:[JabberPerson class]])
	{
		[_cell setAttributedStringValue:[self displayStringForObject:_item]];
	}
	else if([_item isKindOfClass:[JabberIdentity class]])
	{
		[_cell setAttributedStringValue:[self displayStringForObject:_item]];
	}
	else 
	{
		/* Nothing to change */
	}
}

- (id)outlineView:(NSOutlineView *)_outlineView objectValueForTableColumn:(NSTableColumn *)_tableColumn byItem:(id)_item
{
	if([_item isKindOfClass:[RosterGroup class]])
	{
		return [_item groupName];
	}
	else if([_item isKindOfClass:[JabberPerson class]])
	{
		return [(JabberPerson*)_item name];
	}
	else if([_item isKindOfClass:[JabberIdentity class]])
	{
		return [[_item jid] jidString];
	}
	else 
	{
		return @"Wrgon!";
	}
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	id group = [[notification userInfo] objectForKey:@"NSObject"];
	if([group isKindOfClass:[RosterGroup class]])
	{
		[[NSUserDefaults standardUserDefaults] setExpanded:[group groupName] to:YES];
	}
	RESIZE_ROSTER;
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	id group = [[notification userInfo] objectForKey:@"NSObject"];
	if([group isKindOfClass:[RosterGroup class]])
	{
		[[NSUserDefaults standardUserDefaults] setExpanded:[group groupName] to:NO];
	}
	RESIZE_ROSTER;
}

inline Conversation * createChatWithPerson(id self, JabberPerson* person, XMPPAccount * account)
{
	JID * destinationJID = [[person defaultIdentity] jid];
	Conversation * conversation = [Conversation conversationForPerson:person];
	if(conversation != nil)
	{
		[conversation setJID:destinationJID];
		[[conversation delegate] activate:self];
	}
	else
	{
		conversation = [[Conversation conversationWithPerson:person
												  forAccount:account]
			retain];
		
		MessageWindowController * chatWindow = [[MessageWindowController alloc] initWithWindowNibName:@"MessageWindow"];		
		[chatWindow conversation:conversation];
		[conversation setDelegate:chatWindow];
	}
	return conversation;
}

- (IBAction) click:(id)sender
{
	id item = [view itemAtRow:[view clickedRow]];
	if([item isKindOfClass:[JabberPerson class]])
	{
		createChatWithPerson(self,(JabberPerson*) item, account);
	}
	else if([item isKindOfClass:[JabberIdentity class]])
	{
		JID * destinationJID = [(JabberIdentity*)item jid];
		[createChatWithPerson(self, [data personForJID:destinationJID], account) setJID:destinationJID];
	}
}

- (IBAction) changePresence:(id)sender
{
	NSString * status = [statusBox stringValue];
	switch([presenceBox indexOfSelectedItem])
	{
		case 0:
			[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_CHAT withMessage:status];
			break;
		case 1:
			[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_ONLINE withMessage:status];
			break;
		case 2:
			[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_AWAY withMessage:status];
			break;
		case 3:
			[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_XA withMessage:status];
			break;
		case 4:
			[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_DND withMessage:status];
			break;
		case 6:
			[(JabberApp*)[NSApp delegate] setPresence:PRESENCE_OFFLINE withMessage:status];
			break;
		case 8:
			[(JabberApp*)[NSApp delegate] setCustomPresence:status];
			break;
	}
}

- (void) setPresence:(unsigned char)_status withMessage:(NSString*)_message
{
	if(_message == nil)
	{
		_message = [statusBox stringValue];
	}
	if(presence != _status)
	{
		presence = _status;
		[presenceBox selectItemWithTitle:[Presence displayStringForPresence:_status]];		
	}
	if(_message == nil)
	{
		_message = @"";
	}
	if(![[statusBox stringValue] isEqualToString:_message])
	{
		[statusBox setStringValue:_message];
	}	
	[statusBox setTextColor:PRESENCE_COLOUR(_status)];
}
/*- (void) update
{
	if([[self window] isZoomed])
	{
		[[self window] setFrame:[self windowWillUseStandardFrame:[self window] defaultFrame:NSMakeRect(0,0,0,0)] display:YES];
	}
}*/
- (NSString*) currentStatusMessage
{
	return [statusBox stringValue];
}

- (void) dealloc
{
	[rosterControllers removeObject:self];
	[[self window] close];
	[data release];
	[view release];
	[super dealloc];
}
@end
