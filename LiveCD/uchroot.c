/*
	uchroot.c
	
	Tool to run scripts with chroot

	Copyright (C) 2007 David Chisnall

	Author:  David Chisnall
	Date:  July 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <pwd.h>

int main(int argc, char * argv[])
{
	if(argc < 4)
	{
		printf("Usage: %s {username} {directory} {program} [arguments]\n", argv[0]);
		return 1;
	}
	/* Parse arguments */
	struct passwd * pass = getpwnam(argv[1]);
	if(pass == NULL)
	{
		printf("Unknown user %s\n", argv[1]);
		return 2;
	}
	/* Set the required UID */
	chdir(argv[2]);
	if(chroot(argv[2])
		||
		setgid(pass->pw_gid)
		||
		setuid(pass->pw_uid))
	{
		printf("%s must be run as root.  Current uid=%d, euid=%d\n", 
				argv[0],
				(int)getuid(),
				(int)geteuid()
				);
		return 3;
	}
	return execv(argv[3], argv + 3);
}

