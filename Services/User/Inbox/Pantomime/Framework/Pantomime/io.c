/*
**  io.c
**
**  Copyright (c) 2004-2007
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#include <Pantomime/io.h>

#include <errno.h>
#ifdef __MINGW32__
#include <io.h> 	// For _read(), _write() and _close() on MinGW
#include <winsock2.h>	// For recv() on MinGW
#else
#include <sys/ioctl.h>
#include <sys/socket.h>
#endif

#include <stdio.h>
#include <string.h>     // For memset()
#include <netinet/in.h> // For ntohs() and friends. 

#include <unistd.h>	// For read(), write() and close()

#ifdef MACOSX
#include <sys/uio.h>	// For read() and write() on OS X
#endif

#if !defined(FIONBIO) && !defined(__MINGW32__)
#include <sys/filio.h>  // For FIONBIO on Solaris
#endif

//
//
//
ssize_t read_block(int fd, void *buf, size_t count)
{
  ssize_t tot, bytes;
  
  tot = bytes = 0;

  while (tot < count)
    {
#ifdef __MINGW32__ 
      if ((bytes = _read(fd, buf+tot, count-tot)) == -1)
#else
      if ((bytes = read(fd, buf+tot, count-tot)) == -1)
#endif
        {
	  if (errno != EINTR)
	    {
	      return -1;
	    }
	}
      else
	{
	  tot += bytes;
	}
    }
  
  return tot;
}


//
//
//
int safe_close(int fd)
{
  int value;
#ifdef __MINGW32__
  while (value = _close(fd), value == -1 && errno == EINTR);
#else
  while (value = close(fd), value == -1 && errno == EINTR);
#endif
  return value;
}

//
//
//
ssize_t safe_read(int fd, void *buf, size_t count)
{
  ssize_t value;
#ifdef __MINGW32__
  while (value = _read(fd, buf, count), value == -1 && errno == EINTR);
#else
  while (value = read(fd, buf, count), value == -1 && errno == EINTR);
#endif
  return value;
}

//
//
//
ssize_t safe_recv(int fd, void *buf, size_t count, int flags)
{
  ssize_t value;
  while (value = recv(fd, buf, count, flags), value == -1 && errno == EINTR);
  return value;
}

//
// 
//
void read_string_memory(unsigned char *m, unsigned char *buf, unsigned short int *count)
{
  unsigned short c0, c1, r;

  c0 = *m;
  c1 = *(m+1);

#if BYTE_ORDER == BIG_ENDIAN
  *count = r = ntohs((c0<<8)|c1);
#else  
  *count = r = ntohs((c1<<8)|c0);
#endif
  m += 2;

  while (r--)
    {
      *buf++ = *m++;
    }

  *buf = 0;
}

//
//
//
unsigned int read_unsigned_int_memory(unsigned char *m)
{
  unsigned int c0, c1, c2, c3, r;

  c0 = *m;
  c1 = *(m+1);
  c2 = *(m+2);
  c3 = *(m+3);

#if BYTE_ORDER == BIG_ENDIAN
  r = (c0<<24)|(c1<<16)|(c2<<8)|c3;
#else
  r = (c3<<24)|(c2<<16)|(c1<<8)|c0;
#endif
  
  //NSLog(@"read r = %d", ntohl(r));
  return ntohl(r);
}

//
//
//
unsigned short read_unsigned_short(int fd)
{
  unsigned short v;
  
  if (read(fd, &v, 2) != 2) abort();

  return ntohs(v);
}

//
//
//
void write_unsigned_short(int fd, unsigned short value)
{
  unsigned short int v;
  
  v = htons(value);
  
  if (write(fd, &v, 2) != 2)
    {
      //printf("Error writing cache, aborting.");
      abort();
    }
} 

//
//
//
void read_string(int fd, char *buf, unsigned short int *count)
{
  *count = read_unsigned_short(fd);
  
  if (*count)
    {
      read(fd, buf, *count);
    }
}

//
//
//
void write_string(int fd, unsigned char *s, unsigned short len)
{
  if (s && len > 0)
    { 
      write_unsigned_short(fd, len);
      if (write(fd, s, len) != len)
	{
	  //NSLog(@"FAILED TO WRITE BYTES, ABORT");
	  abort();
	}
    }
  else
    {
      write_unsigned_short(fd, 0);
    }
}

//
//
//
unsigned int read_unsigned_int(int fd)
{
  unsigned int v;
  //int v;
  int c;
  
  if ((c = read(fd, &v, 4)) != 4) { printf("read = %d\n", c); }

  return ntohl(v);
}

//
//
//
void write_unsigned_int(int fd, unsigned int value)
{
  unsigned int v;
  
  v = htonl(value);

  //printf("b|%d| a|%d|", value, v);

  if (write(fd, &v, 4) != 4)
    {
      //NSLog(@"ERROR WRITING CACHE.");
      abort();
    }
}
