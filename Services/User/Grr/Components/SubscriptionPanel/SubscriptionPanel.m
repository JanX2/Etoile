/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "SubscriptionPanel.h"

#import "Database.h"

@implementation SubscriptionPanel

// -----------------------------------------------------
//    initialisation
// -----------------------------------------------------

+(id) shared
{
    static SubscriptionPanel* controller = nil;
    
    if (controller == nil) {
        ASSIGN(controller, [SubscriptionPanel new]);
    }
    
    return controller;
}

-(void) dealloc
{
    DESTROY(panel);
    DESTROY(urlField);
    DESTROY(subscriptionButton);
    DESTROY(referenceElement);
    
    [super dealloc];
}


// ------------------------------------------------------------
//    SubscriptionPanel protocol (see FeedOperations component)
// ------------------------------------------------------------

-(void) show
{
    [panel makeKeyAndOrderFront: self];
}

-(void) setReferenceElement: (id<DatabaseElement>) anElement
{
    ASSIGN(referenceElement, anElement);
}


// ------------------------------------------------------------
//    helper methods
// ------------------------------------------------------------

-(BOOL) subscribeToURL: (NSURL*) url
{
    BOOL result = NO;
    NSParameterAssert([url isKindOfClass: [NSURL class]]);
    
    if (referenceElement != nil) {
        if ([referenceElement conformsToProtocol: @protocol(Category)]) {
            result = [[Database shared] subscribeToURL: url
                                            inCategory: (id<Category>)referenceElement];
        } else {
            NSAssert1(
                [referenceElement conformsToProtocol: @protocol(DatabaseElement)],
                @"The reference element %@ is not a DatabaseElement.", referenceElement
            );
            
            // The category to put the subscription into is the super category of the
            // reference element, the index is one below the reference element.
            id<Category> category = [referenceElement superElement];
            int index = 0;
            if (category != nil) {
                index = [[category elements] indexOfObject: referenceElement] + 1;
            } else {
                // The ref elements category was nil, so it's a top level element in the database.
                index = [[[Database shared] topLevelElements] indexOfObject: referenceElement];
                
                NSAssert(index != NSNotFound, @"The reference element points to a bad super element!");
                index ++;
            }
            
            result = [[Database shared] subscribeToURL: url
                                            inCategory: category
                                              position: index];
        }
    } else {
        result = [[Database shared] subscribeToURL: url];
    }
    
    return result;
}

// ------------------------------------------------------------
//    GUI actions
// ------------------------------------------------------------

-(IBAction) subscribe: (id)sender
{
    NSLog(@"URL: %@", [urlField stringValue]);
    NSURL* URL = [NSURL URLWithString: [urlField stringValue]];
    
    if (URL == nil) {
        NSRunAlertPanel(
            NSLocalizedString(@"Subscription failed", @"title of an alert dialog"),
            NSLocalizedString(
                @"The string you provided is not in URL format.",
                @"failure reason in alert dialog"
            ),
            _(@"Ok"), nil, nil
        );
    } else {
        // URL is valid.
        
        if ([self subscribeToURL: URL]) {
            // success
            [panel close];
        } else {
            // could not subscribe
            NSRunAlertPanel(
                NSLocalizedString(@"Subscription failed", @"alert message title"),
                NSLocalizedString(
                    @"Your subscription failed. Possible reasons include:\n"
                    @"\t- There's not a RSS or Atom document stored at this URL\n"
                    @"\t- Incorrect Web Proxy settings\n",
                    @"failure reason in alert dialog"
                ),
                _(@"Ok"), nil, nil
            );
        }
    }
}

@end
