/*
    BundleExtensionLoader.h

    Interface declaration of the BundleExtensionLoader class for the
    ProjectManager application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import <Foundation/NSObject.h>

#import <Foundation/NSPathUtilities.h>

@class NSString, NSDictionary;

/** @def MainBundleDomainMask

 If this is specified in the domain search mask, the bundle
loader also look into the main bundle. It looks for matching
bundles with the means of NSBundle's `-pathsForResourcesOfType...'
method.
*/
enum {
  MainBundleDomainMask = 0x00010000
};

/** @class BundleExtensionLoader
 A simple interface for locating extending bundles for apps.

 This class allows an application easily obtain all the bundles
in the filesystem that match it's specified search criteria.
This is used mainly by applications that use bundles to flexibly
extended their basic functionality (for example the Preferences
app uses bundles for it's preferences modules).

 @author Saso Kiselkov
*/
@interface BundleExtensionLoader : NSObject

 /// Returns a shared instance of BundleExtensionLoader.
+ shared;

 /**
    Searches the filesystem for extension bundles.

 @param bundleFileExtension Specifies the required bundle file extension.
   Specifying `nil' matches any filename.
 @param protocols The protocols to which the prinicipal class is required
   to conform. Passing `nil' causes any class to match. Please
   be careful when specifying a protocol and not specifying a bundle
   extension or bundle subdirectory - you could end up loading _all_
   the relocatable code of all bundles in the filesystem.
 @param subDirName Specifying this will cause the search for matching
   bundles not to occur in the ``Library/Bundles'' and
   ``Library/ApplicationSupport'' but in the specified subdirectory
   of these domain directories.
 @param domainMask Explicitly specifies which domains to look in.
   Passing a zero domain mask will cause the receiver to automatically
   determine the search mask with the help of the defaults system.
   See description for the `defaultsKey' argument.
 @param defaultsKey If automatic detection of domains has been requested,
  the receiver interrogates the defaults database to automagically
  determine the searched domains. The function of this argument
  is best described on an example: if defaultsKey = @"Features" and
  the defaults database doesn't contains any of the following keys set to YES:
- "Features-ExcludeLoadingFromSystem"
- "Features-ExcludeLoadingFromLocal"
- "Features-ExcludeLoadingFromNetwork"
- "Features-ExcludeLoadingFromUser"
- "Features-ExcludeLoadingFromMainBundle"
.
  then all the domains will be searched. If any of the above keys
  is set to YES, that specific domain will not be searched. I.e.
  by default all domains are searched.
  If automatic detection is requested and defaultsKey = nil, then
  defaultsKey = @"BundleExtensionLoader" is assumed.
         
  @returns An autoreleased array NSBundles that matched the
           search criteria.
 */
- (NSArray *) extensionsForBundleType: (NSString *) bundleFileExtension
              principalClassProtocols: (NSArray *) protocols
                   bundleSubdirectory: (NSString *) subDirName
                            inDomains: (NSSearchPathDomainMask) domainMask
                 domainDetectionByKey: (NSString *) defaultsKey;

 /** Searches the filesystem for extension bundles.

  This method is simmilar to -[BundleExtensionLoader
  extensionForBundleType:principalClassProtocols:bundleSubdirectory:inDomains:domainDetectionByKey:]
  but it allows a single protocol to be specified directly. It simply
  invokes the above method with a single protocol in the array, i.e.
  this method is a shorthand.

  @see -[BundleExtensionLoader
  extensionForBundleType:principalClassProtocols:bundleSubdirectory:inDomains:domainDetectionByKey:]
*/
- (NSArray *) extensionsForBundleType: (NSString *) bundleFileExtension
               principalClassProtocol: (Protocol *) protocol
                   bundleSubdirectory: (NSString *) subDirName
                            inDomains: (NSSearchPathDomainMask) domainMask
                 domainDetectionByKey: (NSString *) defaultsKey;

@end
