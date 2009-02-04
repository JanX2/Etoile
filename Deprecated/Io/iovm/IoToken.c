/*   
docCopyright("Steve Dekorte", 2002)
docLicense("BSD revised")
*/

#include "IoToken.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

IoToken *IoToken_new(void)
{
    IoToken *self = (IoToken *)calloc(1, sizeof(IoToken));
    self->name = NULL;
    self->charNumber = -1;
    
    return self;
}

void IoToken_free(IoToken *self)
{
    if (self->name) free(self->name);
    if (self->error) free(self->error);
    free(self);
}

const char *IoToken_typeName(IoToken *self)
{ 
    switch (self->type)
    {
        case NO_TOKEN:         return "NoToken"; 
        case OPENPAREN_TOKEN:  return "OpenParen"; 
        case COMMA_TOKEN:      return "Comma"; 
        case CLOSEPAREN_TOKEN: return "CloseParen"; 
        case MONOQUOTE_TOKEN:  return "MonoQuote"; 
        case TRIQUOTE_TOKEN:   return "TriQuote"; 
        case IDENTIFIER_TOKEN: return "Identifier"; 
        case TERMINATOR_TOKEN: return "Terminator"; 
        case COMMENT_TOKEN:    return "Comment";
        case NUMBER_TOKEN:     return "Number"; 
        case HEXNUMBER_TOKEN:  return "HexNumber";
    }
    return "UNKNOWN_TOKEN";
}

void IoToken_name_length_(IoToken *self, const char *name, size_t len)
{ 
    self->name = strncpy(realloc(self->name, len + 1), name, len);
    self->name[len] = (char)0;
    self->length = len;
}

void IoToken_name_(IoToken *self, const char *name)
{ 
    self->name = strcpy((char *)realloc(self->name, strlen(name) + 1), name);
    self->length = strlen(name);
}

char *IoToken_name(IoToken *self) 
{ 
    return self->name ? self->name : (char *)""; 
}

void IoToken_error_(IoToken *self, const char *error)
{ 
    self->error = strcpy((char *)realloc(self->error, strlen(error) + 1), error); 
}

char *IoToken_error(IoToken *self) 
{ 
    return self->error ? self->error : (char *)""; 
}

int IoToken_nameIs_(IoToken *self, const char *name)
{ 
    if (strlen(self->name) == 0 && strlen(name) != 0) 
    {
        return 0;
    }
    //return !strncmp(self->name, name, self->length);
    return !strcmp(self->name, name);
}

IoTokenType IoToken_type(IoToken *self) 
{ 
    return self->type; 
}

int IoToken_lineNumber(IoToken *self) 
{ 
    return self->lineNumber; 
}

int IoToken_charNumber(IoToken *self) 
{ 
    return self->charNumber; 
}

void IoToken_quoteName_(IoToken *self, const char *name)
{ 
    char *old = self->name;
    size_t length = strlen(name) + 3;
    self->name = malloc(length); 
    snprintf(self->name, length, "\"%s\"", name);
    
    if (old) 
    {
        free(old);
    }
}

void IoToken_type_(IoToken *self, IoTokenType type)
{ 
    self->type = type; 
}

void IoToken_nextToken_(IoToken *self, IoToken *nextToken)
{
    if (self == nextToken) 
    { 
        printf("next == self!\n"); 
        exit(1); 
    }
    
    if (self->nextToken) 
    {
        IoToken_free(self->nextToken);
    }
    
    self->nextToken = nextToken;
}

void IoToken_print(IoToken *self)
{
    IoToken_printSelf(self);
}

void IoToken_printSelf(IoToken *self)
{
    size_t i;
    printf("'");
    
    for (i = 0; i < self->length; i ++) 
    {
        putchar(self->name[i]);
    }
    
    printf("' ");
}

int IoTokenType_isValidMessageName(IoTokenType self)
{
    switch (self)
    {
        case IDENTIFIER_TOKEN:
        case MONOQUOTE_TOKEN:
        case TRIQUOTE_TOKEN:
        case NUMBER_TOKEN:
        case HEXNUMBER_TOKEN:
            return 1;
        default:
            return 0;
    }
    return 0;
}

