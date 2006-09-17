//
//  poppler_objc.m
//  PopplerKit
//
//  Created by Stefan Kleine Stegemann on 9/12/05.
//  Copyright 2005 . All rights reserved.
//

#import "poppler.h"
#import <Foundation/NSLock.h>

static NSLock* poppler_lock = nil;

#define CHECK_INITIALIZED \
   if (!poppler_lock) { \
      fprintf(stderr, "poppler_lock not initialized\n"); fflush(stderr);\
      return; \
   }


void _poppler_objc_init(void)
{
   poppler_lock = [[NSLock alloc] init];
}

void poppler_acquire_lock(void)
{
   CHECK_INITIALIZED;
   [poppler_lock lock];
}

void poppler_release_lock(void)
{
   CHECK_INITIALIZED;
   [poppler_lock unlock];
}
