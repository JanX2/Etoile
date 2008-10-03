/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "COObjectContext.h"
#import "COObject.h"
#import "COGroup.h"
#import "COSerializer.h"
#import "CODeserializer.h"
#import "COMetadataServer.h"
#import "COObjectServer.h"

@interface COObjectContext (GraphRollback)
- (NSMutableDictionary *) findAllObjectVersionsMatchingContextVersion: (int)aVersion;
@end


@implementation COObjectContext (GraphRollback)

// TODO: Break -rollbackToVersion: in several small methods.

/* Query example:
SELECT objectUUID, objectVersion, contextVersion FROM (SELECT objectUUID, objectVersion, contextVersion FROM HISTORY WHERE contextUUID = '64dc7e8f-db73-4bcc-666f-d9bf6b77a80a') AS ContextHistory WHERE contextVersion > 2000 ORDER BY contextVersion DESC LIMIT 10 */
- (void) _rollbackToVersion: (int)aVersion
{
	_revertingContext = YES;

	NSMutableDictionary *rolledbackObjectVersions = 
		[self findAllObjectVersionsMatchingContextVersion: aVersion];

	/* Find the base versions for objects that don't appear in the context history

	    Base versions (first snapshot) aren't written in the context history, 
	    only recorded invocations are, hence if we haven't reached the targeted 
	    context version but we just reached the first recorded invocation of an 
	    object (version 1), the expected objectVersion to roll back will be 0 
	    and not 1. */
	FOREACHI(_registeredObjects, registeredObject)
	{
		// NOTE: [registeredObject objectVersion] > 0 ensures that we won't 
		// restore an object that hasn't been yet snaphotted (no invocation recorded yet).
		if ([rolledbackObjectVersions objectForKey: [registeredObject UUID]] == nil
		 && [registeredObject objectVersion] > 0)
		{
			[rolledbackObjectVersions setObject: [NSNumber numberWithInt: 0]
			                             forKey: [registeredObject UUID]];
		}
		// TODO: Generalize the idea to handle trimmed history...
		// This done by querying contextVersion superior to aVersion rather than 
		// inferior as we do in the first query.
		// SELECT [...] WHERE contextVersion > aVersion ORDER BY contextVersion
		// foreach registeredObject not in rolledbackObjectVersions
		// {
		//		version = first object version right after aVersion
		//	    rolledbackObjectVersions setObject: --version forKey: [object UUID]
		// }
	}

	ETLog(@"Will revert objects to versions: %@", rolledbackObjectVersions);

	/* Revert all the objects we just found */
	NSMutableSet *mergedObjects = [NSMutableSet set];
	id objectServer = [self objectServer];
	FOREACHI([rolledbackObjectVersions allKeys], targetUUID)
	{
		id targetObject = [objectServer cachedObjectForUUID: targetUUID];
		BOOL targetRegisteredInContext = (targetObject != nil && [_registeredObjects containsObject: targetObject]);

		if (targetRegisteredInContext)
		{
			int targetVersion = [[rolledbackObjectVersions objectForKey: targetUUID] intValue];
			BOOL targetUpToDate = (targetVersion == [targetObject objectVersion]);

			/* Only revert the objects that have changed between aVersion and the 
			   current context version */
			if (targetUpToDate)
				continue;

			/* Revert and merge */
			id rolledbackObject = [self objectByRollingbackObject: targetObject 
			                                            toVersion: targetVersion
			                                     mergeImmediately: YES];
			[mergedObjects addObject: rolledbackObject];
		}
	}

	/* Log the revert operation in the History */
	_version++;
	[[self metadataServer] executeDBRequest: [NSString stringWithFormat: 
		@"INSERT INTO History (objectUUID, objectVersion, contextUUID, "
		"contextVersion, date) "
		"VALUES ('%@', %i, '%@', %i, '%@');", 
			[_uuid stringValue],
			aVersion,
			[_uuid stringValue],
			_version,
			[NSDate date]]];

	ETLog(@"Log revert context with UUID %@ to version %i as new version %i", 
		 _uuid, aVersion, _version);

	/* Post notification */
	[[NSNotificationCenter defaultCenter] 
		postNotificationName: COObjectContextDidMergeObjectsNotification
		object: self
		userInfo: D(COMergedObjectsKey, mergedObjects)];

	_revertingContext = NO;
}

/* Collects the object versions at a given context version and returns them in 
   a dictionary keyed by the UUIDs of the matched objects. */
- (NSMutableDictionary *) findAllObjectVersionsMatchingContextVersion: (int)aVersion
{
	/* Query the global history for the history of the context before aVersion */
	NSString *query = [NSString stringWithFormat: 
		@"SELECT objectUUID, objectVersion, contextVersion FROM \
			(SELECT objectUUID, objectVersion, contextVersion FROM History \
			 WHERE contextUUID = '%@') AS ContextHistory \
		  WHERE contextVersion < %i ORDER BY contextVersion DESC", 
		[[self UUID] stringValue], (aVersion + 1)];

	PGresult *result = [[self metadataServer] executeRawPGSQLQuery: query];
	int nbOfRows = PQntuples(result);
	int nbOfCols = PQnfields(result);
	ETUUID *objectUUID = nil;
	int objectVersion = -1;
	int contextVersion = -1;
	/* Collection where the object versions to be rolled back are put keyed by UUIDs */
	NSMutableDictionary *rolledbackObjectVersions = [NSMutableDictionary dictionary];

	ETLog(@"Context rollback query result: %d rows and %d colums", nbOfRows, nbOfCols);

	/* Log the query result for debugging */
	PQprintOpt options = {0};
	options.header    = 1;    /* Ask for column headers           */
	options.align     = 1;    /* Pad short columns for alignment  */
	options.fieldSep  = "|";  /* Use a pipe as the field separator*/
	PQprint(stdout, result, &options);

	/* Find all the objects to be reverted */ 
	int nbOfRegisteredObjects = [_registeredObjects count];
	for (int row = 0; row < nbOfRows; row++)
	{
		objectUUID = AUTORELEASE([[ETUUID alloc] initWithString: 
			[NSString stringWithUTF8String: PQgetvalue(result, row, 0)]]);
		objectVersion = atoi(PQgetvalue(result, row, 1));
		contextVersion = atoi(PQgetvalue(result, row, 2));

		BOOL objectNotAlreadyFound = ([[rolledbackObjectVersions allKeys] containsObject: objectUUID] == NO);

		if (objectNotAlreadyFound)
		{
			[rolledbackObjectVersions setObject: [NSNumber numberWithInt: objectVersion] 
			                             forKey: objectUUID];
		}

		/* If a past object version has already been found for each registered 
		   object, we already know all the objects to be reverted, hence we 
		   can skip the rest of the earlier history. */
		if ([rolledbackObjectVersions count] == nbOfRegisteredObjects)
			break;
	}
	
	/* Free the query result now the object versions are extracted */
	PQclear(result);
	
	return rolledbackObjectVersions;
}

@end
