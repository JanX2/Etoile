/*
	Copyright (C) 2006 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2006
	License:  Modified BSD
 */

#import <Foundation/Foundation.h>
#import <Foundation/NSDebug.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/EtoileUI.h>

int main(int argc, char *argv[])
{
	NSZombieEnabled = YES;
    return ETApplicationMain(argc,  (const char **) argv);
}
