/*
 **  PTYTabViewItem.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Setlur
 **
 **  Project: iTerm
 **
 **  Description: NSTabViewItem subclass. Implements attributes for label.
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

#import <iTerm/PTYTabView.h>
#import <iTerm/PTYTabViewItem.h>

#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0

@implementation PTYTabViewItem

- (id) initWithIdentifier: (id) anIdentifier
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    
    dragTarget = NO;
    
    return([super initWithIdentifier: anIdentifier]);
}

- (void) dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    
    [warningImage release];
    
    [labelAttributes release];
    labelAttributes = nil;
    
    [super dealloc];
}

// Override this to be able to customize the label attributes
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)tabRect
{
    NSString *imagePath;
    NSBundle *thisBundle = [NSBundle bundleForClass: [self class]];
    
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabViewItem: -drawLabel(bell=%@)",bell?@"YES":@"NO");
#endif
    
    if(labelAttributes != nil)
    {
        NSMutableParagraphStyle *pstyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [pstyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        NSMutableAttributedString * attributedLabel = [[[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d: %@", [[self tabView] indexOfTabViewItem: self] + 1, [self label]] attributes: labelAttributes] autorelease];
        
        // If we are a current drag target, add foreground and background colors
        if(dragTarget)
        {
            [attributedLabel addAttribute: NSForegroundColorAttributeName value: [NSColor greenColor] range: NSMakeRange(0, [attributedLabel length])];
            [attributedLabel addAttribute: NSBackgroundColorAttributeName value: [NSColor blackColor] range: NSMakeRange(0, [attributedLabel length])];
        }
        
        [attributedLabel addAttribute:NSParagraphStyleAttributeName value:pstyle range:NSMakeRange(0, [attributedLabel length])];
        
        if (bell) 
        {
            int tabViewType = [[self tabView] tabViewType];
            
            if(tabViewType == NSTopTabsBezelBorder || tabViewType == NSBottomTabsBezelBorder)
            {
                if(warningImage == nil)
                {
                    imagePath = [thisBundle pathForResource:@"important" ofType:@"png"];
                    warningImage = [[NSImage alloc] initByReferencingFile: imagePath];
                }
                
                [warningImage compositeToPoint:NSMakePoint(tabRect.origin.x,tabRect.origin.y+16) operation:NSCompositeSourceOver];
                tabRect.origin.x+=18;
                tabRect.size.width-=18;
            }
            else if(tabViewType == NSRightTabsBezelBorder)
            {
                if(warningImage == nil)
                {
                    imagePath = [thisBundle pathForResource:@"important_r" ofType:@"png"];
                    warningImage = [[NSImage alloc] initByReferencingFile: imagePath];
                }
                
                [warningImage compositeToPoint:NSMakePoint(tabRect.origin.x + 12,tabRect.origin.y + 15)
                                                   operation:NSCompositeSourceOver];
                tabRect.origin.x+=14;
                tabRect.size.width-=14;
            }
            else if(tabViewType == NSLeftTabsBezelBorder)
            {
                if(warningImage == nil)
                {
                    imagePath = [thisBundle pathForResource:@"important_l" ofType:@"png"];
                    warningImage = [[NSImage alloc] initByReferencingFile: imagePath];
                }
                
                [warningImage compositeToPoint:NSMakePoint(tabRect.origin.x - 3,tabRect.origin.y)
                                                                 operation:NSCompositeSourceOver];
                tabRect.origin.x+=15;
                tabRect.size.width-=15;
            }
            [attributedLabel drawInRect: tabRect];
        }
        else 
            [attributedLabel drawInRect: tabRect]; 
    }
    else
    {
        // No attributed label, so just call the parent method.
        [super drawLabel: shouldTruncateLabel inRect: tabRect];
    }
}

- (NSSize) sizeOfLabel:(BOOL)shouldTruncateLabel
{
    NSSize aSize;
    NSMutableAttributedString *attributedLabel;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabViewItem: -sizeOfLabel");
#endif
    
    if(labelAttributes != nil)
    {
        attributedLabel = [[[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d: %@", [[self tabView] indexOfTabViewItem: self] + 1, [self label]] attributes: labelAttributes] autorelease];
        // If we are a current drag target, add foreground and background colors
        if(dragTarget)
        {
            [attributedLabel addAttribute: NSForegroundColorAttributeName value: [NSColor greenColor] range: NSMakeRange(0, [attributedLabel length])];
            [attributedLabel addAttribute: NSBackgroundColorAttributeName value: [NSColor blackColor] range: NSMakeRange(0, [attributedLabel length])];
        }
        aSize = [attributedLabel size];
        
        if (bell)
            aSize.width+=18;
    }
    else
        aSize = [super sizeOfLabel: shouldTruncateLabel];
    
    if (aSize.width > [((PTYTabView*)[self tabView]) maxLabelSize]) 
        aSize.width = [((PTYTabView*)[self tabView]) maxLabelSize];
    
    return (aSize);
}

// set/get custom label
- (NSDictionary *) labelAttributes
{
    return (labelAttributes);
}

- (void) setLabelAttributes: (NSDictionary *) theLabelAttributes
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabViewItem: -setLabelAttributes");
#endif
    
    // Do this only if there is a change
    if([labelAttributes isEqualToDictionary: theLabelAttributes])
        return;
    
    [labelAttributes release];
    labelAttributes = [theLabelAttributes retain];
    
    bell=NO;
    
    // redraw the label
    [self setLabel: [[[self label] copy] autorelease]];
}

// Called when when another tab is being dragged over this one
- (void) becomeDragTarget
{
    dragTarget = YES;
    
    // redraw the label
    [self setLabel: [[[self label] copy] autorelease]];
}

// Called when another tab is moved away from this one
- (void) resignDragTarget
{
    dragTarget = NO;
    
    // redraw the label
    [self setLabel: [[[self label] copy] autorelease]];
}

- (void) setBell:(BOOL)b
{
    // do this only if there is a change
    if(bell == b)
        return;
    
    bell=b;
    
    // redraw the label
    [self setLabel: [[[self label] copy] autorelease]];
}

@end
