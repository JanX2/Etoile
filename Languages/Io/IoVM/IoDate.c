/*#io
Date ioDoc(
           docCopyright("Steve Dekorte", 2002)
           docLicense("BSD revised")
           docDescription("A container for a date and time information.
credits: fromString method by Sean Perry")
		 docCategory("Time")
           */

#include "IoDate.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoObject.h"
#include "IoSeq.h"
#include "IoNumber.h"
#include "IoDuration.h"
#include "PortableStrptime.h"
#include <string.h>

#define DATA(self) ((Date *)IoObject_dataPointer(self))

IoTag *IoDate_tag(void *state)
{
    IoTag *tag = IoTag_newWithName_("Date");
    tag->state = state;
    tag->cloneFunc   = (TagCloneFunc *)IoDate_rawClone;
    tag->freeFunc    = (TagFreeFunc *)IoDate_free;
    tag->compareFunc = (TagCompareFunc *)IoDate_compare;
    tag->writeToStoreOnStreamFunc  = (TagWriteToStoreOnStreamFunc *)IoDate_writeToStore_stream_;
    tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoDate_readFromStore_stream_;
    return tag;
}

void IoDate_writeToStore_stream_(IoDate *self, IoStore *store, BStream *stream)
{
    BStream_writeTaggedDouble_(stream, Date_asSeconds(DATA(self)));
}

void IoDate_readFromStore_stream_(IoDate *self, IoStore *store, BStream *stream)
{
    Date_fromSeconds_(DATA(self), BStream_readTaggedDouble(stream));
}

IoDate *IoDate_proto(void *state)
{
    IoMethodTable methodTable[] = {
    {"now", IoDate_now},
    {"clock", IoDate_clock},
    {"copy", IoDate_copy},
    {"cpuSecondsToRun", IoDate_cpuSecondsToRun},
    {"year", IoDate_year},
    {"setYear", IoDate_setYear},
    {"month", IoDate_month},
    {"setMonth", IoDate_setMonth},
    {"day", IoDate_day},
    {"setDay", IoDate_setDay},
    {"hour", IoDate_hour},
    {"setHour", IoDate_setHour},
    {"minute", IoDate_minute},
    {"setMinute", IoDate_setMinute},
    {"second", IoDate_second},
    {"setSecond", IoDate_setSecond},
    {"isDaylightSavingsTime", IoDate_isDaylightSavingsTime},
    {"zone", IoDate_zone},
    {"isValidTime", IoDate_isValidTime},
    {"secondsSince", IoDate_secondsSince_},
    {"secondsSinceNow", IoDate_secondsSinceNow},
    {"isPast", IoDate_isPast},
    //{"dateAfterSeconds", IoDate_dateAfterSeconds_},
    {"asString", IoDate_asString},
    {"asNumber", IoDate_asNumber},
    {"fromNumber", IoDate_fromNumber},
    {"fromString", IoDate_fromString},
    {"print", IoDate_printDate},
    {"+", IoDate_add},
    {"-", IoDate_subtract},
    {"+=", IoDate_addInPlace},
    {"-=", IoDate_subtractInPlace},
    {NULL, NULL},
    };
    
    IoObject *self = IoObject_new(state);
    
    self->tag = IoDate_tag(state);
    IoObject_setDataPointer_(self, Date_new());
    IoObject_setSlot_to_(self, IOSYMBOL("format"), IOSYMBOL("%Y-%m-%d %H:%M:%S %Z"));
    IoState_registerProtoWithFunc_((IoState *)state, self, IoDate_proto);
    
    IoObject_addMethodTable_(self, methodTable);
    return self;
}

IoDate *IoDate_rawClone(IoDate *proto) 
{ 
    IoObject *self = IoObject_rawClonePrimitive(proto);
    IoObject_setDataPointer_(self, Date_new());
    Date_copy_(DATA(self), DATA(proto));
    return self; 
}

IoDate *IoDate_new(void *state)
{
    IoDate *proto = IoState_protoWithInitFunction_((IoState *)state, IoDate_proto);
    return IOCLONE(proto);
}

IoDate *IoDate_newWithTime_(void *state, time_t t)
{
    IoDate *self = IoDate_new(state);
    Date_fromTime_(DATA(self), t);
    return self;
}

IoDate *IoDate_newWithTimeval_(void *state, struct timeval tv)
{
    IoDate *self = IoDate_new(state);
    Date_setTimevalue_(DATA(self), tv);
    return self;
}

