/*
	ExtendedWorkspaceConfig.h

	Config file for the ExtendedWorkspaceKit

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2004

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

#import <libgnomevfs/gnome-vfs.h>

enum _VFSBackend 
{
  GNUstep,
  GNOMEVFS
};

enum _AttributesBackend
{
  DataCruxSQLlite,
  LibferrisSQLlite
};

#define VFSBackend GNOMEVFS
#define AttributesBackend DataCruxSQLlite

/*
const enum _VFSBackend VFSBackend GNOMEVFS;
const enum _AttributesBackend AttributesBackend = DataCruxSQLlite;
*/

// Private stuff

#if VFSBackend == GNOMEVFS
  typedef GnomeVFSHandle EXTVFSHandle;
#else
  typedef void EXTVFSHandle;
#endif
