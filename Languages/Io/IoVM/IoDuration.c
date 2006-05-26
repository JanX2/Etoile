/*#io
Duration ioDoc(
			docCopyright("Steve Dekorte", 2002)
			docLicense("BSD revised")
			docDescription("A container for a duration of time.")
			docCategory("Time")
*/

#include "IoDuration.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoObject.h"
#include "IoNumber.h"
#include <time.h>

#define DATA(self) ((Duration *)IoObject_dataPointer(self))

// extend message object 

IoDuration *IoMessage_locals_durationArgAt_(IoMessage *self, void *locals, int n)
{
    IoObject *v = IoMessage_locals_valueArgAt_(self, (IoObject *)locals, n);
    if (!ISDURATION(v)) IoMessage_locals_numberArgAt_errorForType_(self, (IoObject *)locals, n, "Duration");
    return v;
}

// --------------------------------------------- 

typedef struct tm tm;

IoTag *IoDuration_tag(void *state)
{
    IoTag *tag = IoTag_newWithName_("Duration");
    tag->state = state;
    tag->cloneFunc = (TagCloneFunc *)IoDuration_rawClone;
    tag->freeFunc = (TagFreeFunc *)IoDuration_free;
    tag->compareFunc = (TagCompareFunc *)IoDuration_compare;
    tag->writeToStoreOnStreamFunc = (TagWriteToStoreOnStreamFunc *)IoDuration_writeToStore_stream_;
    tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoDuration_readFromStore_stream_;
    return tag;
}

void IoDuration_writeToStore_stream_(IoDuration *self, IoStore *store, BStream *stream)
{
    BStream_writeTaggedDouble_(stream, Duration_asSeconds(DATA(self)));
}

void IoDuration_readFromStore_stream_(IoDuration *self, IoStore *store, BStream *stream)
{
    Duration_fromSeconds_(DATA(self), BStream_readTaggedDouble(stream));
}

IoDuration *IoDuration_proto(void *state)
{
    IoMethodTable methodTable[] = {
    {"years", IoDuration_years},
    {"setYears", IoDuration_setYears},
    {"days", IoDuration_days},
    {"setDays", IoDuration_setDays},
    {"hours", IoDuration_hours},
    {"setHours", IoDuration_setHours},
    {"minutes", IoDuration_minutes},
    {"setMinutes", IoDuration_setMinutes},
    {"seconds", IoDuration_seconds},
    {"setSeconds", IoDuration_setSeconds},
    {"totalSeconds", IoDuration_asNumber},
	
    {"asString", IoDuration_asString},
    {"asNumber", IoDuration_asNumber},
	
    {"fromNumber", IoDuration_fromNumber},
	/*Tag_addMethod(tag, "fromString", IoDuration_fromString},*/
	
    {"print", IoDuration_printDuration},
    {"+=", IoDuration_add},
    {"-=", IoDuration_subtract},
    {NULL, NULL},
  };
    
    
    IoObject *self = IoObject_new(state);
    
    IoObject_setDataPointer_(self, Duration_new());
    self->tag = IoDuration_tag(state);
    IoState_registerProtoWithFunc_((IoState *)state, self, IoDuration_proto);
    
    IoObject_addMethodTable_(self, methodTable);
    return self;
}

IoDuration *IoDuration_rawClone(IoDuration *proto) 
{ 
    IoObject *self = IoObject_rawClonePrimitive(proto);
    IoObject_setDataPointer_(self, Duration_new());
    Duration_copy_(DATA(self), DATA(proto));
    return self;
}

IoDuration *IoDuration_new(void *state)
{
    IoDuration *proto = IoState_protoWithInitFunction_((IoState *)state, IoDuration_proto);
    return IOCLONE(proto);
}

IoDuration *IoDuration_newWithSeconds_(void *state, double s)
{
    IoDuration *self = IoDuration_new(state);
    IoDuration_fromSeconds_(self, s);
    return self;
}

int IoDuration_compare(IoDuration *self, IoDuration *other) 
{ 
    if (ISDURATION(other)) 
    { 
	return Duration_compare(DATA(self), DATA(other)); 
    }
    
    return IoObject_defaultCompare(self, other);
}

void IoDuration_free(IoDuration *self)
{
    Duration_free(DATA(self));
}

Duration *IoDuration_duration(IoDuration *self) 
{ 
    return DATA(self); 
}

IoDuration *IoDuration_fromSeconds_(IoDuration *self, double s)
{
    Duration_fromSeconds_(DATA(self), s);
    return self;
}