IoDate *IoDate_newWithLocalTime_(void *state, struct tm *t)
{
    IoDate *self = IoDate_new(state);
    Date_fromLocalTime_(DATA(self), t);
    return self;
}

void IoDate_free(IoDate *self)
{
    Date_free(DATA(self));
}

int IoDate_compare(IoDate *self, IoDate *date) 
{
    if (ISDATE(date)) return Date_compare(DATA(self), DATA(date)); 
    return ((ptrdiff_t)self->tag) - ((ptrdiff_t)date->tag);
}

// ----------------------------------------------------------- 

IoObject *IoDate_now(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("now", "Sets the receiver to the current time. Returns self.")
    */
    
    Date_now(DATA(self)); 
    return self; 
}

IoObject *IoDate_copy(IoDate *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("copy(aDate)", "Sets the receiver to be the same date as aDate. Returns self.")
	*/
	
	IoDate *date = IoMessage_locals_dateArgAt_(m, locals, 0); 
	
	Date_copy_(DATA(self), DATA(date)); 
	return self; 
}

IoObject *IoDate_clock(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("clock", "Returns a number containing the number of seconds 
of processor time since the beginning of the program or -1 if unavailable. ")
    */
    
    return IONUMBER(Date_Clock()); 
}

IoObject *IoDate_cpuSecondsToRun(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("cpuSecondsToRun(expression)", 
            "Evaluates message and returns a Number whose value is the cpu seconds taken to do the evaluation.")
    */
    
    IoMessage_assertArgCount_receiver_(m, 1, self);
    
    {
        clock_t t = clock();
        IoMessage *doMessage = IoMessage_rawArgAt_(m, 0);
        IoMessage_locals_performOn_(doMessage, locals, locals);
        return IONUMBER(((double)(clock() - t))/((double)CLOCKS_PER_SEC));
    }
}

IoObject *IoDate_year(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("year", 
            "Returns a number containing the year of the receiver. ")
    */
    
    return IONUMBER(Date_year(DATA(self))); 
}

IoObject *IoDate_setYear(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setYear(aNumber)", 
            "Sets the year of the receiver. ")
    */
    
    Date_setYear_(DATA(self), IoMessage_locals_intArgAt_(m, locals, 0));
    return self; 
}

IoObject *IoDate_month(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("month", 
            "Returns a number containing the month(1-12) of the year of the receiver. ")
    */
    
    return IONUMBER(Date_month(DATA(self))); 
}

IoObject *IoDate_setMonth(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setMonth(aNumber)", 
            "Sets the month(1-12) of the receiver. Returns self. ")
    */
    
    int v = IoMessage_locals_intArgAt_(m, locals, 0);
    IOASSERT(v >= 1 && v <= 12, "month must be within range 1-12");
    Date_setMonth_(DATA(self), v);
    return self; 
}

IoObject *IoDate_day(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("day", 
            "Returns a number containing the day of the month of the receiver. ")
    */
    
    return IONUMBER(Date_day(DATA(self))); 
}

IoObject *IoDate_setDay(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setDay(aNumber)", 
            "Sets the day of the receiver. Returns self.")
    */
    
    int v = IoMessage_locals_intArgAt_(m, locals, 0);
    int month = Date_month(DATA(self));
    
    IOASSERT(v >= 1 && v <= 31, "day must be within range 1-31");
    
    if (month == 2)
    {
        if (Date_isLeapYear(DATA(self)))
        {
            IOASSERT(v >= 1 && v <= 29, "day must be within range 1-29");
        }
        else
        {
            IOASSERT(v >= 1 && v <= 28, "day must be within range 1-28");
        }
    } else if (month == 11) 
    {
	    IOASSERT(v >= 1 && v <= 30, "day must be within range 1-30");
    } else if (month == 12) 
    {
	    IOASSERT(v >= 1 && v <= 31, "day must be within range 1-31");
    }
	
    Date_setDay_(DATA(self), v);
    return self; 
}

IoObject *IoDate_hour(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("hour", 
            "Returns a number containing the hour of the day(0-23) of the receiver. ")
    */
    
    return IONUMBER(Date_hour(DATA(self))); 
}

IoObject *IoDate_setHour(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setHour(aNumber)", 
            "Sets the hour of the receiver. Returns self.")
    */
    
    int v = IoMessage_locals_intArgAt_(m, locals, 0);
    IOASSERT(v >= 0 && v <= 23, "hour must be within range 0-23");
    Date_setHour_(DATA(self), v);
    return self; 
}

