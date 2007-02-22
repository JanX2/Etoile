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

#import "ProxyComponent.h"

@implementation ProxyComponent

// ---------------------------------------
//    init and dealloc
// ---------------------------------------

-(id) init
{
    if ((self = [super init]) != nil) {
        RETAIN(hostnameControl);
        RETAIN(portControl);
        RETAIN(proxyUseButton);
        
        ASSIGN(defaults, [NSUserDefaults standardUserDefaults]);
        
        [self updateGUI];
    }
    
    return self;
}

-(void) dealloc
{
    DESTROY(hostnameControl);
    DESTROY(portControl);
    DESTROY(proxyUseButton);
    DESTROY(defaults);
}

// ---------------------------------------
//    Overriding stuff from the superclass
// ---------------------------------------

-(NSString*) prefPaneName
{
    return @"Proxy";
}

-(NSImage*) prefPaneIcon
{
    return [NSImage imageNamed: @"WebProxy"];
}

// ---------------------------------------
//    Handles actions invoked from the GUI and sets user defaults
// ---------------------------------------

-(void) hostnameChanged: (id)sender
{
    NSString* hostStr = [hostnameControl stringValue];
    
    [defaults setObject: hostStr forKey: @"ProxyHostname"];
    
    [self updateGUI];
}

-(void) portChanged: (id)sender
{
    int num = [[portControl stringValue] intValue];
    
    if (num == 0) {
        num = 3128;
    }
    
    [defaults setInteger: num forKey: @"ProxyPort"];
    [self updateGUI];
}

-(void) proxyUseButtonChanged: (id)sender
{
    int state = [proxyUseButton state];
    
    NSAssert1(state == NSOnState || state == NSOffState, @"Bad button state %d", state);
    
    BOOL enabled;
    if (state == NSOnState) {
        enabled = YES;
    } else { // NSOffState
        enabled = NO;
    }
    
    [defaults setBool: enabled forKey: @"ProxyEnabled"];
    [self updateGUI];
}

// ---------------------------------------
//    Updates the GUI from the user defaults
// ---------------------------------------

-(void) updateGUI
{
    [hostnameControl setStringValue: [defaults stringForKey: @"ProxyHostname"]];
    [portControl setIntValue: [defaults integerForKey: @"ProxyPort"]];
    [proxyUseButton setIntValue: [defaults boolForKey: @"ProxyEnabled"]];
}

@end
