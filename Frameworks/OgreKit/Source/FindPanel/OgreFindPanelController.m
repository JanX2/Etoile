/*
 * Name: OgreFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreFindPanelController.h>
#import <OgreKit/OgreFindPanel.h>
#import "GNUstep.h"

@implementation OgreFindPanelController
// 適切な正規表現かどうか調べる
- (BOOL)alertIfInvalidRegex
{
  NS_DURING
   [OGRegularExpression regularExpressionWithString: [[findPanel findTextField] stringValue]
                                           options: [self options]
                                            syntax: [self syntax]
                                   escapeCharacter: OgreBackslashCharacter];
  NS_HANDLER
  // 例外処理
    if ([[localException name] isEqualToString:OgreException]) {
      NSBeep();   // 不適切な正規表現だった場合 (非常に手抜き)
    } else {
      [localException raise];
    }
    return NO;
  NS_ENDHANDLER

  return YES;
}

- (void) findNext: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  OgreTextFindResult *result = [[self textFinder] 
	           find: [[findPanel findTextField] stringValue]
	        options: [self options]
		fromTop: NO
		forward: YES
		wrap: YES];
  if (![result isSuccess]) 
  {
    [findPanel setTitle: @"Find Panel: find next failed"];
  }
  else
  {
    [findPanel setTitle: @"Find Panel: find next successed"];
  }
}

- (void) findPrevious: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  OgreTextFindResult *result = [[self textFinder] 
	           find: [[findPanel findTextField] stringValue]
	        options: [self options]
		fromTop: NO
		forward: NO
		wrap: YES];
  if (![result isSuccess]) 
  {
    [findPanel setTitle: @"Find Panel: find previous failed"];
  }
  else
  {
    [findPanel setTitle: @"Find Panel: find previous successed"];
  }
}

- (void) replace: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  OgreTextFindResult *result = [[self textFinder] 
	replace: [[findPanel findTextField] stringValue]
	withString: [[findPanel replaceTextField] stringValue]
        options: [self options]];

  if (![result isSuccess]) 
  {
    [findPanel setTitle: @"Find Panel: replace failed"];
  }
  else
  {
    [findPanel setTitle: @"Find Panel: replace successed"];
  }
}

- (void) replaceAndFind: (id) sender
{
  if (![self alertIfInvalidRegex]) return;

  // FIXME: not sure what replacingOnly means.
  OgreTextFindResult *result = [[self textFinder] 
	replaceAndFind: [[findPanel findTextField] stringValue]
	withString: [[findPanel replaceTextField] stringValue]
        options: [self options]
        replacingOnly: NO
        wrap: NO];

  if (![result isSuccess]) 
  {
    [findPanel setTitle: @"Find Panel: replace and find failed"];
  }
  else
  {
    [findPanel setTitle: @"Find Panel: replace and find successed"];
  }
}

- (void) replaceAll: (id) sender
{
  if (![self alertIfInvalidRegex]) return;
  
  // FIXME: it replace everything in the document, not only selected text
  OgreTextFindResult *result = [[self textFinder] 
	replaceAll: [[findPanel findTextField] stringValue]
	withString: [[findPanel replaceTextField] stringValue]
        options: [self options]
        inSelection: inSelection];

  if (![result isSuccess]) {
    [findPanel setTitle: @"Find Panel: replace all failed"];
  }
  else
  {
    [findPanel setTitle: @"Find Panel: replace all successed"];
  }
}

- (OgreTextFinder*)textFinder
{
	return textFinder;
}

- (void)setTextFinder:(OgreTextFinder*)aTextFinder
{
	textFinder = aTextFinder;
}


- (IBAction)showFindPanel:(id)sender
{
	if ([findPanel isKeyWindow]) {
		[findPanel orderFront:self];
	} else {
		[findPanel makeKeyAndOrderFront:self];
		[[findPanel findTextField] selectText: self];
	}
	
	// WindowsメニューにFind Panelを追加
	[NSApp addWindowsItem:findPanel title:[findPanel title] filename:NO];
}

- (void)close
{
	[findPanel orderOut:self];
}

- (NSPanel*)findPanel
{
	return findPanel;
}

- (void)setFindPanel:(NSPanel*)aPanel
{
	ASSIGN(findPanel, aPanel);
}

- (unsigned int) options
{
  return options;
}

- (void) setOptions: (unsigned int) o
{
  options = o;
}

- (OgreSyntax) syntax
{
  return syntax;
}

- (void) setSyntax: (OgreSyntax) o
{
  [[self textFinder] setSyntax: o];
  syntax = o;
}

- (BOOL) inSelection
{
  return inSelection;
}

- (void) setInSelection: (BOOL) flag
{
  inSelection = flag;
}

// NSCoding protocols
- (NSDictionary*)history
{
	/* 履歴等を保存したい場合は、NSDictionaryで返す。 */
	return [NSDictionary dictionary];
}

@end
