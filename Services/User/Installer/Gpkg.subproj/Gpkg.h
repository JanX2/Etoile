/*
   Project: Gpkg

   Copyright (C) 2004 Frederico Munoz

   Author: Frederico S. Munoz

   Created: 2004-06-22 15:45:21 +0100 by fsmunoz

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

#ifndef _GPKG_H_
#define _GPKG_H_

#include <Foundation/Foundation.h>
#include "../Package.h"

@interface Gpkg : NSObject <Package>
{
 NSMutableDictionary *infoValues;
 NSString *copyright;
 NSData *bomContents;
 NSString *packagePath;
 NSString *packageSizes;
 NSString *packageTempDir;
 NSString *installerTempDir;
 NSString *packageArchivePath;
 NSString *packageTempArchivePath;
 NSString *appDirectoryName;
 NSImage *icon;
 NSString *archiveFormat;
 NSDictionary *infoPlist;
 NSDictionary *descriptionPlist;
 NSDictionary *bom;
 NSString *paxArchivePath;
 NSString *license;
 NSString *welcome;
 NSString *installLocation;
 int currentStep;
 int totalSteps;
}
- _getAllInfo;
- _uncompressPackage;
- (BOOL) atomicallyCopyPath: (NSString *) sourcePath toPath: (NSString *) destinationPath ofType: (NSString *)fileType  withAttributes: (NSDictionary *) attributes;
@end

#endif // _GPKG_H_

