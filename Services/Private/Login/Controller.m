/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "Controller.h"
#import "Background.h"
#import <unistd.h>

@implementation Controller

- (void) awakeFromNib
{
	[self setView: loginView];
	busyImageCounter = 0;
	busy = NO;
	[self displayHostname];
	[[NSCursor arrowCursor] set];
}

- (void) setView: (NSView*) aView
{
	[view removeFromSuperview];
	view = aView;
	[[window contentView] addSubview: view];	
}

- (void) applicationWillFinishLaunching: (NSNotification*) notification
{
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
	Background* bgd = [Background background];
	[bgd set];
	[window makeKeyAndOrderFront: self];
	gdm = [GDMClient new];
	[gdm setDelegate: self];
	[gdm beginning];
}

- (void) gdmError: (id) sender
{
	waggleCount = 0;
	add = 5;
	originalPosition = [window frame];
	busy = NO;
	[self waggle: nil];	
	[NSTimer scheduledTimerWithTimeInterval: (1.0/400.0)
		target: self selector: @selector(waggle:) userInfo: nil repeats: YES]; 
}

- (void) gdmLogged: (id) sender
{
	[gdm release];
	exit (0);
}

- (void) setBusyImage
{
	busyImageCounter = busyImageCounter % 8;
	
	[imageView setImage: [NSImage imageNamed: [NSString stringWithFormat: @"Loader%d.png", ++busyImageCounter]]];	
	[imageView setNeedsDisplay: YES];
	if (busy) [self performSelector: @selector(setBusyImage) withObject: nil afterDelay: 0.1];
}

- (void) login: (id)sender
{
	busy = YES;
	busyImageCounter = 0;
	[self setView: busyView];
	[self setBusyImage];
	//[self performSelector: @selector(doLogin) withObject: nil afterDelay: 0.1];
	[NSThread detachNewThreadSelector: @selector(doLogin) toTarget: self withObject: nil];
}

- (void) doLogin
{
	if ([gdm loginWithUsername: [loginTextfield stringValue]
		 password: [passwordTextfield stringValue]
		 session: [sessionPopUpButton stringValue]])
	{
		//[self gdmLogged: self];
		[self performSelectorOnMainThread: @selector(gdmLogged:) withObject: nil waitUntilDone: NO];	
	}
	else
	{
		//[self gdmError: self];
		[self performSelectorOnMainThread: @selector(gdmError:) withObject: nil waitUntilDone: NO];	
	}

	[NSThread exit];
}

- (void) waggle: (NSTimer*) timer
{
	waggleCount++;
	if (waggleCount > 100)
	{
		[timer invalidate];
		[window setFrameOrigin: originalPosition.origin];
		[self setView: loginView];
		[[Background background] redraw];
		[window makeKeyAndOrderFront: self];
	}
	else
	{
		NSRect rect = [window frame];
		if (waggleCount % 10 == 0) add = -1 * add;
		[window setFrameOrigin:	NSMakePoint (rect.origin.x+add, rect.origin.y)];	
		[[Background background] setNeedsDisplayInRect: rect];
		[window makeKeyAndOrderFront: self];
	}
}

- (void) shutdown: (id)sender
{
  /*	
  //[window orderOut: self];
  int choice = NSRunAlertPanel (@"Shut down",
		  @"Are you sure you want to Shut down the computer ?",
		  @"Cancel", @"Shut down!", nil);

  if (choice == NSAlertAlternateReturn)
  {
	[gdm release];
	exit (DISPLAY_HALT);
  }
  //[window makeKeyAndOrderFront: self];
  */
  [gdm release];
  exit (DISPLAY_HALT);
}


- (void) reboot: (id)sender
{
  /*
  //[window orderOut: self];
  int choice = NSRunAlertPanel (@"Reboot",
		  @"Are you sure you want to Reboot the computer ?",
		  @"Cancel", @"Reboot!", nil);

  if (choice == NSAlertAlternateReturn)
  {
  	[gdm release];
  	exit (DISPLAY_REBOOT);
  }		
  //[window makeKeyAndOrderFront: self];
  */
  	[gdm release];
  	exit (DISPLAY_REBOOT);
}

- (void)displayHostname
{
  char hostname[256], displayname[256];
  int  namelen = 256, index = 0;
  NSString *host_name = nil;

  // Initialize hostname
  gethostname( hostname, namelen );
  for(index = 0; index < 256 && hostname[index] != '.'; index++)
    {
      displayname[index] = hostname[index];
    }
  displayname[index] = 0;
  host_name = [NSString stringWithCString: displayname];
  [hostnameText setStringValue: host_name];
}

@end
