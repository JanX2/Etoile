/*
 * WFObjectDrawing.m - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 04/07/07
 * License: Modified BSD license (see file COPYING)
 */


#import "WFObjectDrawing.h"


@implementation WFObject (WFObjectDrawing)

- (NSRect) rect
{
	// FIXME: The following should not be constants:
	float connectionHeight = 12.0;
	float titleHeight = 14.0;
	float iconPadding = 4.0;

	/* Find object height */
	float iconHeight = (48.0 + (iconPadding * 2));

	int inputHeight = ([[self dataInputs] count] * connectionHeight);
	int outputHeight = ([[self dataOutputs] count] * connectionHeight);

	float ioHeight = ((inputHeight > outputHeight) ? inputHeight : outputHeight);
	float height = ((ioHeight > iconHeight) ? ioHeight : iconHeight)
		+ titleHeight;

	/* Find object width */

	float width = 128.0; // TEMP

	/* Create rect */

	NSPoint position = [self position];

	return NSMakeRect(position.x, position.y, width, height);
}

- (NSDictionary *) layout
{
	return nil;
}

- (void) draw
{
	//
	// TODO: Implement object drawing code. Layout values should be taken from
	//       the layout method.
	//

	/* Generate size information */

	/* Draw inputs */

	/* Draw outputs */

	/* Draw icon */

	/* Draw title */
}

@end

