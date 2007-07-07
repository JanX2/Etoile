/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */


@protocol DefinitionWriter

-(void) beginWriting;
-(void) endWriting;

-(void) clearResults;
-(void) writeBigHeadline: (NSString*) aString;
-(void) writeHeadline: (NSString*) aString;
-(void) writeLine: (NSString*) aString;
-(void) writeString: (NSString*) aString link: (id) aClickable;

@end

