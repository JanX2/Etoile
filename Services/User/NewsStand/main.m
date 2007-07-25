//
//  main.m
//  Vienna
//
//  Created by Steve on Sun Mar 14 2004.
//  Copyright (c) 2007 Yen-Ju Chen. All rights reserved.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <AppKit/AppKit.h>
#import "AppController.h"

int main(int argc, const char *argv[])
{
#ifdef GNUSTEP
	CREATE_AUTORELEASE_POOL(x);
	[NSApplication sharedApplication];
	[NSApp setDelegate: AUTORELEASE([[AppController alloc] init])];
	[NSApp run];
	DESTROY(x);
	return 0;
#else
	return NSApplicationMain(argc, argv);
#endif
}
