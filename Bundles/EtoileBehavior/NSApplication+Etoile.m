/*
  NSApplication+Etoile.h
	
  Category on NSApplication to implement Etoile specific behavior or 
  integration features.
 
  Copyright (C) 2006 Quentin Mathe
 
  Author:  Quentin Mathe <qmathe@club-internet.fr>
  Date:  November 2006
 
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the Etoile project nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
  THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSApplication+Etoile.h"
#import <GNUstepGUI/GSServicesManager.h>

static NSObject <SCSession> *session = nil;

@interface NSDocumentController (GNUstepPrivate)
+ (BOOL) isDocumentBasedApplication;
@end

@interface NSApplication (EtoilePrivate)
- (void) replyToTerminate: (int)reply;

/* This will be called through NSConnection. */
- (void) application: (NSApplication *) app 
    serviceRequested: (NSString *) service;
@end

/* You should not assume anything about the session, since it can be a user 
   session, a project session or even a system session. The only thing sure
   about it is its protocol SCSession.

   First, the session calls -shouldTerminateOnOperation:. Three replies are 
   possible:
   - Cancel
     the session won't call -terminateOnOperation: afterwards and no other 
     feedback will be requested from the application
   - Later
   - Now
     in both cases, the session will call -terminateOnOperation: immediately and
     waits for feedback through -replyToTerminate:info:
   Second, the sessions calls -terminateOnOperation: when it is necessary:. Two
   replies sent aynchronously are now possible:
   - Cancel
   - Now
     in boths cases, they will be sent through -replyToTerminate: which calls
     -replyToTerminate:info: on the session object.
   if -shouldTerminateOnOperation: replied initially NSTerminateLater, this
   means -terminateOnOperation: will need the user interaction, therefore
   will not return immediately; otherwise it should reply asynchronously but 
   without delay either NSTerminateCancel or NSTerminateNow.
*/

@implementation NSApplication (Etoile)

// NOTE: Returns int, but usually one of the NSApplicationTerminateReply enum
// constants. The use of int allows to add extra return values in future.
- (int) shouldTerminateOnOperation: (NSString *)operation
{
	id delegate = [self delegate];
	int	terminateReply = NSTerminateNow;

	if ([delegate respondsToSelector: @selector(applicationShouldTerminate:)])
	{
		terminateReply = [delegate applicationShouldTerminate: self];
	}
	else
	{
		if ([NSDocumentController isDocumentBasedApplication])
		{
			if ([[NSDocumentController sharedDocumentController] hasEditedDocuments])
				terminateReply = NSTerminateLater;
		}
	}
	
	return terminateReply;
}

- (oneway void) terminateOnOperation: (NSString *)op inSession: (id <SCSession>)theSession
{
	int terminateReply = NSTerminateNow;
	id delegate = [self delegate];

	/*ASSIGN(session, theSession);

	NSDebugLLog(@"Session", @"In session %@, %@ requested to terminate on operation %@", 
		session, [[NSProcessInfo processInfo] processName], op);*/

	// FIXME: The previous code above doesn't work, theSession is bizarely nil.
	// Therefore we rely on the following hack...
	session = [NSConnection 
		rootProxyForConnectionWithRegisteredName: @"/etoileusersession"
		host: nil];
	RETAIN(session);
	
	if ([delegate respondsToSelector: @selector(applicationShouldTerminate:)])
	{
		if([delegate applicationShouldTerminate: self] == NO)
			terminateReply = NSTerminateCancel;
	}
	else if ([NSDocumentController isDocumentBasedApplication])
	{
		// NOTE: The following call blocks the application until the user takes his decision.
		if([[NSDocumentController sharedDocumentController] 
			reviewUnsavedDocumentsWithAlertTitle: _(@"Quit") cancellable:YES])
		{
			/* The user has reviewed all documents */
			terminateReply = NSTerminateNow;
		}
		else
		{
			/* The user has cancelled review or save, this involves cancelling quit thereby log out. */
			terminateReply = NSTerminateCancel;
			
		}
	}
	
	[self replyToTerminate: terminateReply];
	
	if (terminateReply == NSTerminateNow)
		[self replyToApplicationShouldTerminate: YES];
}

- (void) replyToTerminate: (int)reply
{
	NSNumber *pid = [NSNumber numberWithInt: [[NSProcessInfo processInfo] processIdentifier]];
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: 
		[[NSProcessInfo processInfo] processName], @"NSApplicationName",
		pid, @"NSApplicationProcessIdentifier", nil];
	
	NSDebugLLog(@"Session", @"In session %@, %@ replies to terminate: %i", session,
		[info objectForKey: @"NSApplicationName"], reply);

	[session replyToTerminate: reply info: info];
	RELEASE(session);
}

- (void) application: (NSApplication *) app 
    serviceRequested: (NSString *) service
{
  /* We need to be application:... in order to receive call remotely.
     See GSServicesManager for reasons. */
  NSLog(@"service %@", service);
  GSServicesManager *gm = [GSServicesManager manager];
  /* Let find the menu item first */
  NSArray *array = [service componentsSeparatedByString: @"/"];
  if ([array count] == 1)
  {
    /* Must an item of service menu. */
    NSMenu *menu = [NSApp servicesMenu];
    if (menu)
    {
      id <NSMenuItem> item = [menu itemWithTitle: [array objectAtIndex: 0]];
      if (item)
      {
	NSLog(@"Found imte %@", item);
	[gm doService: item];
      }
    }
  }
  else if ([array count] == 2)
  {
    /* Must an item of submenu of service menu */
  }
  else
  {
    /* Do nothing */
    NSLog(@"Cannot find service menu item for %@", service);
  }
}
@end
