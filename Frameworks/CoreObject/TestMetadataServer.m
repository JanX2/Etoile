/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileSerialize/EtoileSerialize.h>
#import <UnitKit/UnitKit.h>
#import <postgresql/libpq-fe.h>
#import "COMetadataServer.h"
#import "COSerializer.h"
#import "CODeserializer.h"
#import "COUtility.h"

#define FM [NSFileManager defaultManager]
#define TMP_URL [NSURL fileURLWithPath: [FM tempDirectory]]

@interface COMetadataServer (TestMetadataServer) <UKTest>
@end


@implementation COMetadataServer (TestMetadataServer)

/* We patch the DB name to create a DB reserved to tests. */
+ (NSString *) defaultDBName
{
	return @"coreobjecttest";
}

- (void) testDBConnection
{
	conn = PQsetdb(NULL, NULL, NULL, NULL, "unknowndb");
	UKIntsEqual(CONNECTION_BAD, PQstatus(conn));
	[self closeDBConnection];

	/* Try access the internal db of pgsql */
	conn = PQsetdb(NULL, NULL, NULL, NULL, "postgres");
	UKIntsEqual(CONNECTION_OK, PQstatus(conn));
	[self closeDBConnection];
}

- (void) testOpenDBConnectionWithURL
{
	id url = [NSURL URLWithString: [NSString stringWithFormat: 
		@"pgsql://%s@localhost/postgres", getenv("USER")]];

	UKTrue([self openDBConnectionWithURL: url]);
	UKIntsEqual(CONNECTION_OK, PQstatus(conn));
	[self closeDBConnection];
}

- (void) testSetUpDBWithURL
{
	id testDBURL = [NSURL URLWithString: @"pgsql://localhost/coreobjectbasictest"];
	id pgsqlDBURL = [NSURL URLWithString: @"pgsql://localhost/postgres"];

	[self setUpDBWithURL: testDBURL];
	/* -setUpDBWithURL: doesn't result in an open connection and cannot drop a 
	   a db if connected to it, so another connection is necessary... */
	[self openDBConnectionWithURL: pgsqlDBURL];
	[self executeDBRequest: @"DROP DATABASE CoreObjectBasicTest;"];
	[self closeDBConnection];
}

- (void) testInit
{
	id server = [[COMetadataServer alloc] initWithURL: nil shouldCreateDBIfNeeded: NO];

	UKNotNil(server);
	UKNotNil([server storeURL]);
	//UKObjectsEqual(url, [server storeURL]);
}

- (id) initForTest
{
	return [self initWithURL: nil shouldCreateDBIfNeeded: YES];
}

+ (void) testDefaultStoreURL
{
	UKNotNil([self defaultStoreURL]);
}

+ (void) testDefaultServer
{
	UKNotNil([self defaultServer]);
}

- (void) testUUIDForURL
{
	id url = TMP_URL;
	id url2 = TMP_URL;
	id uuid = [ETUUID UUID];

	[self setURL: url forUUID: uuid];
	UKObjectsEqual(uuid, [self UUIDForURL: url]);
	UKObjectsNotEqual(uuid, [self UUIDForURL: url2]);
}

- (void) testURLForUUID
{

	id url = TMP_URL;
	id uuid = [ETUUID UUID];
	id uuid2 = [ETUUID UUID];

	[self setURL: url forUUID: uuid];

	UKObjectsEqual(url, [self URLForUUID: uuid]);
	UKObjectsNotEqual(url, [self URLForUUID: uuid2]);

	[self setURL: url forUUID: uuid2];

	UKObjectsEqual([self URLForUUID: uuid], [self URLForUUID: uuid2]);

	[self setURL: TMP_URL forUUID: uuid];

	UKObjectsNotEqual([self URLForUUID: uuid], [self URLForUUID: uuid2]);
}

- (void) testRemoveURLForUUID
{
	id url = TMP_URL;
	id uuid = [ETUUID UUID];

	[self setURL: url forUUID: uuid];
	[self removeURLForUUID: uuid];

	UKNil([self URLForUUID: uuid]);
}

@end
