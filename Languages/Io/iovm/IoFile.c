/*#io
File ioDoc(
		   docCopyright("Steve Dekorte", 2002)
		   docLicense("BSD revised") 
		   docDescription("""Encapsulates file i/o. Here's an example of opening a file, and reversing it's lines:

<pre>
file = File clone openForUpdating("/tmp/test")
lines = file readLines reverse
file rewind
lines foreach(i, line, file write(line, "\n"))
file close</pre>
""")
		 docCategory("FileSystem")
		   */

#include "IoDate.h"
#include "IoFile.h"
#include "IoFile_stat.h"
#include "IoSeq.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoObject.h"
#include "IoList.h"
#include "IoSeq.h"
#include "ByteArray.h"
#include "PortableTruncate.h"
#include <errno.h>
#include <stdio.h>

#if !defined(_MSC_VER) && !defined(__SYMBIAN32__)
#include <unistd.h> /* ok, this isn't ANSI */
#endif

#if defined(_MSC_VER) && !defined(__SYMBIAN32__)
#include <direct.h>
#define getcwd _getcwd
#define popen(x,y) _popen(x,y)
#define pclose(x) _pclose(x)
#endif

#if defined(__SYMBIAN32__)
static int pclose(void* f) { return 0; }
static int popen(void* f, int m) {  return 0; }
static int rename(void* a, void* b) { return 0; }
static char* getcwd(char* buf, int size) { return 0; }
#endif

#define DATA(self) ((IoFileData *)IoObject_dataPointer(self))

IoTag *IoFile_tag(void *state)
{
    IoTag *tag = IoTag_newWithName_("File");
    tag->state = state;
    tag->cloneFunc = (TagCloneFunc *)IoFile_rawClone;
    tag->markFunc  = (TagMarkFunc *)IoFile_mark;
    tag->freeFunc  = (TagFreeFunc *)IoFile_free;
    tag->writeToStoreOnStreamFunc  = (TagWriteToStoreOnStreamFunc *)IoFile_writeToStore_stream_;
    tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoFile_readFromStore_stream_;
    return tag;
}

IoFile *IoFile_proto(void *state)
{
    IoMethodTable methodTable[] = {
    {"descriptor", IoFile_descriptor},
    // standard I/O 
    {"standardInput", IoFile_standardInput},
    {"standardOutput", IoFile_standardOutput},
    {"standardError", IoFile_standardError},
		
    // path 
    {"setPath", IoFile_setPath},
    {"path", IoFile_path},
    {"name", IoFile_lastPathComponent},
    {"temporaryFile", IoFile_temporaryFile},
		
    // info 
    {"exists", IoFile_exists},
    {"size", IoFile_size},
		
    // open and close 
    {"openForReading", IoFile_openForReading},
    {"openForUpdating", IoFile_openForUpdating},
    {"openForAppending", IoFile_openForAppending},
    {"mode", IoFile_mode},
		
    {"open", IoFile_open},
    {"popen", IoFile_popen},
    {"close", IoFile_close},

    {"isOpen", IoFile_isOpen},
		
    // reading 
    {"contents", IoFile_contents},
    {"asBuffer", IoFile_asBuffer},
    {"readLine", IoFile_readLine},
    {"readLines", IoFile_readLines},
    {"readStringOfLength", IoFile_readStringOfLength_},
    {"readBufferOfLength", IoFile_readBufferOfLength_},
    {"readToBufferLength", IoFile_readToBufferLength},
    {"at", IoFile_at},
    {"foreach", IoFile_foreach},
		
    // writing 
    {"write", IoFile_write},
    {"atPut", IoFile_atPut},
    {"flush", IoFile_flush},
		
    // positioning 
    {"rewind", IoFile_rewind},
    {"setPosition", IoFile_position_},
    {"position", IoFile_position},
    {"isAtEnd", IoFile_isAtEnd},
		
    // other
    {"remove", IoFile_remove},
    {"moveTo", IoFile_moveTo_},
    {"truncateToSize", IoFile_truncateToSize},
		
    {NULL, NULL},
    };
    
    IoObject *self = IoObject_new(state);
    self->tag = IoFile_tag(state);
    
    IoObject_setDataPointer_(self, calloc(1, sizeof(IoFileData)));
    DATA(self)->path  = IOSYMBOL("");
    DATA(self)->mode  = IOSYMBOL("r+b");
    DATA(self)->flags = IOFILE_FLAGS_NONE;
    IoState_registerProtoWithFunc_((IoState *)state, self, IoFile_proto);
    
    IoObject_addMethodTable_(self, methodTable);
    IoFile_statInit(self);
    return self;
}

