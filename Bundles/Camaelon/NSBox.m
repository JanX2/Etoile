#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"

@implementation NSBox (theme)

- (BOOL) isOpaque { return NO; }

- (void) drawRect: (NSRect)rect
{
//  _title_rect.origin.x=rect.origin.x + 8;
//  rect.size.height -= _title_rect.size.height -2;
  rect.size.height -= 4;

  // Draw border

  switch (_border_type)
  {
  	case NSNoBorder:
	break;
	case NSLineBorder:
  		[GSDrawFunctions drawBox: rect on: self];
		break;
	case NSBezelBorder:
  		[GSDrawFunctions drawBox: rect on: self];
		break;
	case NSGrooveBorder:
  		[GSDrawFunctions drawBox: rect on: self];
		break;
  }

  // Draw title
  if (_title_position != NSNoTitle)
    {
      [GSDrawFunctions drawTitleBox: _title_rect on: self];
      [_cell drawWithFrame: _title_rect inView: self];
    }
}

@end

