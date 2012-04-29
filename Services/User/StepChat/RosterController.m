//
//  RosterController.m
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <EtoileFoundation/EtoileFoundation.h>
#import <XMPPKit/XMPPRosterGroup.h>
#import <XMPPKit/XMPPPerson.h>
#import <XMPPKit/XMPPIdentity.h>
#import <XMPPKit/XMPPConversation.h>
#import "RosterController.h"
#import "JabberApp.h"
#import "CustomPresenceWindowController.h"
#import "TRUserDefaults.h"
#import "MessageWindowController.h"

#define AUTO_RESIZE

#ifdef NO_ATTRIBUTED_TITLES
#define setAttributedTitle(x) setTitle:[x string]
#else
#define setAttributedTitle(x) setAttributedTitle:x
#endif

//Don't animate the window on GNUstep; it breaks (Seems to work now.  Delete
//this if it doesn't break)
#ifdef GNUSTEP
#define ANIMATE_WINDOW YES
#else
#define ANIMATE_WINDOW YES
#endif

#ifdef AUTO_RESIZE
#define RESIZE_ROSTER [[self window] setFrame:[self optimalSize] display:YES animate:ANIMATE_WINDOW]
#else
#define RESIZE_ROSTER
#endif

#ifdef GNUSTEP
/* Ugly hack to fix a GNUstep bug */
/*@implementation NSOutlineView (UglyHack)
- (id)itemAtRow: (int)row
{
        if (row >= [_items count])
        {
                return [NSNull null];
        }
        return [_items objectAtIndex: row];
}
@end*/
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

- (void)windowDidLoad
{
        [super windowDidLoad];
        [view registerForDraggedTypes:A(@"XMPPPerson",@"XMPPIdentity")];
#ifdef GNUSTEP
        [view setHeaderView: nil];
        [view setCornerView: nil];
        avatarColumn= [[view tableColumns] objectAtIndex:0];
        column = [[view tableColumns] objectAtIndex:1];
        NSLog(@"Loaded roster window");
#endif
}

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

        title = [[[presenceBox menu] itemAtIndex:1] title];
        colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_ONLINE]
                                                                                 forKey:NSForegroundColorAttributeName];
        colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                                   attributes:colour];
        [[[presenceBox menu] itemAtIndex:1] setAttributedTitle(colouredTitle)];
        
        title = [[[presenceBox menu] itemAtIndex:2] title];
        colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_AWAY]
                                                                                 forKey:NSForegroundColorAttributeName];
        colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                                   attributes:colour];
        [[[presenceBox menu] itemAtIndex:2] setAttributedTitle(colouredTitle)];
        
        title = [[[presenceBox menu] itemAtIndex:3] title];
        colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_XA] 
                                                                                 forKey:NSForegroundColorAttributeName];
        colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                                   attributes:colour];
        [[[presenceBox menu] itemAtIndex:3] setAttributedTitle(colouredTitle)];
        
        title = [[[presenceBox menu] itemAtIndex:4] title];
        colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_DND] 
                                                                                 forKey:NSForegroundColorAttributeName];
        colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                                   attributes:colour];
        [[[presenceBox menu] itemAtIndex:4] setAttributedTitle(colouredTitle)];
        
        title = [[[presenceBox menu] itemAtIndex:6] title];
        colour = [NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] colourForPresence:PRESENCE_OFFLINE] 
                                                                                 forKey:NSForegroundColorAttributeName];
        colouredTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                                   attributes:colour];
        [[[presenceBox menu] itemAtIndex:6] setAttributedTitle(colouredTitle)];
}