IoFile *IoFile_rawClone(IoFile *proto)
{
    IoObject *self = IoObject_rawClonePrimitive(proto);
    IoObject_setDataPointer_(self, cpalloc(IoObject_dataPointer(proto), sizeof(IoFileData)));
    DATA(self)->info = 0x0;
    return self;
}

IoFile *IoFile_new(void *state)
{
    IoObject *proto = IoState_protoWithInitFunction_((IoState *)state, IoFile_proto);
    return IOCLONE(proto);
}

IoFile *IoFile_newWithPath_(void *state, IoSymbol *path)
{
    IoFile *self = IoFile_new(state);
    DATA(self)->path = IOREF(path);
    return self;
}


IoFile *IoFile_newWithStream_(void *state, FILE *stream)
{
    IoFile *self = IoFile_new(state);
    DATA(self)->stream = stream;
    return self;
}

IoFile *IoFile_cloneWithPath_(IoFile *self, IoSymbol *path)
{
    IoFile *f = IOCLONE(self);
    DATA(f)->path = IOREF(path);
    return f;
}

void IoFile_mark(IoFile *self)
{
    IoObject_shouldMarkIfNonNull(DATA(self)->path);
    IoObject_shouldMarkIfNonNull(DATA(self)->mode);
}

void IoFile_free(IoFile *self)
{
    if (NULL == IoObject_dataPointer(self)) 
    { 
		return; 
    }
    
    IoFile_justClose(self);
    
    if (DATA(self)->info) 
    {
		free(DATA(self)->info);
    }
    
    free(IoObject_dataPointer(self));
}

void IoFile_writeToStore_stream_(IoFile *self, IoStore *store, BStream *stream)
{
    BStream_writeTaggedByteArray_(stream, IoSeq_rawByteArray(DATA(self)->path));
    BStream_writeTaggedByteArray_(stream, IoSeq_rawByteArray(DATA(self)->mode));
}

void *IoFile_readFromStore_stream_(IoFile *self, IoStore *store, BStream *stream)
{
    IoSymbol *mode;
    IoSymbol *path = IoState_symbolWithByteArray_copy_(IOSTATE, BStream_readTaggedByteArray(stream), 1);
    DATA(self)->path = IOREF(path);
    mode = IoState_symbolWithByteArray_copy_(IOSTATE, BStream_readTaggedByteArray(stream), 1);
    DATA(self)->mode = IOREF(mode);
    return self;
}

void IoFile_justClose(IoFile *self)
{
    FILE *stream  = DATA(self)->stream;
    
    if (stream)
    {
		if (stream != stdout && stream != stdin)
		{
			if (DATA(self)->flags == IOFILE_FLAGS_PIPE)
			{
				pclose(stream);
			}
			else
			{
				fclose(stream);
				DATA(self)->flags = IOFILE_FLAGS_NONE;
			}
		}
		
		DATA(self)->stream = (FILE *)NULL;
    }
}

int IoFile_justExists(IoFile *self)
{
	char *path = CSTRING(DATA(self)->path);
	FILE *fp = fopen(path, "rb");
    
	if (fp) 
	{ 
		fclose(fp); 
		return 1; 
	}
    
	return 0;
}

