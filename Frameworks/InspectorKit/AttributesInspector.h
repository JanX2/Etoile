/*
   AttributesInspector.h
   The attributes inspector.

   Copyright (C) 2005 Saso Kiselkov 
                 2007 Yen-Ju Chen

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice, 
     this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice, 
     this list of conditions and the following disclaimer in the documentation 
     and/or other materials provided with the distribution.
   * Neither the name of the Etoile project nor the names of its contributors 
     may be used to endorse or promote products derived from this software 
     without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
   THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <AppKit/AppKit.h>
#import "InspectorModule.h"

@interface AttributesInspector : NSObject <InspectorModule>
{
  id computeSizeBtn;
  id date;
  id fileGroup;
  id fileOwner;
  id fileSize;
  id linkTo;
  id bogusWindow;
  id perms;
  id box;
  id okButton;
  id revertButton;

  NSString * path;

  NSDictionary * users;
  NSDictionary * groups,
               * myGroups;

  NSString * user;
  NSString * group;
  BOOL modeChanged;
  unsigned oldMode;
  unsigned mode;
}

- (void) changeOwner: sender;
- (void) changeGroup: (id)sender;
- (void) computeSize: (id)sender;

- (void) ok: sender;
- (void) revert: sender;

- (void) changePerms: sender;

@end
