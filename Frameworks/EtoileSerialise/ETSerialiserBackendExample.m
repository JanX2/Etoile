#include <stdio.h>
#include <objc/objc-api.h>
#import "ETSerialiserBackendExample.h"


@implementation ETSerialiserBackendExample
+ (id) serialiserBackendWithURL:(NSURL*)anURL
{
	return [[[ETSerialiserBackendExample alloc] initWithURL:anURL] autorelease];
}
- (id) initWithURL:(NSURL*)anURL
{
	/* Write to stdout, or a file.  Other URL types not supported */
	if(anURL == nil)
	{
		outFile = stdout;
	}
	else if([anURL isFileURL])
	{
		outFile = fopen([[anURL path] UTF8String], "w");
	}
	else
	{
		return nil;
	}
	return [self init];
}
- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	referenceCounts = [[NSMutableDictionary alloc] init];
	return self;
}
- (void) indent
{
	for(unsigned int i=0 ; i<indent ; i++)
	{
		fprintf(outFile, "\t");
	}
}
- (int) newVersion
{
	fprintf(outFile, "\nVersion %d:\n\n", ++version);
	return version;
}
- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "struct %s %s {\n",aStructName, aName);
	indent++;
}
- (void) endStruct
{
	indent--;
	[self indent];
	fprintf(outFile, "}\n");
}
- (void) setClassVersion:(int)aVersion
{
	[self indent];
	fprintf(outFile, "Class has version %d\n", aVersion);
}
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass
{
	fprintf(outFile, "(Object with ID:%ld)\n",aReference);
	[self indent];
	fprintf(outFile, "%s * %s {\n",aClass->name,aName);
	indent++;
}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "id %s=%ld\n",aName,aReference);
}
- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	NSNumber * key = [NSNumber numberWithUnsignedInt: anObjectID];
	unsigned int count = [[referenceCounts objectForKey:key] unsignedIntValue];
	count++;
	[referenceCounts setObject:[NSNumber numberWithUnsignedInt:count]
						forKey:key];
}
- (void) endObject
{
	indent--;
	[self indent];
	fprintf(outFile, "}\n");
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
{
	[self indent];
	fprintf(outFile, "array %s [%u]{\n",aName, aLength);
	indent++;
}
- (void) endArray
{
	indent--;
	[self indent];
	fprintf(outFile, "}\n");
}

- (void) storeChar:(char)aChar withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "char %s=%c;\n",aName,aChar);
}
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "unsigned char %s=%u;\n",aName,(unsigned int)aChar);
}
- (void) storeShort:(short)aShort withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "short %s=%hd;\n",aName,aShort);
}
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "unsigned short %s=%hu;\n",aName,aShort);
}
- (void) storeInt:(int)aInt withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "int %s=%d;\n",aName,aInt);
}
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "unsigned int %s=%u;\n",aName,aInt);
}
- (void) storeLong:(long)aLong withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "long int %s=%ld;\n",aName,aLong);
}
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "unsigned long int %s=%lu;\n",aName,aLong);
}
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "long long int %s=%lld;\n",aName,aLongLong);
}
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "unsigned long int %s=%llu;\n",aName,aLongLong);
}
- (void) storeFloat:(float)aFloat withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "float %s=%f;\n",aName,(double)aFloat);
}
- (void) storeDouble:(double)aDouble withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "double %s=%f;\n",aName,aDouble);
}
- (void) storeClass:(Class)aClass withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "Class %s=[%s class];\n",aName,aClass->class_pointer->name);
}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "SEL %s=@selector(%s);\n",aName,sel_get_name(aSelector));
}
- (void) storeCString:(char*)aCString withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "char* %s=\"%s\";\n",aName, aCString);
}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName
{
	[self indent];
	fprintf(outFile, "void * %s = <<", aName);
	for(unsigned int i=0 ; i<aSize ; i++)
	{
		fprintf(outFile, "%.2u",(unsigned int)(*(char*)(aBlob++)));
	}
	fprintf(outFile, ">>;\n");
}

- (void) dealloc
{
	NSEnumerator * keys = [referenceCounts keyEnumerator];
	NSNumber * key;
	while((key = [keys nextObject]) != nil)
	{
		fprintf(outFile, "Object %ld has reference count %ld\n",
				[key unsignedIntValue],
				[[referenceCounts objectForKey:key] unsignedIntValue]);
	}
	if(outFile != stdout)
	{
		fclose(outFile);
	}
	[referenceCounts release];
	[super dealloc];
}
@end