int IoFile_create(IoFile *self)
{
    FILE *fp = fopen(CSTRING(DATA(self)->path), "wb");
    
    if (fp) 
    { 
		fclose(fp); 
		return 1; 
    }
    
    return 0;
}

/* ----------------------------------------------------------- */

IoObject *IoFile_descriptor(IoFile *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("escriptor", "Returns the file's descriptor as a number.")
	*/
	
	return IONUMBER(fileno(DATA(self)->stream));

}

IoObject *IoFile_standardInput(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("standardInput", 
			"Returns a new File whose stream is set to the standard input stream.")
    */
    
    IoFile *newFile = IoFile_new(IOSTATE);
    DATA(newFile)->path = IOREF(IOSYMBOL("<standard input>"));
    DATA(newFile)->mode = IOREF(IOSYMBOL("rb"));
    DATA(newFile)->stream = stdin;
    DATA(newFile)->flags = IOFILE_FLAGS_NONE;
    return newFile;
}

IoObject *IoFile_standardOutput(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("standardOutput", 
			"Returns a new File whose stream is set to the standard output stream.")
    */
    
    IoFile *newFile = IoFile_new(IOSTATE);
    DATA(newFile)->path = IOREF(IOSYMBOL("<standard output>"));
    DATA(newFile)->mode = IOREF(IOSYMBOL("wb"));
    DATA(newFile)->stream = stdout;
    DATA(newFile)->flags = IOFILE_FLAGS_NONE;
    return newFile;
}

IoObject *IoFile_standardError(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("standardError", 
			"Returns a new File whose stream is set to the standard error stream.")
    */
    
    IoFile *newFile = IoFile_new(IOSTATE);
    DATA(newFile)->path = IOREF(IOSYMBOL("<standard error>"));
    DATA(newFile)->mode = IOREF(IOSYMBOL("wb"));
    DATA(newFile)->stream = stderr;
    DATA(newFile)->flags = IOFILE_FLAGS_NONE;
    return newFile;
}


