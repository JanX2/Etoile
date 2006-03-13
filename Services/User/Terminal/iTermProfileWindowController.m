/*
 **  iTermProfileWindowController.h
 **
 **  Copyright (c) 2002, 2003, 2004
 **
 **  Author: Ujwal S. Setlur
 **
 **  Project: iTerm
 **
 **  Description: window controller for profile editors.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <iTerm/iTermController.h>
#import <iTerm/iTermKeyBindingMgr.h>
#import <iTerm/iTermDisplayProfileMgr.h>
#import <iTerm/iTermTerminalProfileMgr.h>
#import <iTerm/iTermProfileWindowController.h>


@implementation iTermProfileWindowController

- (IBAction) showProfilesWindow: (id) sender
{
	NSEnumerator *profileEnumerator;
	NSString *aString;
	NSEnumerator *anEnumerator;
	NSNumber *anEncoding;
	
	// load up the keyboard profiles
	[kbProfileSelector removeAllItems];
	profileEnumerator = [[[iTermKeyBindingMgr singleInstance] profiles] keyEnumerator];
	while((aString = [profileEnumerator nextObject]) != nil)
		[kbProfileSelector addItemWithTitle: aString];
	
	[self kbProfileChanged: nil];
	[self tableViewSelectionDidChange: nil];	
	
	// load up the display profiles
	[displayProfileSelector removeAllItems];
	profileEnumerator = [[[iTermDisplayProfileMgr singleInstance] profiles] keyEnumerator];
	while((aString = [profileEnumerator nextObject]) != nil)
		[displayProfileSelector addItemWithTitle: aString];
	
	[self displayProfileChanged: nil];
	
	// load up the terminal profiles
	[terminalProfileSelector removeAllItems];
	profileEnumerator = [[[iTermTerminalProfileMgr singleInstance] profiles] keyEnumerator];
	while((aString = [profileEnumerator nextObject]) != nil)
		[terminalProfileSelector addItemWithTitle: aString];

	// add list of encodings
	[terminalEncoding removeAllItems];
	anEnumerator = [[[iTermController sharedInstance] sortedEncodingList] objectEnumerator];
	while((anEncoding = [anEnumerator nextObject]) != NULL)
	{
		[terminalEncoding addItemWithTitle: [NSString localizedNameOfStringEncoding: [anEncoding unsignedIntValue]]];
		[[terminalEncoding lastItem] setTag: [anEncoding unsignedIntValue]];
	}
	
	[self terminalProfileChanged: nil];
	
	[self showWindow: self];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    // Post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"nonTerminalWindowBecameKey" object: nil userInfo: nil];        
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[NSColorPanel sharedColorPanel] close];
	[[NSFontPanel sharedFontPanel] close];	
}

// Profile editing
- (IBAction) profileAdd: (id) sender
{
	
	[NSApp beginSheet: addProfile
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(_addProfileSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];        
	
}

- (IBAction) profileDelete: (id) sender
{
	[NSApp beginSheet: deleteProfile
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(_deleteProfileSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];        
}

- (IBAction) profileAddConfirm: (id) sender
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp endSheet:addProfile returnCode:NSOKButton];
}

- (IBAction) profileAddCancel: (id) sender
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp endSheet:addProfile returnCode:NSCancelButton];
}

- (IBAction) profileDeleteConfirm: (id) sender
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp endSheet:deleteProfile returnCode:NSOKButton];
}

- (IBAction) profileDeleteCancel: (id) sender
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[NSApp endSheet:deleteProfile returnCode:NSCancelButton];
}


// Keybinding profile UI
- (void) kbOptionKeyChanged: (id) sender
{
	
	[[iTermKeyBindingMgr singleInstance] setOptionKey: [kbOptionKey selectedColumn] 
										   forProfile: [kbProfileSelector titleOfSelectedItem]];
}

- (IBAction) kbProfileChanged: (id) sender
{
	NSString *selectedKBProfile;
	//NSLog(@"%s; %@", __PRETTY_FUNCTION__, sender);
	
	selectedKBProfile = [kbProfileSelector titleOfSelectedItem];
	
	[kbProfileDeleteButton setEnabled: ![[iTermKeyBindingMgr singleInstance] isGlobalProfile: selectedKBProfile]];
    [kbOptionKey selectCellAtRow:0 column:[[iTermKeyBindingMgr singleInstance] optionKeyForProfile: selectedKBProfile]];
	
	[kbEntryTableView reloadData];
}

- (IBAction) kbEntryAdd: (id) sender
{
	int i;
	
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[kbEntryKeyCode setStringValue: @""];
	[kbEntryText setStringValue: @""];
	[kbEntryKeyModifierOption setState: NSOffState];
	[kbEntryKeyModifierControl setState: NSOffState];
	[kbEntryKeyModifierShift setState: NSOffState];
	[kbEntryKeyModifierCommand setState: NSOffState];
	[kbEntryKeyModifierOption setEnabled: YES];
	[kbEntryKeyModifierControl setEnabled: YES];
	[kbEntryKeyModifierShift setEnabled: YES];
	[kbEntryKeyModifierCommand setEnabled: YES];
	if ([kbEntryKeyCode respondsToSelector: @selector(setHidden:)] == YES)
	{
		[kbEntryKeyCode setHidden: YES];
		[kbEntryText setHidden: YES];
	}
				
	[kbEntryKey selectItemAtIndex: 0];
	[kbEntryKey setTarget: self];
	[kbEntryKey setAction: @selector(kbEntrySelectorChanged:)];
	[kbEntryAction selectItemAtIndex: 0];
	[kbEntryAction setTarget: self];
	[kbEntryAction setAction: @selector(kbEntrySelectorChanged:)];
	
	
	
	if([[iTermKeyBindingMgr singleInstance] isGlobalProfile: [kbProfileSelector titleOfSelectedItem]])
	{
		for (i = KEY_ACTION_NEXT_SESSION; i < KEY_ACTION_ESCAPE_SEQUENCE; i++)
		{
			[[kbEntryAction itemAtIndex: i] setEnabled: YES];
			[[kbEntryAction itemAtIndex: i] setAction: @selector(kbEntrySelectorChanged:)];
			[[kbEntryAction itemAtIndex: i] setTarget: self];
		}
	}
	else
	{
		for (i = KEY_ACTION_NEXT_SESSION; i < KEY_ACTION_ESCAPE_SEQUENCE; i++)
		{
			[[kbEntryAction itemAtIndex: i] setEnabled: NO];
			[[kbEntryAction itemAtIndex: i] setAction: nil];
		}
		[kbEntryAction selectItemAtIndex: KEY_ACTION_ESCAPE_SEQUENCE];
		
	}
	
	[self kbEntrySelectorChanged: kbEntryAction];
	
	[NSApp beginSheet: addKBEntry
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(_addKBEntrySheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];        
	
}

- (IBAction) kbEntryAddConfirm: (id) sender
{
	[NSApp endSheet:addKBEntry returnCode:NSOKButton];
}

- (IBAction) kbEntryAddCancel: (id) sender
{
	[NSApp endSheet:addKBEntry returnCode:NSCancelButton];
}


- (IBAction) kbEntryDelete: (id) sender
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	if([kbEntryTableView selectedRow] >= 0)
	{
		[[iTermKeyBindingMgr singleInstance] deleteEntryAtIndex: [kbEntryTableView selectedRow] 
													  inProfile: [kbProfileSelector titleOfSelectedItem]];
		[kbEntryTableView reloadData];
	}
	else
		NSBeep();
}

- (IBAction) kbEntrySelectorChanged: (id) sender
{
	if(sender == kbEntryKey)
	{
		if([kbEntryKey indexOfSelectedItem] == KEY_HEX_CODE && [kbEntryKeyCode respondsToSelector: @selector(setHidden:)] == YES)
		{			
			[kbEntryKeyCode setHidden: NO];
		}
		else
		{			
			[kbEntryKeyCode setStringValue: @""];
			if ([kbEntryKeyCode respondsToSelector: @selector(setHidden:)] == YES)
				[kbEntryKeyCode setHidden: YES];
		}
	}
	else if(sender == kbEntryAction)
	{
		if([kbEntryAction indexOfSelectedItem] == KEY_ACTION_HEX_CODE ||
		   [kbEntryAction indexOfSelectedItem] == KEY_ACTION_ESCAPE_SEQUENCE)
		{		
			if ([kbEntryText respondsToSelector: @selector(setHidden:)] == YES)
				[kbEntryText setHidden: NO];
		}
		else
		{
			[kbEntryText setStringValue: @""];
			if([kbEntryText respondsToSelector: @selector(setHidden:)] == YES)
				[kbEntryText setHidden: YES];
		}
	}	
}

// NSTableView data source
- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
	if([kbProfileSelector numberOfItems] == 0)
		return (0);
	
	return ([[iTermKeyBindingMgr singleInstance] numberOfEntriesInProfile: [kbProfileSelector titleOfSelectedItem]]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if([[aTableColumn identifier] intValue] ==  0)
	{
		return ([[iTermKeyBindingMgr singleInstance] keyCombinationAtIndex: rowIndex 
																 inProfile: [kbProfileSelector titleOfSelectedItem]]);
	}
	else
	{
		return ([[iTermKeyBindingMgr singleInstance] actionForKeyCombinationAtIndex: rowIndex 
																		  inProfile: [kbProfileSelector titleOfSelectedItem]]);
	}
}

// NSTableView delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([kbEntryTableView selectedRow] < 0)
		[kbEntryDeleteButton setEnabled: NO];
	else
		[kbEntryDeleteButton setEnabled: YES];
}

// Display profile UI
- (IBAction) displayProfileChanged: (id) sender
{
	NSString *theProfile;
	NSString *backgroundImagePath;
	
	theProfile = [displayProfileSelector titleOfSelectedItem];
	
	// load the colors
	[displayFGColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_FOREGROUND_COLOR 
																  forProfile: theProfile]];
	[displayBGColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_BACKGROUND_COLOR 
																  forProfile: theProfile]];
	[displayBoldColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_BOLD_COLOR 
																  forProfile: theProfile]];
	[displaySelectionColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_SELECTION_COLOR 
																  forProfile: theProfile]];
	[displaySelectedTextColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_SELECTED_TEXT_COLOR 
																  forProfile: theProfile]];
	[displayCursorColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_CURSOR_COLOR 
																  forProfile: theProfile]];
	[displayCursorTextColor setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_CURSOR_TEXT_COLOR 
																  forProfile: theProfile]];
	[displayAnsi0Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_0_COLOR 
																  forProfile: theProfile]];
	[displayAnsi1Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_1_COLOR 
																  forProfile: theProfile]];
	[displayAnsi2Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_2_COLOR 
																  forProfile: theProfile]];
	[displayAnsi3Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_3_COLOR 
																  forProfile: theProfile]];
	[displayAnsi4Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_4_COLOR 
																  forProfile: theProfile]];
	[displayAnsi5Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_5_COLOR 
																  forProfile: theProfile]];
	[displayAnsi6Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_6_COLOR 
																  forProfile: theProfile]];
	[displayAnsi7Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_7_COLOR 
																  forProfile: theProfile]];
	[displayAnsi8Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_8_COLOR 
																  forProfile: theProfile]];
	[displayAnsi9Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_9_COLOR 
																  forProfile: theProfile]];
	[displayAnsi10Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_10_COLOR 
																  forProfile: theProfile]];
	[displayAnsi11Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_11_COLOR 
																  forProfile: theProfile]];
	[displayAnsi12Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_12_COLOR 
																  forProfile: theProfile]];
	[displayAnsi13Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_13_COLOR 
																  forProfile: theProfile]];
	[displayAnsi14Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_14_COLOR 
																  forProfile: theProfile]];
	[displayAnsi15Color setColor: [[iTermDisplayProfileMgr singleInstance] color: TYPE_ANSI_15_COLOR 
																  forProfile: theProfile]];
	
	// background image
	backgroundImagePath = [[iTermDisplayProfileMgr singleInstance] backgroundImageForProfile: theProfile];
	if([backgroundImagePath length] > 0)
	{
		NSImage *anImage = [[NSImage alloc] initWithContentsOfFile: backgroundImagePath];
		if(anImage != nil)
		{
			[displayBackgroundImage setImage: anImage];
			[anImage release];
			[displayUseBackgroundImage setState: NSOnState];
		}
		else
		{
			[displayBackgroundImage setImage: nil];
			[displayUseBackgroundImage setState: NSOffState];
		}
	}
	else
	{
		[displayBackgroundImage setImage: nil];
		[displayUseBackgroundImage setState: NSOffState];
	}	
				
	// transparency
	[displayTransparency setStringValue: [NSString stringWithFormat: @"%d", 
		(int)(100*[[iTermDisplayProfileMgr singleInstance] transparencyForProfile: theProfile])]];
	
	// disable bold
	[displayDisableBold setState: [[iTermDisplayProfileMgr singleInstance] disableBoldForProfile: theProfile]];
	
	// fonts
	[self _updateFontsDisplay];
	
	// anti-alias
	[displayAntiAlias setState: [[iTermDisplayProfileMgr singleInstance] windowAntiAliasForProfile: theProfile]];
	
	// window size
	[displayColTextField setStringValue: [NSString stringWithFormat: @"%d",
		[[iTermDisplayProfileMgr singleInstance] windowColumnsForProfile: theProfile]]];
	[displayRowTextField setStringValue: [NSString stringWithFormat: @"%d",
		[[iTermDisplayProfileMgr singleInstance] windowRowsForProfile: theProfile]]];
	
	[displayProfileDeleteButton setEnabled: ![[iTermDisplayProfileMgr singleInstance] isDefaultProfile: theProfile]];

	
}

- (IBAction) displaySetDisableBold: (id) sender
{
	if(sender == displayDisableBold)
	{
		[[iTermDisplayProfileMgr singleInstance] setDisableBold: [sender state] 
														 forProfile: [displayProfileSelector titleOfSelectedItem]];
	}
}

- (IBAction) displaySetAntiAlias: (id) sender
{
	if(sender == displayAntiAlias)
	{
		[[iTermDisplayProfileMgr singleInstance] setWindowAntiAlias: [sender state] 
												   forProfile: [displayProfileSelector titleOfSelectedItem]];
	}
}

- (IBAction) displayBackgroundImage: (id) sender
{
	NSString *theProfile = [displayProfileSelector titleOfSelectedItem];
	
	if (sender == displayUseBackgroundImage)
	{
		if ([sender state] == NSOffState)
		{
			[displayBackgroundImage setImage: nil];
			[[iTermDisplayProfileMgr singleInstance] setBackgroundImage: @"" forProfile: theProfile];
		}
		else
			[self _chooseBackgroundImageForProfile: theProfile];
	}
}

- (IBAction) displayChangeColor: (id) sender
{
	
	NSString *aProfileName;
	int type;
	
	aProfileName = [displayProfileSelector titleOfSelectedItem];
	type = [sender tag];
	
	[[iTermDisplayProfileMgr singleInstance] setColor: [sender color]
											  forType: type
										   forProfile: aProfileName];
	
	// update fonts display
	[self _updateFontsDisplay];
	
}

// sent by NSFontManager
- (void)changeFont:(id)fontManager
{
	NSString *theProfile;
	NSFont *aFont;
	
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	
	theProfile = [displayProfileSelector titleOfSelectedItem];
	
	if(changingNAFont)
	{
		aFont = [fontManager convertFont: [displayNAFontTextField font]];
		[[iTermDisplayProfileMgr singleInstance] setWindowNAFont: aFont forProfile: theProfile];
	}
	else
	{
		aFont = [fontManager convertFont: [displayFontTextField font]];
		[[iTermDisplayProfileMgr singleInstance] setWindowFont: aFont forProfile: theProfile];
	}
	
	[self _updateFontsDisplay];
	
}


- (IBAction) displaySelectFont: (id) sender
{
	NSFont *aFont;
	NSString *theProfile;
	NSFontPanel *aFontPanel;
	
	changingNAFont = NO;
	
	theProfile = [displayProfileSelector titleOfSelectedItem];
	aFont = [[iTermDisplayProfileMgr singleInstance] windowFontForProfile: theProfile];
	
	// make sure we get the messages from the NSFontManager
    [[self window] makeFirstResponder:self];
	aFontPanel = [[NSFontManager sharedFontManager] fontPanel: YES];
	[aFontPanel setAccessoryView: displayFontAccessoryView];
    [[NSFontManager sharedFontManager] setSelectedFont:aFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction) displaySelectNAFont: (id) sender
{
	NSFont *aFont;
	NSString *theProfile;
	NSFontPanel *aFontPanel;
	
	changingNAFont = YES;
	
	theProfile = [displayProfileSelector titleOfSelectedItem];
	aFont = [[iTermDisplayProfileMgr singleInstance] windowNAFontForProfile: theProfile];
	
	// make sure we get the messages from the NSFontManager
    [[self window] makeFirstResponder:self];
	aFontPanel = [[NSFontManager sharedFontManager] fontPanel: YES];
	[aFontPanel setAccessoryView: displayFontAccessoryView];
    [[NSFontManager sharedFontManager] setSelectedFont:aFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction) displaySetFontSpacing: (id) sender
{
	NSString *theProfile;
	
	theProfile = [displayProfileSelector titleOfSelectedItem];
	
	if(sender == displayFontSpacingWidth)
		[[iTermDisplayProfileMgr singleInstance] setWindowHorizontalCharSpacing: [sender floatValue] 
																	 forProfile: theProfile];
	else if(sender == displayFontSpacingHeight)
		[[iTermDisplayProfileMgr singleInstance] setWindowVerticalCharSpacing: [sender floatValue] 
																	 forProfile: theProfile];
	
}

// NSTextField delegate
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	int iVal;
	float fVal;
	NSString *theDsiplayProfile;
	NSString *theTerminalProfile;
	id sender;

	//NSLog(@"%s: %@", __PRETTY_FUNCTION__, [aNotification object]);

	theDsiplayProfile = [displayProfileSelector titleOfSelectedItem];
	theTerminalProfile = [terminalProfileSelector titleOfSelectedItem];
	sender = [aNotification object];

	iVal = [sender intValue];
	fVal = [sender floatValue];
	if(sender == displayColTextField)
		[[iTermDisplayProfileMgr singleInstance] setWindowColumns: iVal forProfile: theDsiplayProfile];
	else if(sender == displayRowTextField)
		[[iTermDisplayProfileMgr singleInstance] setWindowRows: iVal forProfile: theDsiplayProfile];
	else if(sender == displayTransparency)
		[[iTermDisplayProfileMgr singleInstance] setTransparency: fVal/100 forProfile: theDsiplayProfile];
	else if(sender == terminalScrollback)
		[[iTermTerminalProfileMgr singleInstance] setScrollbackLines: iVal forProfile: theTerminalProfile];
	else if(sender == terminalIdleChar)
		[[iTermTerminalProfileMgr singleInstance] setIdleChar: iVal forProfile: theTerminalProfile];
}

// Terminal profile UI
- (IBAction) terminalProfileChanged: (id) sender
{
	NSString *theProfile;
	
	theProfile = [terminalProfileSelector titleOfSelectedItem];

	[terminalType setTitle: [[iTermTerminalProfileMgr singleInstance] typeForProfile: theProfile]];
	[terminalEncoding setTitle: [NSString localizedNameOfStringEncoding:
		[[iTermTerminalProfileMgr singleInstance] encodingForProfile: theProfile]]];
	[terminalScrollback setStringValue: [NSString stringWithFormat: @"%d",
		[[iTermTerminalProfileMgr singleInstance] scrollbackLinesForProfile: theProfile]]];
	[terminalSilenceBell setState: [[iTermTerminalProfileMgr singleInstance] silenceBellForProfile: theProfile]];
	[terminalShowBell setState: [[iTermTerminalProfileMgr singleInstance] showBellForProfile: theProfile]];
	[terminalBlink setState: [[iTermTerminalProfileMgr singleInstance] blinkCursorForProfile: theProfile]];
	[terminalCloseOnSessionEnd setState: [[iTermTerminalProfileMgr singleInstance] closeOnSessionEndForProfile: theProfile]];
	[terminalDoubleWidth setState: [[iTermTerminalProfileMgr singleInstance] doubleWidthForProfile: theProfile]];
	[terminalSendIdleChar setState: [[iTermTerminalProfileMgr singleInstance] sendIdleCharForProfile: theProfile]];
	[terminalIdleChar setStringValue: [NSString stringWithFormat: @"%d",  
		[[iTermTerminalProfileMgr singleInstance] idleCharForProfile: theProfile]]];
	[xtermMouseReporting setState: [[iTermTerminalProfileMgr singleInstance] xtermMouseReportingForProfile: theProfile]];
	
	[terminalProfileDeleteButton setEnabled: ![[iTermTerminalProfileMgr singleInstance] isDefaultProfile: theProfile]];

}

- (IBAction) terminalSetType: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setType: [sender titleOfSelectedItem] 
										   forProfile: [terminalProfileSelector titleOfSelectedItem]];
}

- (IBAction) terminalSetEncoding: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setEncoding: [[terminalEncoding selectedItem] tag] 
											   forProfile: [terminalProfileSelector titleOfSelectedItem]];
}

- (IBAction) terminalSetSilenceBell: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setSilenceBell: [sender state] 
												  forProfile: [terminalProfileSelector titleOfSelectedItem]];
}	

- (IBAction) terminalSetShowBell: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setShowBell: [sender state] 
												  forProfile: [terminalProfileSelector titleOfSelectedItem]];
}

- (IBAction) terminalSetBlink: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setBlinkCursor: [sender state] 
												  forProfile: [terminalProfileSelector titleOfSelectedItem]];
}	

- (IBAction) terminalSetCloseOnSessionEnd: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setCloseOnSessionEnd: [sender state] 
														forProfile: [terminalProfileSelector titleOfSelectedItem]];
}	

- (IBAction) terminalSetDoubleWidth: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setDoubleWidth: [sender state] 
												  forProfile: [terminalProfileSelector titleOfSelectedItem]];
}	

- (IBAction) terminalSetSendIdleChar: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setSendIdleChar: [sender state] 
												   forProfile: [terminalProfileSelector titleOfSelectedItem]];
}

- (IBAction) terminalSetXtermMouseReporting: (id) sender
{
	[[iTermTerminalProfileMgr singleInstance] setXtermMouseReporting: [sender state] 
												  forProfile: [terminalProfileSelector titleOfSelectedItem]];
}	


@end

@implementation iTermProfileWindowController (Private)

- (void)_addKBEntrySheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	if(returnCode == NSOKButton)
	{
		unsigned int modifiers = 0;
		unsigned int hexCode = 0;
		
		if([kbEntryKeyModifierOption state] == NSOnState)
			modifiers |= NSAlternateKeyMask;
		if([kbEntryKeyModifierControl state] == NSOnState)
			modifiers |= NSControlKeyMask;
		if([kbEntryKeyModifierShift state] == NSOnState)
			modifiers |= NSShiftKeyMask;
		if([kbEntryKeyModifierCommand state] == NSOnState)
			modifiers |= NSCommandKeyMask;
		
		if([kbEntryKey indexOfSelectedItem] == KEY_HEX_CODE)
		{
			if(sscanf([[kbEntryKeyCode stringValue] UTF8String], "%x", &hexCode) == 1)
			{
				[[iTermKeyBindingMgr singleInstance] addEntryForKeyCode: hexCode 
															  modifiers: modifiers 
																 action: [kbEntryAction indexOfSelectedItem] 
																   text: [kbEntryText stringValue]
																profile: [kbProfileSelector titleOfSelectedItem]];
			}
		}
		else
		{
			[[iTermKeyBindingMgr singleInstance] addEntryForKey: [kbEntryKey indexOfSelectedItem] 
													  modifiers: modifiers 
														 action: [kbEntryAction indexOfSelectedItem] 
														   text: [kbEntryText stringValue]
														profile: [kbProfileSelector titleOfSelectedItem]];			
		}
		[self kbProfileChanged: nil];
	}
	
	[addKBEntry close];
}

- (void)_addProfileSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	int selectedTabViewItem;
	NSPopUpButton *aProfileSelector;
	NSEnumerator *aProfileEnumerator;
	SEL aSelector;
	NSString *aString;
	id profileMgr;
	
	selectedTabViewItem  = [profileTabView indexOfTabViewItem: [profileTabView selectedTabViewItem]];
	
	if(selectedTabViewItem == KEYBOARD_PROFILE_TAB)
	{
		profileMgr = [iTermKeyBindingMgr singleInstance];
		aSelector = @selector(kbProfileChanged:);
		aProfileSelector = kbProfileSelector;
	}
	else if(selectedTabViewItem == TERMINAL_PROFILE_TAB)
	{
		profileMgr = [iTermTerminalProfileMgr singleInstance];
		aSelector = @selector(terminalProfileChanged:);
		aProfileSelector = terminalProfileSelector;
	}
	else if(selectedTabViewItem == DISPLAY_PROFILE_TAB)
	{
		profileMgr = [iTermDisplayProfileMgr singleInstance];
		aSelector = @selector(displayProfileChanged:);
		aProfileSelector = displayProfileSelector;
	}
	else
		return;
	
	if(returnCode == NSOKButton && [[profileName stringValue] length] > 0)
	{
		
		// make sure this profile does not already exist
		if([aProfileSelector indexOfItemWithTitle: [profileName stringValue]] >= 0)
		{
			NSBeep();
			[addProfile close];
			return;
		}
		
		[profileMgr addProfileWithName: [profileName stringValue] 
													copyProfile: [aProfileSelector titleOfSelectedItem]];
		
		[aProfileSelector removeAllItems];
		aProfileEnumerator = [[profileMgr profiles] keyEnumerator];
		while((aString = [aProfileEnumerator nextObject]) != nil)
			[aProfileSelector addItemWithTitle: aString];	
		[aProfileSelector selectItemWithTitle: [profileName stringValue]];
		[self performSelector: aSelector];
	}
	
	[addProfile close];
}

- (void)_deleteProfileSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	int selectedTabViewItem;
	NSPopUpButton *aProfileSelector;
	NSEnumerator *aProfileEnumerator;
	SEL aSelector;
	NSString *aString;
	id profileMgr;
	
	selectedTabViewItem  = [profileTabView indexOfTabViewItem: [profileTabView selectedTabViewItem]];
	
	if(selectedTabViewItem == KEYBOARD_PROFILE_TAB)
	{
		profileMgr = [iTermKeyBindingMgr singleInstance];
		aSelector = @selector(kbProfileChanged:);
		aProfileSelector = kbProfileSelector;
	}
	else if(selectedTabViewItem == TERMINAL_PROFILE_TAB)
	{
		profileMgr = [iTermTerminalProfileMgr singleInstance];
		aSelector = @selector(terminalProfileChanged:);
		aProfileSelector = terminalProfileSelector;
	}
	else if(selectedTabViewItem == DISPLAY_PROFILE_TAB)
	{
		profileMgr = [iTermDisplayProfileMgr singleInstance];
		aSelector = @selector(displayProfileChanged:);
		aProfileSelector = displayProfileSelector;
	}
	else
		return;
	
	if(returnCode == NSOKButton)
	{
		
		[profileMgr deleteProfileWithName: [aProfileSelector titleOfSelectedItem]];
		
		[aProfileSelector removeAllItems];
		aProfileEnumerator = [[profileMgr profiles] keyEnumerator];
		while((aString = [aProfileEnumerator nextObject]) != nil)
			[aProfileSelector addItemWithTitle: aString];
		if([aProfileSelector numberOfItems] > 0)
			[aProfileSelector selectItemAtIndex: 0];
		[self performSelector: aSelector];
	}
	
	[deleteProfile close];
}

- (void) _updateFontsDisplay
{
	NSString *theProfile;
	float horizontalSpacing, verticalSpacing;
	
	theProfile = [displayProfileSelector titleOfSelectedItem];
	
	// load the fonts
	NSString *fontName;
	NSFont *font;
	
	font = [[iTermDisplayProfileMgr singleInstance] windowFontForProfile: theProfile];
	if(font != nil)
	{
		fontName = [NSString stringWithFormat: @"%@ %g", [font fontName], [font pointSize]];
		[displayFontTextField setStringValue: fontName];
		[displayFontTextField setFont: font];
		[displayFontTextField setTextColor: [displayFGColor color]];
		[displayFontTextField setBackgroundColor: [displayBGColor color]];
	}
	else
	{
		fontName = @"Unknown Font";
		[displayFontTextField setStringValue: fontName];
	}
	font = [[iTermDisplayProfileMgr singleInstance] windowNAFontForProfile: theProfile];
	if(font != nil)
	{
		fontName = [NSString stringWithFormat: @"%@ %g", [font fontName], [font pointSize]];
		[displayNAFontTextField setStringValue: fontName];
		[displayNAFontTextField setFont: font];
		[displayNAFontTextField setTextColor: [displayFGColor color]];
		[displayNAFontTextField setBackgroundColor: [displayBGColor color]];
	}
	else
	{
		fontName = @"Unknown NA Font";
		[displayNAFontTextField setStringValue: fontName];
	}
	
	horizontalSpacing = [[iTermDisplayProfileMgr singleInstance] windowHorizontalCharSpacingForProfile: theProfile];
	verticalSpacing = [[iTermDisplayProfileMgr singleInstance] windowVerticalCharSpacingForProfile: theProfile];

	[displayFontSpacingWidth setFloatValue: horizontalSpacing];
	[displayFontSpacingHeight setFloatValue: verticalSpacing];
	
}

- (void) _chooseBackgroundImageForProfile: (NSString *) theProfile
{
    NSOpenPanel *panel;
    int sts;
    NSString *filename = nil;
		
    panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection: NO];
			
    sts = [panel runModalForDirectory: NSHomeDirectory() file:@"" types: [NSImage imageFileTypes]];
    if (sts == NSOKButton) {
		if([[panel filenames] count] > 0)
			filename = [[panel filenames] objectAtIndex: 0];
		
		if([filename length] > 0)
		{
			NSImage *anImage = [[NSImage alloc] initWithContentsOfFile: filename];
			if(anImage != nil)
			{
				[displayBackgroundImage setImage: anImage];
				[anImage release];
				[[iTermDisplayProfileMgr singleInstance] setBackgroundImage: filename forProfile: theProfile];
			}
			else
				[displayUseBackgroundImage setState: NSOffState];
		}
		else
			[displayUseBackgroundImage setState: NSOffState];
    }
    else
    {
		[displayUseBackgroundImage setState: NSOffState];
    }
	
}

@end

