//
//  main.m
//  UKDistributedView
//
//  Created by Uli Kusterer on Tue Jun 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <math.h>

int main(int argc, const char *argv[])
{
    float myF = 5.;
	float myF1 = 5;
	float myF2 = 5.21869;
	
	NSLog(@"myF1 %f", myF1);
	NSLog(@"myF2 %f", myF2);
	NSLog(@"truncf %d", truncf(myF));
	NSLog(@"truncf %d", truncf(myF1));
	NSLog(@"truncf %d", truncf(myF2));
	NSLog(@"truncf %d", truncf((float)(myF1)));
	return NSApplicationMain(argc, argv);
}