IoObject *IoFile_setPath(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("setPath(aString)", 
			"Sets the file path of the receiver to pathString. 
The default path is an empty string. Returns self.")
    */
    
    DATA(self)->path = IOREF(IoMessage_locals_symbolArgAt_(m, locals, 0));
    return self;
}

IoObject *IoFile_path(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("path", 
			"Returns the file path of the receiver.")
    */
    
    return DATA(self)->path;
}

IoObject *IoFile_lastPathComponent(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("name", 
			"Returns the last path component of the file path.")
    */
    
    return IoSeq_lastPathComponent(DATA(self)->path, locals, m);
}

IoObject *IoFile_mode(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("mode", 
			"Returns the open mode of the file(either read, update or append).")
    */
    
    char *mode = IoSeq_asCString(DATA(self)->mode);
    
    if (!strcmp(mode, "rb"))  { return IOSYMBOL("read"); }
    if (!strcmp(mode, "r+b")) { return IOSYMBOL("update"); }
    if (!strcmp(mode, "a+b")) { return IOSYMBOL("append"); }
    
    return IONIL(self);
}

IoObject *IoFile_temporaryFile(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("temporaryFile", 
			"Returns a new File object with an open temporary file. The file is 
automatically deleted when the returned File object is closed or garbage collected. ")
    */
    
    IoFile *newFile = IoFile_new(IOSTATE);
    DATA(newFile)->stream = tmpfile();
    return newFile;
}

/*
 IoObject *IoFile_useTemporaryPath(IoFile *self, IoObject *locals, IoMessage *m)
 {
    //method2: useTemporaryPath
    //description2: Sets the path to an unused temporary file path. Returns self.
	 
#if !defined(__SYMBIAN32__)
#ifdef _UNISTD_H_
	 char s[128];
	 strcpy(s, "Io_XXXXXX");
	 if (mkstemp(s) == -1)
		 return IONIL(self);
#else
	 char *s = tmpnam(NULL);
#endif
#else
	 char s[128];
    // TODO: Implement for Symbian 
	 strcpy(s, "useTemporaryPath Not Implemented");
#endif
	 DATA(self)->path = IOSYMBOL(s);
	 return self;
 }
 */

IoObject *IoFile_openForReading(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("openForReading(optionalPathString)", 
			"Sets the file mode to read (reading only) and calls open(optionalPathString). ")
    */
    DATA(self)->mode = IOREF(IOSYMBOL("rb"));
    return IoFile_open(self, locals, m);
}

IoObject *IoFile_openForUpdating(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("openForUpdating(optionalPathString)", 
			"Sets the file mode to update (reading and writing) and calls 
open(optionalPathString). This will not delete the file if it already exists. 
Use the remove method first if you need to delete an existing file before opening a new one.")
    */
    
    DATA(self)->mode = IOREF(IOSYMBOL("r+b"));
    return IoFile_open(self, locals, m);
}

IoObject *IoFile_openForAppending(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("openForAppending(optionalPathString)", 
			"Sets the file mode to append (writing to the end of the file) 
and calls open(optionalPathString).")
    */
    
    DATA(self)->mode = IOREF(IOSYMBOL("a+b"));
    return IoFile_open(self, locals, m);
}

IoObject *IoFile_open(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("open(optionalPathString)", 
			"Opens the file. Creates one if it does not exist. 
If the optionalPathString argument is provided, the path is set to it before 
opening. Returns self or raises an File exception on error.")
    */
    
    char *mode = CSTRING(DATA(self)->mode);
    
    DATA(self)->flags = IOFILE_FLAGS_NONE;
    
    if (IoMessage_argCount(m) > 0)
    { 
		DATA(self)->path = IOREF(IoMessage_locals_symbolArgAt_(m, locals, 0)); 
    }
    
    if (DATA(self)->stream) 
    { 
		IoFile_justClose(self); 
    }
    
    if (!IoFile_justExists(self) && strcmp(mode, "rb") != 0 )
    { 
		IoFile_create(self); 
		
		if(!IoFile_justExists(self))
		{
			IoState_error_(IOSTATE, m, "unable to create file '%s'", CSTRING(DATA(self)->path));	
		}
    }
    
    DATA(self)->stream = fopen(CSTRING(DATA(self)->path), mode);
    
    if (DATA(self)->stream == NULL)
    {
		IoState_error_(IOSTATE, m, "unable to open file path '%s'", CSTRING(DATA(self)->path));
    }
    
    return self;
}

IoObject *IoFile_popen(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("popen", 
			"open as a pipe")
    */
    
    DATA(self)->flags = IOFILE_FLAGS_PIPE;
    
    if (IoMessage_argCount(m) > 0)
    { 
		DATA(self)->path = IOREF(IoMessage_locals_symbolArgAt_(m, locals, 0)); 
    }
    
    if (DATA(self)->stream) 
    { 
		IoFile_justClose(self); 
    }
    
#if defined(SANE_POPEN)
    DATA(self)->mode = IOREF(IOSYMBOL("a+b"));
    DATA(self)->stream = popen(CSTRING(DATA(self)->path), "r+");
#elif defined(__SYMBIAN32__)
    /* Symbian does not implement popen.
		* (There is popen3() but it is "internal and not intended for use.")
		*/
    DATA(self)->mode = IOREF(IOSYMBOL("rb"));
    DATA(self)->stream = NULL;
#else
    DATA(self)->mode = IOREF(IOSYMBOL("rb"));
    DATA(self)->stream = popen(CSTRING(DATA(self)->path), "r");
#endif
    if (DATA(self)->stream == NULL)
    {
		IoState_error_(IOSTATE, m, "error executing file path '%s'", CSTRING(DATA(self)->path));
    }
    
    return self;
}


IoObject *IoFile_close(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("close", 
			"Closes the receiver if open, otherwise does nothing. Returns self.")
    */
    
    IoFile_justClose(self);
    return self;
}

IoObject *IoFile_flush(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("flush", 
			"Forces any buffered data to be written to disk. Returns self.")
    */
    
    fflush(DATA(self)->stream);
    return self;
}

IoObject *IoFile_rawAsString(IoFile *self)
{
    ByteArray *ba = ByteArray_new();
    
    if (ByteArray_readFromFilePath_(ba, CSTRING(DATA(self)->path)) == 1)
    { 
		return IoState_symbolWithByteArray_copy_(IOSTATE, ba, 0); 
    }
    else
    {
		ByteArray_free(ba);
		IoState_error_(IOSTATE, 0x0, "unable to read file '%s'", CSTRING(DATA(self)->path));
    }
    
    return IONIL(self);
}

IoObject *IoFile_contents(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("contents", "Returns contents of the file as a mutable Sequence of bytes.")
    */
    
    ByteArray *ba = ByteArray_new();
    char *path = CSTRING(DATA(self)->path);
    FILE *fp;
    int result = -1;
    
    if (DATA(self)->stream == stdin)
    { 
		fp = DATA(self)->stream;
    }
    else
    { 
		fp = fopen(path, "rb"); 
    }
    
    if (fp)
    {
		result = ByteArray_readFromCStream_(ba, fp);
		fclose(fp);
    }
    
    if (result != -1)
    { 
	    return IoSeq_newWithByteArray_copy_(IOSTATE, ba, 0);
    }
    else
    {
		ByteArray_free(ba);
		IoState_error_(IOSTATE, m, "unable to read file '%s'", CSTRING(DATA(self)->path));
    }
    
    return IONIL(self);
}

IoObject *IoFile_asBuffer(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asBuffer", "Opens the receiver in read only mode, reads the whole 
contents of the file into a buffer object, closes the file and returns the buffer.")
    */
    
    ByteArray *ba = ByteArray_new();
    
    if (ByteArray_readFromFilePath_(ba, CSTRING(DATA(self)->path)) == 1)
    { 
		return IoSeq_newWithByteArray_copy_(IOSTATE, ba, 0); 
    }
    else
    {
		ByteArray_free(ba);
		IoState_error_(IOSTATE, m, "unable to read file '%s'", CSTRING(DATA(self)->path));
    }
    
    return IONIL(self);
}

IoObject *IoFile_exists(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("exists", "Returns true if the file specified by the receiver's 
path exists, false otherwise.")
    */
    
    return IOBOOL(self, IoFile_justExists(self));
}

IoObject *IoFile_remove(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("remove", 
			"Removes the file specified by the receiver's path. 
Raises an error if the file exists but is not removed. Returns self.")
    */
    
    int error;
    
#if defined(__SYMBIAN32__)
	error = -1;
#else
	error = remove(CSTRING(DATA(self)->path));
#endif

    if (error && IoFile_justExists(self))
    {
		IoState_error_(IOSTATE, m, "error removing file '%s'", CSTRING(DATA(self)->path));
    }
    return self;
}

IoObject *IoFile_truncateToSize(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("truncateToSize(numberOfBytes)", 
			"Trunctates the file's size to the numberOfBytes. Returns self.")
    */
    
    long newSize = IoMessage_locals_longArgAt_(m, locals, 0);
    truncate(CSTRING(DATA(self)->path), newSize);
    return self;
}

IoObject *IoFile_moveTo_(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("moveTo(pathString)", 
			"""Moves the file specified by the receiver's path to the 
new path pathString. Raises an File doesNotExist exception if the 
file does not exist or a File nameConflict exception if the file 
nameString already exists.""")
    */
    
    IoSymbol *newPath = IoMessage_locals_symbolArgAt_(m, locals, 0);
    int error = rename(CSTRING(DATA(self)->path), CSTRING(newPath));
    
    if (error)
    {
		IoState_error_(IOSTATE, m, "error moving file '%s' to '%s'", CSTRING(DATA(self)->path), CSTRING(newPath));
    }
    return self;
}

IoObject *IoFile_write(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("write(aSequence1, aSequence2, ...)", 
			"Writes the arguments to the receiver file. Returns self.")
    */
    
    int i;
    
    IoFile_assertOpen(self, locals, m);
    IoFile_assertWrite(self, locals, m);
    
    for (i = 0; i < IoMessage_argCount(m); i ++)
    {
		IoSymbol *string = IoMessage_locals_seqArgAt_(m, locals, i);
		ByteArray_writeToCStream_(IoSeq_rawByteArray(string), DATA(self)->stream);
		
		if (ferror(DATA(self)->stream) != 0)
		{
			IoState_error_(IOSTATE, m, "error writing to file '%s'", 
									   CSTRING(DATA(self)->path));
		}
    }
    
    return self;
}

IoObject *IoFile_readLines(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("readLines", 
			"Returns list containing all lines in the file.")
    */
	
    IoState *state = IOSTATE;
    
    if (!DATA(self)->stream)
    {
		IoFile_openForReading(self, locals, m);
    }
    
    IoFile_assertOpen(self, locals, m);
    
    {
		IoList *lines = IoList_new(state);
		IoObject *newLine;
		
		IoState_pushRetainPool(state);
		
		for (;;)
		{
			IoState_clearTopPool(state);
			newLine = IoFile_readLine(self, locals, m);
			
			if (ISNIL(newLine))
			{
				break;
			}
			
			IoList_rawAppend_(lines, newLine);
		} 
		IoState_popRetainPool(state);
		
		return lines;
    }
}

IoObject *IoFile_readLine(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("readLine", "Reads the next line of the file and returns it as a 
string without the return character. Returns Nil if the end of the file has been reached.")
    */
    //char *path = CSTRING(DATA(self)->path); // tmp for debugging

	IoFile_assertOpen(self, locals, m);
    
    if (feof(DATA(self)->stream) != 0) 
    {
		clearerr(DATA(self)->stream);
		return IONIL(self);
    }
    else
    {
		ByteArray *ba = ByteArray_new();
		int error;
		unsigned char didRead = ByteArray_readLineFromCStream_(ba, DATA(self)->stream);
		
		if (!didRead) 
		{ 
			ByteArray_free(ba); 
			return IONIL(self); 
		}
		
		error = ferror(DATA(self)->stream);
		
		if (error != 0)
		{
			ByteArray_free(ba);
			clearerr(DATA(self)->stream);
			IoState_error_(IOSTATE, m, "error reading from file '%s'", CSTRING(DATA(self)->path));
			return IONIL(self); 
		}
		
		clearerr(DATA(self)->stream);
		return IoSeq_newWithByteArray_copy_(IOSTATE, ba, 0);
		/*return IoState_symbolWithByteArray_copy_(IOSTATE, ba, 0);*/
    }
}

ByteArray *IoFile_readByteArrayOfLength_(IoFile *self, IoObject *locals, IoMessage *m)
{
    int length = IoMessage_locals_intArgAt_(m, locals, 0);
    ByteArray *ba = ByteArray_new();
    IoFile_assertOpen(self, locals, m);
    
    ByteArray_readNumberOfBytes_fromCStream_(ba, length, DATA(self)->stream);
    
    if (ferror(DATA(self)->stream) != 0)
    {
		clearerr(DATA(self)->stream);
		ByteArray_free(ba);
		IoState_error_(IOSTATE, m, "error reading file '%s'", CSTRING(DATA(self)->path));
    }
    
    if (!ByteArray_size(ba))
    {
		ByteArray_free(ba);
		return 0x0;
    }
    
    return ba;
}

IoObject *IoFile_readToBufferLength(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("readToBufferOfLength(aBuffer, aNumber)", 
			"Reads at most aNumber bytes and appends them to aBuffer.
Returns true if any bytes where read and false otherwise.")
    */
    
    IoSeq *buffer = IoMessage_locals_mutableSeqArgAt_(m, locals, 0);
    size_t length = IoMessage_locals_longArgAt_(m, locals, 1);
    ByteArray *ba = IoSeq_rawByteArray(buffer);
    size_t bytesRead = ByteArray_readNumberOfBytes_fromCStream_(ba, length, DATA(self)->stream);
    //return IOBOOL(self, bytesRead > 0);
    return IONUMBER(bytesRead);
}

IoObject *IoFile_readBufferOfLength_(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("readBufferOfLength(aNumber)", 
			"Reads a Buffer of the specified length and returns it.
Returns Nil if the end of the file has been reached.")
    */
    
    ByteArray *ba = IoFile_readByteArrayOfLength_(self, locals, m);
    
    if (!ba) 
    {
		return IONIL(self);
    }
    
    return IoSeq_newWithByteArray_copy_(IOSTATE, ba, 0);
}

IoObject *IoFile_readStringOfLength_(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("readStringOfLength(aNumber)", 
			"Reads a String of the specified length and returns it.
Returns Nil if the end of the file has been reached.")
    */
    
    ByteArray *ba = IoFile_readByteArrayOfLength_(self, locals, m);
    
    if (!ba) 
    {
		return IONIL(self);
    }
    
    return IoState_symbolWithByteArray_copy_(IOSTATE, ba, 0);
}

IoObject *IoFile_rewind(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("rewind", 
			"Sets the file position pointer to the beginning of the file.")
    */
    IoFile_assertOpen(self, locals, m);
    
    if (DATA(self)->stream) 
    {
		rewind(DATA(self)->stream);
    }
    
    return self;
}

IoObject *IoFile_position_(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("setPosition(aNumber)", 
			"Sets the file position pointer to the byte specified by aNumber. Returns self.")
    */
    
    long pos = IoMessage_locals_longArgAt_(m, locals, 0);
    IoFile_assertOpen(self, locals, m);
	
    if (fseek(DATA(self)->stream, pos, 0) != 0)
    {
		IoState_error_(IOSTATE, m, "unable to set position %i file path '%s'",
								   (int)pos, CSTRING(DATA(self)->path));
    }
    
    return self;
}

IoObject *IoFile_position(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("position", 
			"Returns the current file pointer byte position as a Number.")
    */
    
    IoFile_assertOpen(self, locals, m);
    return IONUMBER(ftell(DATA(self)->stream));
}

IoObject *IoFile_isAtEnd(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isAtEnd", 
			"Returns true if the file is at it's end. Otherwise returns false.")
    */
    
    IoFile_assertOpen(self, locals, m);
    return IOBOOL(self, feof(DATA(self)->stream) != 0);
}

IoObject *IoFile_size(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("size", 
			"Returns the file size in bytes.")
    */
    
    FILE *fp = fopen(CSTRING(DATA(self)->path), "rb");
    
    if (fp)
    {
		int fileSize;
		fseek(fp, 0, SEEK_END);
		fileSize = ftell(fp);
		fclose(fp);
		return IONUMBER(fileSize);
    }
    else
    {
		IoState_error_(IOSTATE, m, "unable to open file '%s'", CSTRING(DATA(self)->path));
    }
    
    return IONIL(self);
}

IoObject *IoFile_isOpen(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("isOpen", 
			"Returns self if the file is open. Otherwise returns Nil.")
    */
    
    return IOBOOL(self, DATA(self)->stream != 0);
}

IoObject *IoFile_assertOpen(IoFile *self, IoObject *locals, IoMessage *m)
{
    if (!DATA(self)->stream)
    {
		IoState_error_(IOSTATE, m, "file '%s' not yet open", CSTRING(DATA(self)->path));
    }
    return self;
}

IoObject *IoFile_assertWrite(IoFile *self, IoObject *locals, IoMessage *m)
{
    char *mode = IoSeq_asCString(DATA(self)->mode);
    
    if ((strcmp(mode, "r+b")) && (strcmp(mode, "a+b")) && (strcmp(mode, "wb")))
    {
		IoState_error_(IOSTATE, m, "file '%s' not open for write", CSTRING(DATA(self)->path));
    }
    
    return self;
}

IoObject *IoFile_at(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("at(aNumber)", 
			"Returns a Number containing the byte at the specified 
byte index or Nil if the index is out of bounds.")
    */
    
    int byte;
    
    IoFile_assertOpen(self, locals, m);
    IoFile_position_(self, locals, m); /* works since first arg is the same */
    byte = fgetc(DATA(self)->stream);
    
    if (byte == EOF) 
    {
		return IONIL(self);
    }
    
    return IONUMBER(byte);
}

IoObject *IoFile_atPut(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("atPut(positionNumber, byteNumber)", 
			"Writes the byte value of byteNumber to the file position 
positionNumber. Returns self.")
    */
    
    int c = IoMessage_locals_intArgAt_(m, locals, 1);
    
    IoFile_assertOpen(self, locals, m);
    IoFile_assertWrite(self, locals, m);
    IoFile_position_(self, locals, m); // works since first arg is the same 
    
    if (fputc(c, DATA(self)->stream) == EOF)
    {
		int pos = IoMessage_locals_intArgAt_(m, locals, 0); // BUG - this may not be the same when evaled 
		IoState_error_(IOSTATE, m, "error writing to position %i in file '%s'", pos, CSTRING(DATA(self)->path));
    }
    
    return self;
}

IoObject *IoFile_foreach(IoFile *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("foreach(optionalIndex, value, message)", 
			"""For each byte, set index to the index of the byte 
and value to the number containing the byte value and execute aMessage.
Example usage:
<pre>
aFile foreach(i, v, writeln("byte at ", i, " is ", v))
aFile foreach(v, writeln("byte ", v))
</pre>
""")
    */
    
    IoObject *result = IONIL(self);
    
    IoSymbol *indexSlotName, *characterSlotName;
    IoMessage *doMessage;
    int i = 0;
	
    IoMessage_foreachArgs(m, self, &indexSlotName, &characterSlotName, &doMessage);
    
    for (;;)
    {
        int c = getc(DATA(self)->stream);
	   
        if (c == EOF) 
	   {
		   break;
	   }
	   
        if (indexSlotName)
        {
            IoObject_setSlot_to_(locals, indexSlotName, IONUMBER(i));
        }
	   
        IoObject_setSlot_to_(locals, characterSlotName, IONUMBER(c));
        result = IoMessage_locals_performOn_(doMessage, locals, locals);
        
        if (IoState_handleStatus(IOSTATE))
        {
            break;
        }
        
        i ++;
    }
    return result;
}

IoObject *IoFile_rawDo(IoFile *self, IoObject *context)
{
    return IoObject_rawDoString_label_(context, (IoSymbol *)IoFile_rawAsString(self), DATA(self)->path);
}

IoObject *IoFile_do(IoFile *self, IoObject *locals, IoMessage *m)
{
    IoList *argsList = IoList_new(IOSTATE);
    IoObject *context = IoMessage_locals_valueArgAt_(m, locals, 0);
    int argn = 1;
    IoObject *arg = IoMessage_locals_valueArgAt_(m, locals, argn);
    
    while (arg && !ISNIL(arg))
    {
		IoList_rawAppend_(argsList, arg);
		argn ++;
		arg = IoMessage_locals_valueArgAt_(m, locals, argn);
    }
    
    if (IoList_rawSize(argsList))
    { 
		IoObject_setSlot_to_(context, IOSYMBOL("args"), argsList); 
    }
    
    return IoObject_rawDoString_label_(context, (IoSymbol *)IoFile_rawAsString(self), DATA(self)->path);
}

