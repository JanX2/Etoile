/*
   Project: Installer

   Copyright (C) 2004 Frederico Munoz

   Author: Frederico S. Munoz

   Created: 2004-06-22 15:45:55 +0100 by fsmunoz

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <AppKit/AppKit.h>
@protocol Package <NSObject>
- (BOOL) handlesPackage: (NSString *)pkgPath;
- (NSString *) packageName;
- (NSString *) packageVersion;
- (BOOL) isInstalled;
- (NSString *) packageDescription;
- (NSString *) packageAuthor;
- (NSString *) packageContents;
- (NSString *) packagePlatform;
- (NSString *) packageSizes;
- (NSImage *) packageIcon;
- (NSString *) packageLicence;
- (NSString *) packageLocation;
- (BOOL) installPackage: (id) sender;
- (BOOL) isRelocatable;
- (int) currentStep;
- (int) totalSteps;
- (BOOL) setPackageLocation: (NSString *) packageLocation;
- (BOOL) installReceipt: (NSData*) receiptData;
- (BOOL) preInstall;
- (BOOL) postInstall;
@end
