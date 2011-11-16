#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>

@interface NesedahTheme : GSTheme
@end

@implementation NesedahTheme

- (NSColor *) menuBackgroundColor
{
	return [NSColor lightGrayColor];
}

- (NSColor *) menuItemBackgroundColor
{
	return [NSColor clearColor];
}

- (NSColor *) menuBorderColor
{
	return [NSColor grayColor];
}

- (NSColor *) menuBorderColorForEdge: (NSRectEdge)edge isHorizontal: (BOOL)horizontal
{
	if (horizontal && edge != NSMinYEdge)
		return nil;

	return [self menuBorderColor];
}

- (NSColor *) menuSeparatorColor
{
	return [NSColor grayColor];
}

- (CGFloat) menuSeparatorInset
{
	return 0.0;
}

- (BOOL) drawsBorderForMenuItemCell: (NSCell *)cell 
                              state: (GSThemeControlState)state
                       isHorizontal: (BOOL)horizontal
{
	return NO;
}

/*- (void) drawSeparatorItemWithFrame:(NSRect)cellFrame
                            inView:(NSView *)controlView
{
  [[NSColor lightGrayColor] set];
  PSmoveto(NSMinX(cellFrame) + 2, NSMidY(cellFrame));
  PSrlineto(NSWidth(cellFrame) - 4, 0);
  PSstroke();

  [[NSColor whiteColor] set];
  PSmoveto(NSMinX(cellFrame) + 2, NSMidY(cellFrame) - 1);
  PSrlineto(NSWidth(cellFrame) - 4, 0);
  PSstroke();
}*/

- (NSButtonCell*) cellForScrollerArrow: (NSScrollerArrow)arrow
			    horizontal: (BOOL)horizontal
{
  NSButtonCell	*cell;
  NSString	*name;
  
  cell = [NSButtonCell new];
  [cell setBordered: NO];
  if (horizontal)
    {
      if (arrow == NSScrollerDecrementArrow)
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowLeft"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowLeftH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerLeftArrow;
	}
      else
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowRight"]];
	  [cell setAlternateImage: [NSImage imageNamed: @"common_ArrowRightH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerRightArrow;
	}
    }
  else
    {
      if (arrow == NSScrollerDecrementArrow)
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowUp"]];
	  //[cell setAlternateImage: [NSImage imageNamed: @"common_ArrowUpH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerUpArrow;
	}
      else
	{
	  [cell setHighlightsBy:
	    NSChangeBackgroundCellMask | NSContentsCellMask];
	  [cell setImage: [NSImage imageNamed: @"common_ArrowDown"]];
	  //[cell setAlternateImage: [NSImage imageNamed: @"common_ArrowDownH"]];
	  [cell setImagePosition: NSImageOnly];
          name = GSScrollerDownArrow;
	}
    }
  [self setName: name forElement: cell temporary: YES];
  RELEASE(cell);
  return cell;
}

@end

@interface NSColor (Nesedah)
+ (NSColor *) selectedMenuItemColor;
+ (NSColor *) selectedMenuItemTextColor;
@end

@implementation NSColor (Nesedah)
+ (NSColor *) selectedMenuItemColor
{
	return [NSColor yellowColor];
}

+ (NSColor *) selectedMenuItemTextColor
{
	return [NSColor redColor];
}
@end
