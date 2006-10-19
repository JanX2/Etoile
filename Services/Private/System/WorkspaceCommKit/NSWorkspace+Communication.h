#ifndef _NSWORKSPACE_WORKSPACE_COMM_H_
#define _NSWORKSPACE_WORKSPACE_COMM_H_

#import <AppKit/NSWorkspace.h>

@interface NSWorkspace (WorkspaceComm)

- connectToApplication: (NSString *) appName
                launch: (BOOL) launchFlag;

- connectToWorkspaceApplicationLaunch: (BOOL) launchFlag;

@end

#endif // _NSWORKSPACE_WORKSPACE_COMM_H_
