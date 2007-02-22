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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "../DatabaseOperations/SubscriptionPanelProtocol.h"

#ifdef ETOILE
#import <EtoileFoundation/UKNibOwner.h>
#else
#import "UKNibOwner.h"
#endif

/**
 * The controller for the subscription panel.
 */
@interface SubscriptionPanel : UKNibOwner <SubscriptionPanel>
{
    IBOutlet NSPanel* panel;
    IBOutlet NSTextField* urlField;
    IBOutlet NSButton* subscriptionButton;
    
    id<DatabaseElement> referenceElement;
}

+(id) shared;

-(IBAction) subscribe: (id)sender;

@end

