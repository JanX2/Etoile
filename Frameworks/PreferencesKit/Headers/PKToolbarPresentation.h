/*
	PKToolbarPresentation.h
 
	Preferences controller subclass with preference panes listed in a toolbar
 
	Copyright (C) 2005 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2005
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __PreferencesKit_Toolbar_Presentation__
#define __PreferencesKit_Toolbar_Presentation__

#include "PKPresentationBuilder.h"

@interface PKToolbarPresentation : PKPresentationBuilder
{
    NSToolbar *preferencesToolbar;
    BOOL switchActionTriggered;
}

@end

#endif /* __PreferencesKit_Toolbar_Presentation__ */