- (NSAttributedString*) displayStringForObject:(id)anObject
{
        NSMutableDictionary * attributes = [[NSMutableDictionary alloc] init];
        NSString * plainText;
        if([anObject isKindOfClass:[XMPPRosterGroup class]])
        {
                plainText = [anObject groupName];
        }
        else if([anObject isKindOfClass:[XMPPPerson class]])
        {
                unsigned char onlineState = [[[anObject defaultIdentity] presence] show];
                NSColor * foreground = [[NSUserDefaults standardUserDefaults] colourForPresence:onlineState];
                if(foreground != nil)
                {
                        [attributes setValue:foreground
                                                  forKey:NSForegroundColorAttributeName];
                }
                plainText = [NSString stringWithFormat:@"%C %@", 
                        PRESENCE_ICONS[(onlineState / 10) - 1], 
                        [(XMPPPerson*)anObject name]];
        }
        else if([anObject isKindOfClass:[XMPPIdentity class]])
        {
                NSColor * foreground = [[NSUserDefaults standardUserDefaults] colourForPresence:[[anObject presence] show]];
                if(foreground != nil)
                {
                        [attributes setValue:foreground 
                                                  forKey:NSForegroundColorAttributeName];
                }
                plainText = [[anObject jid] jidString];
        }
        else 
        {
                plainText = @"Wrgon!";
        }
        NSAttributedString * text = [[NSAttributedString alloc] initWithString:plainText attributes:attributes];
        return text;
}

- (float) widthOfItemAndChildren:(id) anObject withIndent:(float)anIndent
{
        NSAttributedString * attributedText= [self displayStringForObject:anObject];
        float myWidth = [attributedText size].width;
        if([view isItemExpanded:anObject])
        {
                for(int i=0 ; i<[self outlineView:view numberOfChildrenOfItem:anObject] ; i++)
                {
                        float width = [self widthOfItemAndChildren:[self outlineView:view
                                                                                                                                   child:i
                                                                                                                                  ofItem:anObject] 
                                                                                        withIndent:anIndent] + anIndent;
                        if(width > myWidth)
                        {
                                myWidth = width;
                        }
                }
        }
        return myWidth;
}

- (int) rowsUnder:(id)anObject
{
        int rows = 0;
        if([view isItemExpanded:anObject])
        {
                   rows = [self outlineView:view numberOfChildrenOfItem:anObject];
                for(int i=0 ; i<[self outlineView:view numberOfChildrenOfItem:anObject] ; i++)
                {
                        rows += [self rowsUnder:[self outlineView:view child:i ofItem:anObject]];
                }
        }
        return rows;
}

- (NSSize) calculateRosterSize;
{
        NSSize size;
        //Calculate width
        float interCellHorizontalSpacing = [view intercellSpacing].width;
//        float indent = [view indentationPerLevel] + (interCellHorizontalSpacing);
        size.width = [self widthOfItemAndChildren:nil withIndent:0.0f];
        size.width += interCellHorizontalSpacing;
        //Hack to ensure text doesn't get truncated.
        [column setWidth:size.width + 200];
        size.width += interCellHorizontalSpacing + 70.0f;

        //Calculate height
#ifdef GNUSTEP
        //numberOfRows doesn't seem to work correctly on GNUstep.
        size.height = [self rowsUnder:nil] *  ([view rowHeight] + [view intercellSpacing].height);
#else
        size.height = [view numberOfRows] * ([view rowHeight] + [view intercellSpacing].height);
#endif
        return size;
}

