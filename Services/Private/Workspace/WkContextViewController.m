/* 
   WkContextViewController.m

   Context component view controller
   
   Copyright (C) 2004 Quentin Mathe

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: July 2004
   
   This file is part of the Etoile desktop environment.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ExtendedWorkspaceKit/ExtendedWorkspaceKit.h>
#import "WkContextViewController.h"
#import "WkContextTableViewController.h"

@interface WkContextViewControllerPH : NSObject
{

}

- (id) initWithView: (NSView *)view;

@end

@implementation WkContextViewControllerPH

- (id) init
{
    return [self initWithView: nil];
}

- (id) initWithView: (NSView *)view
{
    NSZone *z = [self zone];
    
    RELEASE(self);
    
    if ([view isKindOfClass: [NSTableView class]])
    {
        self = [[WkContextTableViewController allocWithZone: z] initWithView: view];
        return self;
    }
    
    return nil;
}
@end

@implementation WkContextViewController

/*
+ (void) initialize
{
    if (self == [ViewerController class])
    {

    }
}
 */

- (id) alloc
{
    if([self isEqual: [WkContextViewController class]])
        return [WkContextViewControllerPH alloc];
    else
        return [NSObject alloc];
}

- (id) allocWithZone: (NSZone *)zone
{
    if([self isEqual: [WkContextViewController class]])
        return [WkContextViewControllerPH allocWithZone: zone];
    else
        return [NSObject allocWithZone: zone];
}

- (id) initWithView: (NSView *)view
{
   if ((self = [super init])  != nil)
    {
        return self;
    }
  
  return nil;
}

 
- (void) reload
{
    //[self subclassResponsability:_cmd];
}

/*
 * Accessors
 */
 
- (EXContext *) context
{
   return context;
}
 
- (void) setContext: (EXContext *)aContext
{
    ASSIGN(context, context);
    ASSIGN(subcontexts, [context subcontexts]);
    ASSIGN(subcontextsToView, [context visibleSubcontexts]);
}

@end
