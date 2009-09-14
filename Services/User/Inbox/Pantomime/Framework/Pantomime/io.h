/*
**  io.h
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

#ifndef _Pantomime_H_io
#define _Pantomime_H_io

#include <sys/types.h>

/*!
  @function read_block
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method blocks until it read all bytes or if
	      an error different from EINTR occurs.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @result The number of bytes that have been read.
*/
ssize_t read_block(int fd, void *buf, size_t count);

/*!
  @function safe_close
  @discussion This function is used to safely close a file descriptor.
              This function will block until the file descriptor
	      is close, or if the error is different from EINTR.
  @param fd The file descriptor to close.
  @result Returns 0 on success, -1 if an error occurs.
*/
int safe_close(int fd);

/*!
  @function safe_read
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method might not block when reading if there are
	      no bytes available to be read.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @result The number of bytes that have been read.
*/
ssize_t safe_read(int fd, void *buf, size_t count);

/*!
  @function safe_recv
  @discussion This function is used to read <i>count</i> bytes
              from <i>fd</i> and store them in <i>buf</i>. This
	      method might not block when reading if there are
	      no bytes available to be read. Options can be
	      passed through <i>flags</i>.
  @param fd The file descriptor to read bytes from.
  @param buf The buffer where to store the read bytes.
  @param count The number of bytes to read.
  @param flags The flags to use.
  @result The number of bytes that have been read.
*/
ssize_t safe_recv(int fd, void *buf, size_t count, int flags);

/*!
  @function read_string_memory
  @discussion This function is used to read a string from <i>m</i>
              into <i>buf</i> and adjust the <i>count</i> on how
	      long the string is. The string will be NULL terminated
	      and must NOT be longer than 65535 bytes.
  @param m The buffer to read from.
  @param buf The buffer to write to.
  @param count The lenght of the string stored in <i>buf</i>
*/
void read_string_memory(unsigned char *m, unsigned char *buf, unsigned short int *count);

/*!
  @function read_unsigned_int_memory
  @discussion This function is used to read an unsigned int from
              the memory in network byte-order.
  @param m The buffer to read from.
  @result The unsigned integer read from memory.
*/
unsigned int read_unsigned_int_memory(unsigned char *m);

/*!
  @function read_unsigned_short
  @discussion This function is used to read an unsigned short from
              the file descriptor in network byte-order.
  @param fd The file descriptor to read from.
  @result The unsigned short read from the file descriptor.
*/
unsigned short read_unsigned_short(int fd);

/*!
  @function write_unsigned_short
  @discussion This function is used to write the specified
              unsigned short <i>value</i> to the file descriptor
	      </i>fd</i>. The written value is in network byte-order.
  @param fd The file descriptor to write to.
  @param value The unsigned value to write.
*/
void write_unsigned_short(int fd, unsigned short value);

/*!
  @function read_string
  @discussion This function is used to read a string from a
              file descriptor, store it into a buffer and adjust
	      the number of bytes that has been read.
  @param fd The file descriptor to read from.
  @param buf The buf to write to.
  @param count The number of bytes that have been read.
*/
void read_string(int fd, char *buf, unsigned short int *count);

/*!
  @function write_string
  @discussion This function is used to string a string to a
              file descriptor.
  @param fd The file descriptor to write to.
  @param buf The buf that needs to be written.
  @param count The number of bytes that we have to write.
*/
void write_string(int fd, unsigned char *s, unsigned short len);

/*!
  @function read_unsigned_int
  @discussion This function is used to read an unsigned int from
              the file descriptor in network byte-order.
  @param fd The file descriptor to read from.
  @result The unsigned int read from the file descriptor.
*/
unsigned int read_unsigned_int(int fd);

/*!
  @function write_unsigned_int
  @discussion This function is used to write the specified
              unsigned int <i>value</i> to the file descriptor
	      </i>fd</i>. The written value is in network byte-order.
  @param fd The file descriptor to write to.
  @param value The unsigned value to write.
*/
void write_unsigned_int(int fd, unsigned int value);

#endif //  _Pantomime_H_io