- (void) subscriptionChanged:(NSNotification*)_notification
{
        if([[_notification name] isEqualToString:@"TRXMPPSubscriptionRequest"])
        {
                NSLog(@"Subscription request received");
                //TODO:  Ask permission first
                [roster authorise:[(XMPPPresence*)[_notification object] jid]];
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
        [defaultCenter addObserver:self
                       selector:@selector(newConversation:)
                           name:@"XMPPNewConversationStartedNotification"
                         object:nil];
        
        
        [[self window] setFrameFromString:@"Jabber Roster"];
        [[self window] setFrameAutosaveName:@"Jabber Roster"];
        roster = _roster;
        account = _account;
        //Note: nil must be changed to account if permitting multiple accounts
        NSNotificationCenter * localCenter = [NSNotificationCenter defaultCenter];
        [localCenter addObserver:self
                                        selector:@selector(presenceChanged:)
                                                name:@"LocalPresenceChangedNotification"
                                          object:nil];
        return self;
}
- (void) updateIdentities:(NSNotification*)aNotification
{
        //TODO: It might be possible to optimise this,
        //but the overhead of testing might be self-defeating
        [self update:nil];
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
        if([changedObject isKindOfClass:[XMPPPerson class]])
        {
                unsigned int hiddenPresence = [[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"];
                XMPPRosterGroup * group = [[account roster] groupNamed:[changedObject group]];
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
#ifdef GNUSTEP
        //GNUstep doesn't respect minimum window size for some reason
        if(windowFrameDimensions.size.width < 137)
        {
                windowFrameDimensions.size.width = 137;
        }
#endif
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
        }
#endif
        if([_object isKindOfClass:[XMPPRosterGroup class]] && 
                        [[NSUserDefaults standardUserDefaults] expandedGroup:[_object groupName]])
        {
                if([view isExpandable:_object])
                {
                        [view expandItem:_object];
                }
        }
        /* These exception handlers were a work around for a now-fixed bug.
         * They can probably be removed.
         */
        NS_DURING
        RESIZE_ROSTER;
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
                return [roster groupForIndex:_index ignoringPeopleLessOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]];
        }
        if([_item isKindOfClass:[XMPPRosterGroup class]])
        {
                return [_item personAtIndex:_index];
        }
        if([_item isKindOfClass:[XMPPPerson class]])
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
        if([item isKindOfClass:[XMPPRosterGroup class]])
        {
                return [NSString stringWithFormat:@"%d/%d %@",
                        [item numberOfPeopleInGroupMoreOnlineThan:PRESENCE_OFFLINE],
                        [item numberOfPeopleInGroupMoreOnlineThan:PRESENCE_UNKNOWN + 10],
                        [XMPPPresence displayStringForPresence:PRESENCE_ONLINE]];
        }
        NSString * toolTipMessage = nil;
        XMPPPresence * selectedPresence = nil;
        if([item isKindOfClass:[XMPPPerson class]])
        {
                selectedPresence = [[(XMPPPerson*)item defaultIdentity] presence];
        }
        else if([item isKindOfClass:[XMPPIdentity class]])
        {
                selectedPresence = [(XMPPIdentity*)item presence];
        }
        if(selectedPresence != nil)
        {
                toolTipMessage = [selectedPresence status];
                if(toolTipMessage == nil)
                {
                        toolTipMessage = [XMPPPresence displayStringForPresence:[selectedPresence show]];
                }                
        }
        return toolTipMessage;
}

- (BOOL) outlineView:(NSOutlineView *)_outlineView isItemExpandable:(id)_item
{
        if(roster == nil)
        {
                return NO;                
        }
        if([_item isKindOfClass:[XMPPRosterGroup class]])
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
        if([_item isKindOfClass:[XMPPPerson class]])
        {
                if([_item identities] > 1)
                {
                        return YES;
                }
        }
        return NO;
}
- (void) confirmDeleteDidEnd:(NSAlert *)alert returnCode:(int)returnCode contact:(id)contact
{
        if(returnCode == NSAlertFirstButtonReturn)
        {
                if([contact isKindOfClass:[XMPPPerson class]])
                {
                        FOREACH([contact identityList], identity, XMPPIdentity*)
                        {
                                NSLog(@"Deleting %@", [[identity jid] jidString]);
                                [roster unsubscribe:[identity jid]];
                        }
                }
                else if([contact isKindOfClass:[XMPPIdentity class]])
                {
                        NSLog(@"Deleting %@", [[contact jid] jidString]);
                        [roster unsubscribe:[contact jid]];                        
                }
        }
}
- (IBAction) remove:(id)sender
{
        id item = [view itemAtRow:[view selectedRow]];
        if([item isKindOfClass:[XMPPPerson class]])
        {
                NSAlert * alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"Delete Contact"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete %@?", [item name]]];
                [alert setInformativeText:@"All identities for this contact will be deleted."];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:[self window]
                                                  modalDelegate:self
                                                 didEndSelector:@selector(confirmDeleteDidEnd:returnCode:contact:)
                                                        contextInfo:(__bridge void*)item];                
        }
        else if([item isKindOfClass:[XMPPIdentity class]])
        {
                NSAlert * alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"Delete Contact"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete %@?", [[item jid] jidString]]];
                [alert setInformativeText:@"Other identities belonging to this contact will be unaffected."];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:[self window]
                                                  modalDelegate:self
                                                 didEndSelector:@selector(confirmDeleteDidEnd:returnCode:contact:)
                                                        contextInfo:(__bridge void*)item];                
        }
}
- (int)outlineView:(NSOutlineView *)_outlineView numberOfChildrenOfItem:(id)_item
{
        //Root node.  Children are all groups
        if(_item == nil)
        {
                return [roster numberOfGroupsContainingPeopleMoreOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]];
        }
        if([_item isKindOfClass:[XMPPRosterGroup class]])
        {
                return [_item numberOfPeopleInGroupMoreOnlineThan:[[NSUserDefaults standardUserDefaults] presenceForKey:@"HiddenPresences"]];
        }
        if([_item isKindOfClass:[XMPPPerson class]])
        {
                return [_item identities];
        }
        return 0;
}
- (id)outlineView:(NSOutlineView *)_outlineView objectValueForTableColumn:(NSTableColumn *)_tableColumn byItem:(id)_item
{
        if(_tableColumn == column)
        {
                return [self displayStringForObject:_item];
        }
        else
        {
                if([_item isKindOfClass:[XMPPPerson class]])
                {
                        return [(XMPPPerson*)_item avatar];
                }
        }
        return nil;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
        id group = [[notification userInfo] objectForKey:@"NSObject"];
        if([group isKindOfClass:[XMPPRosterGroup class]])
        {
                [[NSUserDefaults standardUserDefaults] setExpanded:[group groupName] to:YES];
        }
        RESIZE_ROSTER;
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
        id group = [[notification userInfo] objectForKey:@"NSObject"];
        if([group isKindOfClass:[XMPPRosterGroup class]])
        {
                [[NSUserDefaults standardUserDefaults] setExpanded:[group groupName] to:NO];
        }
        RESIZE_ROSTER;
}

