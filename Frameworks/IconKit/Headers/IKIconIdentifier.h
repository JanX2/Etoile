/*
 *  IKIconIdentifier.h
 *  
 *
 *  Created by Uli Kusterer on 04.01.05.
 *  Copyright 2005 M. Uli Kusterer. All rights reserved.
 *
 */

#ifndef ICONKIT_IKICONIDENTIFIER_H
#define ICONKIT_IKICONIDENTIFIER_H 1

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#include <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//  Data Types:
// -----------------------------------------------------------------------------

typedef NSString* IKIconIdentifier;     // IKIconIdentifier is opaque, and not guaranteed to be an object! It's a struct on MacOS X.


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

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

#endif /*ICONKIT_IKICONIDENTIFIER_H*/