double IoDuration_asSeconds(IoDuration *self)
{ 
    return Duration_asSeconds(DATA(self)); 
}

// years -------------------------------------------------------- 

IoObject *IoDuration_years(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("years", "Returns a number containing the year of the receiver. ")
    */
    
    return IONUMBER(Duration_years(DATA(self))); 
}

IoObject *IoDuration_setYears(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setYears(aNumber)", "Sets the year of the receiver. Returns self.")
    */
    
    Duration_setYears_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self; 
}

// days -------------------------------------------------------- 

IoObject *IoDuration_days(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("days", 
    "Returns a number containing the day of the month of the receiver. ")
    */
    
    return IONUMBER(Duration_days(DATA(self))); 
}

IoObject *IoDuration_setDays(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setDays(aNumber)", "Sets the day of the receiver. Returns self.")
    */
    
    Duration_setDays_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self; 
}

// hours -------------------------------------------------------- 

IoObject *IoDuration_hours(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("hours", 
    "Returns a number containing the hour of the day(0-23) of the receiver. ")
    */
    
    return IONUMBER(Duration_hours(DATA(self))); 
}

IoObject *IoDuration_setHours(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setHours(aNumber)", "Sets the hour of the receiver. Returns self.")
    */
    
    Duration_setHours_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self; 
}

// minutes -------------------------------------------------------- 

IoObject *IoDuration_minutes(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("minutes", 
    "Returns a number containing the minute of the hour(0-59) of the receiver. ")
    */
    
    return IONUMBER(Duration_minutes(DATA(self))); 
}

IoObject *IoDuration_setMinutes(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setMinutes(aNumber)", 
    "Sets the minute of the receiver. Returns self.")
    */
    
    Duration_setMinutes_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self; 
}

// seconds -------------------------------------------------------- 

IoObject *IoDuration_seconds(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("seconds", 
    "Returns a number containing the seconds of the minute(0-59) of the receiver. 
    This number may contain fractions of seconds. ")
    */
    
    return IONUMBER(Duration_seconds(DATA(self))); 
}

IoObject *IoDuration_setSeconds(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setSeconds(aNumber)", 
    "Sets the second of the receiver. Return self.")
    */
    
    Duration_setSeconds_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self; 
}

// conversion -------------------------------------------------------- 

IoObject *IoDuration_asString(IoDuration *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asString(formatString)", 
    """Returns a string representation of the receiver. The formatString argument is optional. If present, the returned string will be formatted according to ANSI C date formating rules.

    <pre>
    %y years without century as two-digit decimal number (00-99) 
    %Y year with century as four-digit decimal number 

    %d days
    %H hour as two-digit 24-hour clock decimal integer (00-23) 
    %M minute as a two-digit decimal integer (00-59) 
    %S second as a two-digit decimal integer (00-59) 

    The default format is "%Y %d %H:%M:%S". 
    """)
    */
    ByteArray *ba;
    char *format = NULL;
    
    if (IoMessage_argCount(m) == 1)
    { 
	format = CSTRING(IoMessage_locals_symbolArgAt_(m, locals, 0)); 
    }
    
    ba = Duration_asByteArrayWithFormat_(DATA(self), format);
    return IoState_symbolWithByteArray_copy_(IOSTATE, ba, 0);
}

IoObject *IoDuration_printDuration(IoDuration *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("print", "Prints the receiver. Returns self.")
    */
    
    Duration_print(DATA(self));
    return self; 
}

IoObject *IoDuration_asNumber(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("asNumber", 
    "Returns a number representation of the receiver. 
    (where 1 is equal to one second) ")
    */
    
    return IONUMBER(Duration_asSeconds(DATA(self))); 
}

IoObject *IoDuration_fromNumber(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("fromNumber(aNumber)", 
    "Sets the receiver to the Duration specified by 
    aNumber(same format number as returned by Duration asNumber). Returns self. ")
    */
    
    Duration_fromSeconds_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self;
}

// math -------------------------------------------------------- 

IoObject *IoDuration_add(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("+=(aDuration)", "Add aDuration to the receiver. Returns self. ")
    */
    
    IoDuration *d = IoMessage_locals_durationArgAt_(m, locals, 0);
    Duration_add_(DATA(self), DATA(d));
    return self; 
}

IoObject *IoDuration_subtract(IoDuration *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("-=(aDuration)", "Subtract aDuration to the receiver. Returns self. ")
    */
    
    IoDuration *d = IoMessage_locals_durationArgAt_(m, locals, 0);
    Duration_subtract_(DATA(self), DATA(d));
    return self; 
}

