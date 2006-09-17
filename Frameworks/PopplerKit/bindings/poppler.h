/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifndef _H_POPPLER
#define _H_POPPLER

#ifdef __cplusplus 
extern "C" {
#endif

int poppler_init(const unsigned char* fcConfigPath,
                 const unsigned char* appFonts[],
                 unsigned nappFonts);
   
// synchronized access to popple library (required for
// multithreaded applications)
   
void poppler_acquire_lock(void);
void poppler_release_lock(void);

#define SYNCHRONIZED(x) \
   poppler_acquire_lock(); \
   x; \
   poppler_release_lock()
      
#define BEGIN_SYNCHRONIZED poppler_acquire_lock()
#define END_SYNCHRONIZED poppler_release_lock()
      
// private
void _poppler_objc_init(void);

      
#ifdef __cplusplus 
};
#endif

#endif
