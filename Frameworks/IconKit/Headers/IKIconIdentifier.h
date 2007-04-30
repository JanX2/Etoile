/*
	IKIconIdentifier.h

	IKIconIdentifier is where various standard icons related identifiers
	are declared.

	Copyright (C) 2005 Uli Kusterer <contact@zathras.de>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Uli Kusterer <contact@zathras.de>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2005

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

#import <Foundation/Foundation.h>

typedef NSString *IKIconIdentifier;  // IKIconIdentifier is opaque, and not guaranteed to be an object! It's a struct on MacOS X.

// Any of these can go in anywhere an IKIconIdentifier is asked:
extern IKIconIdentifier    IKIconGenericDocument;
extern IKIconIdentifier    IKIconGenericApplication;
extern IKIconIdentifier    IKIconGenericPlugIn;
extern IKIconIdentifier    IKIconGenericFolder;
extern IKIconIdentifier    IKIconPrivateFolder;
extern IKIconIdentifier    IKIconWriteOnlyFolder;
extern IKIconIdentifier    IKIconRecyclerFolder;
extern IKIconIdentifier    IKIconRecyclerFolderFull;
// ...
extern IKIconIdentifier    IKIconLinkBadge;
extern IKIconIdentifier    IKIconLockedBadge;
extern IKIconIdentifier    IKIconScriptBadge;
extern IKIconIdentifier    IKIconReadOnlyBadge;
extern IKIconIdentifier    IKIconWriteOnlyBadge;

// System icons (not for files):
extern IKIconIdentifier    IKIconAlertNote;
extern IKIconIdentifier    IKIconAlertWarning;
extern IKIconIdentifier    IKIconAlertFailure;