IoObject *IoDate_minute(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("minute", 
            "Returns a number containing the minute of the hour(0-59) of the receiver. ")
    */
    
    return IONUMBER(Date_minute(DATA(self))); 
}


IoObject *IoDate_setMinute(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setMinute(aNumber)", 
            "Sets the minute of the receiver. Returns self.")
    */
    
    int v = IoMessage_locals_intArgAt_(m, locals, 0);
    IOASSERT(v >= 0 && v <= 59, "minute must be within range 0-59");
    Date_setMinute_(DATA(self), v);
    return self; 
}

IoObject *IoDate_second(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("second", 
            "Returns a number containing the seconds of the minute(0-59) of the receiver. This number may contain fractions of seconds. ")
    */
    
    return IONUMBER(Date_second(DATA(self))); 
}


IoObject *IoDate_setSecond(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("setSecond(aNumber)", 
            "Sets the second of the receiver. Returns self.")
    */
    
    int v = IoMessage_locals_intArgAt_(m, locals, 0);
    IOASSERT(v >= 0 && v <= 59, "second must be within range 0-59");
    Date_setSecond_(DATA(self), v);
    return self; 
}

IoObject *IoDate_zone(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("zone", 
            "Returns a string containing the time zone code of the receiver. ")
    */
    
    time_t t = time(NULL);
    const struct tm *tp = localtime(&t);
    char s[32];
    strftime(s, 32,"%Z", tp);
    return IOSYMBOL(s);
}

IoObject *IoDate_isDaylightSavingsTime(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("isDaylightSavingsTime", 
            "Returns self if Daylight Saving Time is in effect for the receiver, otherwise returns Nil. ")
    */
    
    return IOBOOL(self, Date_isDaylightSavingsTime(DATA(self))); 
}

IoObject *IoDate_isValidTime(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("validTime(hour, min, sec)", 
            "Returns self if the specified time is valid, otherwise returns Nil. A negative value will count back; i.e., a value of -5 for the hour, will count back 5 hours to return a value of 19. No adjustment is done for values above 24.")
    */
    
    int hour = IoMessage_locals_intArgAt_(m, locals, 0);
    int min = IoMessage_locals_intArgAt_(m, locals, 1);
    int sec = IoMessage_locals_intArgAt_(m, locals, 2);
    
    if (hour < 0) hour += 24;
    if (min < 0) min += 60;
    if (sec < 0) sec += 60;
    
    return IOBOOL(self, ((hour >= 0) && (hour < 24)) &&
        ((min >= 0) && (min < 60)) &&
        ((sec >= 0) && (sec <  60)));
}

IoObject *IoDate_secondsSince_(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("secondsSince(aDate)", 
            "Returns a number of seconds of between aDate and the receiver. ")
    */
    
    IoDate *date = IoMessage_locals_dateArgAt_(m, locals, 0); 
    return IONUMBER(Date_secondsSince_(DATA(self), DATA(date)));
}

IoObject *IoDate_secondsSinceNow(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("secondsSinceNow(aDate)", "Returns the number of seconds since aDate. ")
    */
    
    return IONUMBER(Date_secondsSinceNow(DATA(self))); 
}

IoObject *IoDate_isPast(IoDate *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("isPast", "Returns true if the receiver is a date in the past. ")
	*/
	
	return IOBOOL(self, Date_secondsSinceNow(DATA(self)) > 0); 
}

/*
IoObject *IoDate_dateAfterSeconds_(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    docSlot("dateAfterSeconds(secondsNumber)", 
            "Returns a new date that is secondsNumber seconds after the receiver. ")
    
    IoDate *newDate = IoDate_new(IOSTATE);
    Date_addSeconds_(DATA(newDate), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return newDate;
}
*/

