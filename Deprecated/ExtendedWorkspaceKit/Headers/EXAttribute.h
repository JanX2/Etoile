/*
	EXAttribute.h

	Attributes class which implements basic attributes representation and interaction

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2004

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

@class NSString;

@interface EXAttribute : NSObject
{

}

@end

/*
 * Primary attributes identifiers
 */

GS_EXPORT NSString * const EXAttributeCreationDate;
GS_EXPORT NSString * const EXAttributeModificationDate;
GS_EXPORT NSString * const EXAttributeName;
GS_EXPORT NSString * const EXAttributeSize;
GS_EXPORT NSString * const EXAttributeFSNumber;
GS_EXPORT NSString * const EXAttributeFSType;
GS_EXPORT NSString * const EXAttributePosixPermissions;
GS_EXPORT NSString * const EXAttributeOwnerName;
GS_EXPORT NSString * const EXAttributeOwnerNumber;
GS_EXPORT NSString * const EXAttributeGroupOwnerName;
GS_EXPORT NSString * const EXAttributeGroupOwnerNumber;
GS_EXPORT NSString * const EXAttributeDeviceNumber;
GS_EXPORT NSString * const EXAttributeExtension;

GS_EXPORT NSString * const EXFSTypeDirectory;
GS_EXPORT NSString * const EXFSTypeRegular;
GS_EXPORT NSString * const EXFSTypeLink; // ExtendedWorkspaceKit custom link
GS_EXPORT NSString * const EXFSTypeSymbolicLink;
GS_EXPORT NSString * const EXFSTypeSocket;
GS_EXPORT NSString * const EXFSTypeCharacterSpecial;
GS_EXPORT NSString * const EXFSTypeBlockSpecial;
GS_EXPORT NSString * const EXFSTypeUnknown;
