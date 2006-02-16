/* Desktop.h
 *  
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: May 2004
 *
 * This file is part of the GNUstep Desktop application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef WM_APPLICATION_H
#define WM_APPLICATION_H

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "WINGs/WINGsP.h"

struct W_Application WMApp;

int WMCurrentScreen();

@interface WMApplication : NSObject 
{
  NSString *applicationName;
  NSMenu *workspacesMenu;
  NSMenu *switches;

  /* Debug */
  NSWindow *window;
}

+ (WMApplication *) wmApplication;

- (void) initializeWithName: (NSString *) name 
          numberOfArguments: (int *)argc
	          arguments: (char **)argv;
- (BOOL) isApplicationInitialized;
- (NSString *) applicationName;

/* Info */
- (void) showGNUstepPanel: (id) sender;
- (void) showInfoPanel: (id) sender;
- (void) showLegalPanel: (id) sender;

/* Execute */
- (void) executeExternalProgram: (id) sender;
- (void) executeShellCommand: (id) sender;

/* Workspaces */
- (void) newWorkspace: (id) sender;
- (void) destroyLastWorkspace: (id) sender;
- (void) switchWorkspace: (id) sender;
- (void) renameWorkspace: (id) sender; /* rename current one */

/* Switches */
- (NSMenu *) switchMenu;
- (void) switchWindow: (id) sender;

/* Windows */
- (void) refresh: (id) sender;
- (void) arrangeIcons: (id) sender;
- (void) showAll: (id) sender;
- (void) hideOthers: (id) sender;

/* Session */
- (void) saveSession: (id) sender;
- (void) clearSession: (id) sender;
- (void) restartWindowMaker: (id) sender;
- (void) restart: (id) sender;
- (void) shutdown: (id) sender;
- (void) exit: (id) sender;

@end

#endif // WM_APPLICATION_H


