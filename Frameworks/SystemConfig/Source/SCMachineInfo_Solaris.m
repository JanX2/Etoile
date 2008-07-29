/*
 * SCMachineInfo_Solaris.m - Solaris specific backend for SCMachineInfo
 *
 */

#ifdef SOLARIS

#import <Foundation/NSString.h>
#import "SCMachineInfo.h"

#import <stdio.h>
#import <kstat.h>
#import <fcntl.h>
#import <unistd.h>
#import <sys/sysconfig.h>

static kstat_ctl_t *kernelDesc;

extern int _sysconfig (int foo);

@implementation SCMachineInfo (Solaris)

+ (void) initialize
{
  if (!(kernelDesc = kstat_open ()))
    {
      perror ("kstat_open");
    }
}

+ (long) getKStatNumber: (kstat_ctl_t *) kernelDesc
                       : (char *) moduleName
                       : (char *) recordName
                       : (char *) fieldName
{
  kstat_t *kstatRecordPtr;
  kstat_named_t *kstatFields;
  long value = 0L;
  uint32_t i;

  if (!(kstatRecordPtr = kstat_lookup (kernelDesc, moduleName, -1,
                                       recordName)))
    {
      return -1;
    }

  if (kstat_read (kernelDesc, kstatRecordPtr, NULL) < 0)
    {
      return -1;
    }

  kstatFields = KSTAT_NAMED_PTR (kstatRecordPtr);

  for (i = 0; i < kstatRecordPtr->ks_ndata; i++)
    {
      if (!strcmp (kstatFields[i].name, fieldName))
        {
          switch(kstatFields[i].data_type)
            {
            case KSTAT_DATA_INT32:
              value = kstatFields[i].value.i32;
              break;

            case KSTAT_DATA_UINT32:
              value = kstatFields[i].value.ui32;
              break;

            case KSTAT_DATA_INT64:
              value = kstatFields[i].value.i64;
              break;

            case KSTAT_DATA_UINT64:
              value = kstatFields[i].value.ui64;
              break;

            default:
              value = -1;
              break;
            }

          return value;
        }
    }
  
  return -1;
}

+ (char *) getKStatString: (kstat_ctl_t *) kernelDesc
                         : (char *) moduleName
                         : (char *) recordName
                         : (char *) fieldName
{
  kstat_t *kstatRecordPtr;
  kstat_named_t *kstatFields;
  char *value;
  uint32_t i = 0;

  if (!(kstatRecordPtr = kstat_lookup (kernelDesc, moduleName, -1,
                                       recordName)))
    {
      return NULL;
    }

  if (kstat_read (kernelDesc, kstatRecordPtr, NULL) < 0)
    {
      return NULL;
    }

  kstatFields = KSTAT_NAMED_PTR (kstatRecordPtr);
  
  for (i = 0; i < kstatRecordPtr->ks_ndata; i++)
  {
    if (!strcmp (kstatFields[i].name, fieldName))
      {
        switch (kstatFields[i].data_type)
          {
          case KSTAT_DATA_CHAR:
            value = kstatFields[i].value.c;
            break;

          case KSTAT_DATA_STRING:
            value = kstatFields[i].value.string.addr.ptr;
            break;

          default:
            value = NULL;
            break;
          }

        return value;
      }
    }

  return NULL;
}

+ (NSString *) machineType
{
  return [NSString stringWithUTF8String:
           [self getKStatString: kernelDesc
                               : "cpu_info"
                               : "cpu_info0"
                               : "cpu_type"]];
}

+ (unsigned long long) realMemory
{
  return _sysconfig (_CONFIG_PAGESIZE) * _sysconfig (_CONFIG_PHYS_PAGES);
}

+ (unsigned int) cpuMHzSpeed
{
  return [self getKStatNumber: kernelDesc
                             : "cpu_info"
                             : "cpu_info0"
                             : "clock_MHz"];
}

+ (NSString *) cpuName
{
  return [NSString stringWithUTF8String:
           [self getKStatString: kernelDesc
                               : "cpu_info"
                               : "cpu_info0"
                               : "brand"]];
}

+ (BOOL) platformSupported
{
  return YES;
}

@end
      
#endif // SOLARIS
