/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "Database.h"
#import "NSBundle+Extensions.h"

static id<Database> sharedDatabase = nil;

NSString* const GrrDatabasePluginNameDefaults = @"DatabasePluginName";
NSString* const DatabaseChangeNotification = @"DatabaseChangeNotification";

@implementation Database

+(id<Database>) shared
{
    if (sharedDatabase == nil) {
        // Find out the name of the database plugin to be loaded. The default is
        // "TreeDatabase", but it can be overridden using the DatabasePluginName
        // user default. For details, see the documentation on hacking a database
        // in the documentation directory.
        NSString* databasePluginName =
            [[NSUserDefaults standardUserDefaults] objectForKey: GrrDatabasePluginNameDefaults];
        
        if (databasePluginName == nil) {
            databasePluginName = @"TreeDatabase";
        }
        
        id<Database> database = [NSBundle instanceForBundleWithName: databasePluginName type: @"grrdb"];
        
        NSAssert(database != nil, @"The database could not be loaded!");
        NSAssert1(
            [database conformsToProtocol: @protocol(Database)],
            @"Database %@ does not conform to the database protocol.",
            database
        );
        
        ASSIGN(sharedDatabase, database);
    }
    
    return sharedDatabase;
}

@end
