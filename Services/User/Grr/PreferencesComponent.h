/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "Components.h"

@protocol PreferencesComponent <ViewProvidingComponent>

-(NSString*) prefPaneName;
-(NSImage*) prefPaneIcon;

@end



@interface PreferencesComponent : ViewProvidingComponent <PreferencesComponent>
{
}
// see protocol
@end