IoObject *IoDate_asString(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("asString(optionalFormatString)", 
            """Returns a string representation of the receiver using the 
receivers format. If the optionalFormatString argument is present, the 
receiver's format is set to it first. Formatting is according to ANSI C 
date formating rules.

<pre>
%a abbreviated weekday name (Sun, Mon, etc.)
%A full weekday name (Sunday, Monday, etc.) 
%b abbreviated month name (Jan, Feb, etc.) 
%B full month name (January, February, etc.) 
%c full date and time string 
%d day of the month as two-digit decimal integer (01-31) 
%H hour as two-digit 24-hour clock decimal integer (00-23) 
%I hour as two-digit 12-hour clock decimal integer (01-12) 
%m month as a two-digit decimal integer (01-12)
%M minute as a two-digit decimal integer (00-59) 
%p either "AM" or "PM" 
%S second as a two-digit decimal integer (00-59) 
%U number of week in the year as two-digit decimal integer (00-52) 
with Sunday considered as first day of the week 
%w weekday as one-digit decimal integer (0-6) with Sunday as 0 
%W number of week in the year as two-digit decimal integer (00-52) 
with Monday considered as first day of the week 
%x full date string (no time); in the C locale, this is equivalent 
to "%m/%d/%y". 
%y year without century as two-digit decimal number (00-99) 
%Y year with century as four-digit decimal number 
%Z time zone name (e.g. EST); 
null string if no time zone can be obtained 
%% stands for '%' character in output string. 
</pre>
""")
    */
    
    char *format = "%Y-%m-%d %H:%M:%S %Z";
    
    if (IoMessage_argCount(m) == 1)
    { 
        format = CSTRING(IoMessage_locals_symbolArgAt_(m, locals, 0)); 
    }
    else
    { 
        IoObject *f = IoObject_getSlot_(self, IOSYMBOL("format"));
        if (ISSEQ(f)) { format = CSTRING(f); }
    }
    
    {
        ByteArray *ba = Date_asString(DATA(self), format);
        return IoState_symbolWithByteArray_copy_(IOSTATE, ba, 0);
    }
}

IoObject *IoDate_printDate(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("print", "Prints the receiver. Returns self.")
    */
    
    IoSymbol *s = (IoSymbol *)IoDate_asString(self, locals, m);
    IoSeq_print(s, locals, m);
    return self; 
}

IoObject *IoDate_asNumber(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("asNumber", "Returns the date as seconds since 1970.")
    */
    
    return IONUMBER(Date_asSeconds(DATA(self))); 
}

IoObject *IoDate_fromNumber(IoDate *self, IoObject *locals, IoMessage *m)
{ 
    /*#io
    docSlot("fromNumber(aNumber)", "Sets the receiver to be aNumber seconds since 1970.")
    */
    
    Date_fromSeconds_(DATA(self), IoMessage_locals_doubleArgAt_(m, locals, 0));
    return self;
}

IoObject *IoDate_fromString(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("fromString(aString, formatString)", "Sets the receiver to the date specified by aString as parsed according to the given formatString. See the Date asString method for formating rules. Returns self. ")
    */
    
    IoMessage_assertArgCount_receiver_(m, 2, self);
    {
        IoSymbol *date_input = IoMessage_locals_seqArgAt_(m, locals, 0);
        IoSymbol *format = IoMessage_locals_seqArgAt_(m, locals, 1);
        Date_fromString_format_(DATA(self), CSTRING(date_input), CSTRING(format));
    }
    return self;
}

/* --- Durations -------------------------------------------------------- */

IoObject *IoDate_subtract(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("-(aDurationOrDate)", "Return a new Date with the receiver's value minus an amount of time specified by aDuration to the receiver. Returns self. ")
    */
    
    IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	
    if (ISDATE(v))
    {
        double d = Date_secondsSince_(DATA(self), DATA(v));
        return IoDuration_newWithSeconds_(IOSTATE, d);
    } 
    else if (ISDURATION(v))
    {
        IoDate *newDate = IOCLONE(self);
        Date_subtractDuration_(DATA(newDate), IoDuration_duration(v));
        return newDate;  
    }
    
    IOASSERT(1, "Date or Duration argument required");
    
    return IONIL(self);
}

IoObject *IoDate_subtractInPlace(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("-=(aDuration)", "Subtract aDuration from the receiver. Returns self.") 
    */
    
    IoDuration *d = IoMessage_locals_durationArgAt_(m, locals, 0);
    Date_subtractDuration_(DATA(self), IoDuration_duration(d));
    return self;
}

IoObject *IoDate_addInPlace(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("+=(aDuration)", "Add aDuration to the receiver. Returns self. ")
    */
    
    IoDuration *d = IoMessage_locals_durationArgAt_(m, locals, 0);
    Date_addDuration_(DATA(self), IoDuration_duration(d));
    return self;
}

IoObject *IoDate_add(IoDate *self, IoObject *locals, IoMessage *m)
{
    /*#io
    docSlot("+(aDuration)", "Return a new Date with the receiver's value plus an amount of time specified by aDuration object to the receiver. ")
    */
    
    IoDate *newDate = IOCLONE(self);
    return IoDate_addInPlace(newDate, locals, m);
}
