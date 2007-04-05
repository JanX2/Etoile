/*
 * WFDocument.h - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 03/27/07
 * License: Modified BSD license (see file COPYING)
 */


#import <AppKit/AppKit.h>


@interface WFDocument : NSDocument
{
	id workflowView;
	id scrollView;
}
@end

