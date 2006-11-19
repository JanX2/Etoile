#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ExtendedWorkspaceKit/ExtendedWorkspaceKit.h>

/*
 * Initialise and go!
 */

int main(int argc, const char *argv[]) 
{
  	[EXFileManager poseAs: [NSFileManager class]];
	return NSApplicationMain (argc, argv);
}
