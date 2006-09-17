/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "DocumentTools.h"
#import "ToolViewBuilder.h"

/**
 * Non-Public methods.
 */
@interface DocumentTools (Private)
- (void) myCreateControls;
- (NSButton*) myCreateButtonWithImage: (NSString*)anImageName;
- (NSButton*) myCreateToggleButtonWithImage: (NSString*)anImageName;
@end


@implementation DocumentTools

- (id) initWithFrame: (NSRect)aFrame target: (id)aTarget
{
   if (![super initWithFrame: aFrame])
      return nil;
   
   [self myCreateControls];
   [self setTarget: aTarget];

   return self;
}

- (void) setTarget: (id)aTarget
{
   target = aTarget;
   
   [firstBT setAction: @selector(firstPage:)];
   [firstBT setTarget: target];
   [previousBT setAction: @selector(previousPage:)];
   [previousBT setTarget: target];
   [nextBT setAction: @selector(nextPage:)];
   [nextBT setTarget: target];
   [lastBT setAction: @selector(lastPage:)];
   [lastBT setTarget: target];

   [pageTF setAction: @selector(takePageFrom:)];
   [pageTF setTarget: target];
   
   [zoomTF setAction: @selector(takeZoomFrom:)];
   [zoomTF setTarget: target];
   [zoomInBT setAction: @selector(zoomIn:)];
   [zoomInBT setTarget: target];
   [zoomOutBT setAction: @selector(zoomOut:)];
   [zoomOutBT setTarget: target];
   
   [fitWidthBT setAction: @selector(toggleFitWidth:)];
   [fitWidthBT setTarget: target];
   [fitHeightBT setAction: @selector(toggleFitHeight:)];
   [fitHeightBT setTarget: target];
   [fitPageBT setAction: @selector(toggleFitPage:)];
   [fitPageBT setTarget: target];
}

- (void) setPage: (int)aPage
{
  [pageTF setStringValue: [NSString stringWithFormat: @"%d", aPage]];
}

- (void) setPageCount: (int)aPageCount
{
   [nbpageTF setStringValue: [NSString stringWithFormat:@"of %d", aPageCount]];
}

- (void) setZoom: (float)aFactor
{
   NSString* text = [NSString stringWithFormat: @"%.0f %%", aFactor];
   [zoomTF setStringValue: text];
}

- (void) setResizePolicy: (ResizePolicy)aPolicy
{
   [fitWidthBT setState: (aPolicy == ResizePolicyFitWidth ? NSOnState : NSOffState)];
   [fitHeightBT setState: (aPolicy == ResizePolicyFitHeight ? NSOnState : NSOffState)];
   [fitPageBT setState: (aPolicy == ResizePolicyFitPage ? NSOnState : NSOffState)];
}

- (void) focusPageField
{
   [[self window] makeFirstResponder: pageTF];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation DocumentTools (Private)

- (void) myCreateControls
{
   firstBT = [self myCreateButtonWithImage: @"First.png"];
   previousBT = [self myCreateButtonWithImage: @"Previous.png"];
   nextBT = [self myCreateButtonWithImage: @"Next.png"];
   lastBT = [self myCreateButtonWithImage: @"Last.png"];
   zoomInBT = [self myCreateButtonWithImage: @"ZoomIn.png"];
   zoomOutBT = [self myCreateButtonWithImage: @"ZoomOut.png"];
   fitPageBT = [self myCreateToggleButtonWithImage: @"FitPage.png"];
   fitWidthBT = [self myCreateToggleButtonWithImage: @"FitWidth.png"];
   fitHeightBT = [self myCreateToggleButtonWithImage: @"FitHeight.png"];
   
   pageTF = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];
   [pageTF setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
   [pageTF setAlignment: NSCenterTextAlignment];
   [pageTF sizeToFit];
   [pageTF setFrameSize: NSMakeSize(40, NSHeight([pageTF frame]))];

   nbpageTF = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];
   [nbpageTF setEditable: NO];
   [nbpageTF setSelectable: NO];
   [nbpageTF setBordered: NO];
   [nbpageTF setBezeled: NO];
   [nbpageTF setDrawsBackground: NO];
   [nbpageTF setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
   [nbpageTF setAlignment: NSLeftTextAlignment];
   [nbpageTF setStringValue: @"of 9999"];
   [nbpageTF sizeToFit];
   
   zoomTF = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];
   [zoomTF setFont: [pageTF font]];
   [zoomTF setAlignment: NSCenterTextAlignment];
   [zoomTF sizeToFit];
   [zoomTF setFrameSize: NSMakeSize(55, NSHeight([zoomTF frame]))];
   
   ToolViewBuilder* builder = [ToolViewBuilder builderWithView: self yBorder: 2.0];
   [builder setSpacing: 0.0];
   [[builder advance: 5.0] addViewVerticallyCentered: firstBT];
   [builder addViewVerticallyCentered: previousBT];
   [builder addViewVerticallyCentered: pageTF];
   [[builder advance: 2.0] addViewVerticallyCentered: nbpageTF];
   [builder addViewVerticallyCentered: nextBT];
   [builder addViewVerticallyCentered: lastBT];
   [[builder advance: 25.0] addViewVerticallyCentered: zoomOutBT];
   [[builder advance: 1.0] addViewVerticallyCentered: zoomTF];
   [[builder advance: 1.0] addViewVerticallyCentered: zoomInBT];
   
   [[builder advance: 35.0] addViewVerticallyCentered: fitWidthBT];
   [builder addViewVerticallyCentered: fitHeightBT];
   [builder addViewVerticallyCentered: fitPageBT];
}

- (NSButton*) myCreateButtonWithImage: (NSString*)anImageName
{
   NSButton* button = [[NSButton alloc] initWithFrame: NSZeroRect];
   [button setImage: [NSImage imageNamed: anImageName]];
   [button setImagePosition: NSImageOnly];
   [button setButtonType: NSMomentaryLight];
   [button setBordered: NO];
   [button setRefusesFirstResponder: YES];
   [button sizeToFit];

   // all buttons are size 25 points wide to provide enough
   // "hit" area for users
   [button setFrameSize: NSMakeSize(25, NSHeight([button frame]))];
   
   return [button autorelease];
}

- (NSButton*) myCreateToggleButtonWithImage: (NSString*)anImageName
{
   NSButton* button = [self myCreateButtonWithImage: anImageName];
   [button setButtonType: NSToggleButton];
   
   NSString* extension = [anImageName pathExtension];
   NSString* base = [anImageName stringByDeletingPathExtension];
   NSString* alternateImage = [NSString stringWithFormat: @"%@On.%@", base, extension];
   [button setAlternateImage: [NSImage imageNamed: alternateImage]];

   return button;
}

@end
