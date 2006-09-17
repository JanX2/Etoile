/*
 * Copyright (C) 2005  Stefan Kleine Stegemann
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

#import "NSString+PopplerKitAdditions.h"

static const char kUTF8OffsetValues [256] = {
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
   2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
   3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,6,6,1,1
};


@interface NSString (PopplerKitAdditionsPrivate)
- (unsigned) myUTF8Length;
@end

@implementation NSString (PopplerKitAdditions)

// we can assume that the UTF8String method returns a
// valid UTF8 character sequence, so we don't do error
// checking here.
- (unsigned int*) getUTF32String: (unsigned*)length;
{
   unsigned utf8Length = [self myUTF8Length];

   unsigned int* result = NSZoneMalloc(NSDefaultMallocZone(),
                                       sizeof(unsigned int) * (utf8Length + 1));

   const char *ch = [self UTF8String];
   unsigned i;
   for (i = 0; i < utf8Length; i++)
   {
      unsigned int wc = ((unsigned char*)ch)[0];
      
      if (wc < 0x80) {
         result[i] = wc;
         ch++;
      } else { 
         unsigned charlen = 0;

         if (wc < 0xe0) {
            charlen = 2;
            wc &= 0x1f;
         } else if (wc < 0xf0) {
            charlen = 3;
            wc &= 0x0f;
         } else if (wc < 0xf8) {
            charlen = 4;
            wc &= 0x07;
         } else if (wc < 0xfc) {
            charlen = 5;
            wc &= 0x03;
         } else {
            charlen = 6;
            wc &= 0x01;
         }
         
         unsigned j;
         for (j = 1; j < charlen; j++) {
            wc <<= 6;
            wc |= ((unsigned char *)ch)[j] & 0x3f;
         }
         
         result[i] = wc;
         ch += charlen;
      }
   }

   result[i] = 0;
   
   if (length)
      *length = i;
   
   return result;
}

@end

/* ----------------------------------------------------- */
/*  Category PopplerKitAdditionsPrivate                  */
/* ----------------------------------------------------- */

@implementation NSString (PopplerKitAdditionsPrivate)

- (unsigned) myUTF8Length;
{
   unsigned length = 0;
   const char* ch = [self UTF8String];

   // str is always null terminated!
   while (*ch) {
      ch = (ch + kUTF8OffsetValues[*(unsigned char*)ch]);
      ++length;
   }
   
   return length;
}

@end