inline static XMPPConversation * createChatWithPerson(id self, XMPPPerson* person, XMPPAccount * account)
{
        JID * destinationJID = [[person defaultIdentity] jid];
        XMPPConversation * conversation = [XMPPConversation conversationForPerson:person];
        if(conversation != nil)
        {
                [conversation setJID:destinationJID];
                [[conversation delegate] activate:self];
        }
        else
        {
                conversation = [XMPPConversation conversationWithPerson:person
                                                                                                  forAccount:account];
                
                MessageWindowController * chatWindow = [[MessageWindowController alloc] initWithWindowNibName:@"MessageWindow"];
                [chatWindow conversation:conversation];
                [conversation setDelegate:chatWindow];
        }
        return conversation;
}

- (IBAction) click:(id)sender
{
        id item = [view itemAtRow:[view clickedRow]];
        if([item isKindOfClass:[XMPPPerson class]])
        {
                createChatWithPerson(self,(XMPPPerson*) item, account);
        }
        else if([item isKindOfClass:[XMPPIdentity class]])
        {
                JID * destinationJID = [(XMPPIdentity*)item jid];
                [createChatWithPerson(self, [roster personForJID:destinationJID], account) setJID:destinationJID];
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
                [presenceBox selectItemWithTitle:[XMPPPresence displayStringForPresence:_status]];                
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
//Drag and drop operations

//Drag
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
        id item = [items objectAtIndex:0];
        if([item isKindOfClass:[XMPPPerson class]])
        {
                [pboard declareTypes:[NSArray arrayWithObject:@"XMPPPerson"] owner:self];
                [pboard setPropertyList:D([item name], @"name", [item group], @"group")
                                                forType:@"XMPPPerson"];
                return YES;        
        }
        if([item isKindOfClass:[XMPPPerson class]])
        {
                [pboard declareTypes:[NSArray arrayWithObject:@"XMPPIdentity"] owner:self];
                [pboard setString:[[item jid] jidString] forType:@"XMPPIdentity"];
                return YES;        
        }
        return NO;
}

//Can drop?
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(int)anIndex
{
        NSPasteboard * pboard = [info draggingPasteboard];
        if([item isKindOfClass:[XMPPPerson class]])
        {
                if([pboard availableTypeFromArray:A(@"XMPPPerson", @"XMPPIdentity")])
                {
                        return NSDragOperationMove;
                }
        }
        if([item isKindOfClass:[XMPPRosterGroup class]])
        {
                if([pboard availableTypeFromArray:A(@"XMPPPerson")])
                {
                        return NSDragOperationMove;
                }                
        }
        return NSDragOperationNone;
}
//Drop
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(int)anIndex
{
        NSPasteboard * pboard = [info draggingPasteboard];
        [pboard types];
        BOOL dropped = NO;
        if([item isKindOfClass:[XMPPPerson class]])
        {
                id object = nil;
                NSString * newGroup = [item group];
                NSString * newName = [item name];
                if((object = [pboard propertyListForType:@"XMPPPerson"]) != nil)
                {
                        NSString * groupName = [object objectForKey:@"group"];
                        NSString * personName = [object objectForKey:@"name"];
                        //Make sure it's not dealloc'd when we remove the last identity from it
                        XMPPPerson * person = [[roster groupNamed:groupName] personNamed:personName];
                        NSArray * identities = [person identityList];
                        FOREACH(identities, identity, XMPPIdentity*)
                        {
                                [roster setName:newName group:newGroup forIdentity:identity];
                        }
                        dropped = YES;
                }
                else if((object = [pboard propertyListForType:@"XMPPIdentity"]) != nil)
                {
                        JID * jid = [JID jidWithString:object];
                        XMPPIdentity * identity = [[roster personForJID:jid] identityForJID:jid];
                        //Make sure it's not dealloc'd when we remove the last identity from it
                        [roster setName:newName group:newGroup forIdentity:identity];
                        dropped = YES;
                }
        }
        else if([item isKindOfClass:[XMPPRosterGroup class]])
        {
                id object = nil;

                if((object = [pboard propertyListForType:@"XMPPPerson"]) != nil)
                {
                        NSString * groupName = [object objectForKey:@"group"];
                        NSString * personName = [object objectForKey:@"name"];
                        //Make sure it's not dealloc'd when we remove the last identity from it
                        XMPPPerson * person = [[roster groupNamed:groupName] personNamed:personName];
                        NSArray * identities = [person identityList];
                        NSString * newGroup = [item groupName];
                        FOREACH(identities, identity, XMPPIdentity*)
                        {
                                [roster setGroup:newGroup forIdentity:identity];
                        }
                        dropped = YES;
                }
        }
        if(dropped)
        {
                [self update:nil];
        }
        return dropped;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
        if([item isKindOfClass:[XMPPPerson class]])
        {
                return YES;
        }
        return NO;
}
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
        if([item isKindOfClass:[XMPPPerson class]])
        {
                NSString * group = [item group];
                if([object length] > 2)
                {
                        int p = ([[[item defaultIdentity] presence] show] / 10) - 1;
                        NSString * prefix = [NSString stringWithFormat:@"%C ", 
                        PRESENCE_ICONS[p]];
                        if([prefix isEqualToString:[object substringToIndex:2]])
                        {
                                object = [object substringFromIndex:2];
                        }
                }
                if(![object isEqualToString:[item name]])
                {
                        NSArray * identities = [item identityList];
                        FOREACH(identities, identity, XMPPIdentity*)
                        {
                                [roster setName:object group:group forIdentity:identity];
                        }
                }
        }
}
- (void) newConversation:(NSNotification*)_notification
{
        XMPPConversation * conversation = [[_notification userInfo] valueForKey:@"XMPPConversation"];
        id chatWindow = [[MessageWindowController alloc] initWithWindowNibName:@"MessageWindow"];
                
        [chatWindow conversation:conversation];
        [conversation setDelegate:chatWindow];
}

- (void) dealloc
{
        [rosterControllers removeObject:self];
        [[self window] close];
}
@end
