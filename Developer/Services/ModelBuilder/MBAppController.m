/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileSerialize/EtoileSerialize.h>
#import "MBAppController.h"
#import "ETModelRepository.h"
#import "MBLayoutItemFactory.h"

static ETUTI *packageUTI = nil;
static ETUTI *repositoryUTI = nil;

@implementation MBAppController

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(openedRepositories);
	[super dealloc];
}

- (id) init
{
	SUPERINIT;
	ASSIGN(itemFactory, [MBLayoutItemFactory factory]);
	openedRepositories = [[NSMutableSet alloc] init];

	packageUTI = [ETUTI registerTypeWithString: @"org.etoile-project.objc.class.ETPackageDescription"
		                       description: @"Etoile Metamodel Package and Document (see ETPackageDescription in EtoileFoundation)"
		                  supertypeStrings: [NSArray array]
	                                  typeTags: D(A(@"pkgdesc"), kETUTITagClassFileExtension)];
	repositoryUTI = [ETUTI registerTypeWithString: @"org.etoile-project.objc.class.ETModelRepository"
		                          description: @"Etoile Model Repository (see ETModelRepository in EtoileFoundation)"
		                     supertypeStrings: [NSArray array]
	                                     typeTags: D(A(@"modelrepo"), kETUTITagClassFileExtension)];

	ETAssert([[ETUTI typeWithClass: [ETPackageDescription class]] isEqual: packageUTI]);
	ETAssert([[ETUTI typeWithClass: [ETModelRepository class]] isEqual: repositoryUTI]);

	ETLayoutItemGroup *repoItem = [itemFactory browserWithRepository: [ETModelRepository mainRepository]];
	ETLayoutItemGroup *docItem = [itemFactory editorWithPackageDescription: AUTORELEASE([[ETPackageDescription alloc] init])];

	[self setTemplate: [MBRepositoryBrowserTemplate templateWithItem: repoItem objectClass: Nil]
	          forType: [ETUTI typeWithClass: [ETModelRepository class]]];
	[self setTemplate: [MBPackageEditorTemplate templateWithItem: docItem objectClass: Nil] 
	          forType: [ETUTI typeWithClass: [ETPackageDescription class]]];

	[self setTemplate: [MBRepositoryBrowserTemplate templateWithItem: repoItem objectClass: Nil]
	          forType: kETTemplateGroupType];
	[self setTemplate: [MBPackageEditorTemplate templateWithItem: docItem objectClass: Nil] 
	          forType: kETTemplateObjectType];

	return self;
}

- (NSArray *) supportedTypes
{
	return A(packageUTI, repositoryUTI);
}

- (void) editAnonymousPackageDescription
{
	ETPackageDescription *packageDesc = [[ETModelDescriptionRepository mainRepository] anonymousPackageDescription];
	[[itemFactory windowGroup] addObject: [itemFactory editorWithPackageDescription: packageDesc]];
	id editor = [itemFactory editorWithPackageDescription: packageDesc];
	[[itemFactory windowGroup] addObject: [editor deepCopy]];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	// NOTE: If we introduce an ETPackageEditorLayout that routes the 
	// represented object, then we can use -setTemplateItem: and write -newObject in another way.
	//[self setTemplateItem: [itemFactor editorWithPackageDescription: [ETPackageDescription descriptionWithName: _(@"Untitled")]]];
#if 0
	NSArray *choices = A(_(@"Properties"), _(@"Operations"), _(@"Instances"));
	ETLayoutItem *popUpItem = [itemFactory popUpMenuWithItemTitles: choices
		                                 representedObjects: nil
		                                             target: nil 
		                                             action: @selector(changePresentedContent:)];

	[[popUpItem view] selectItemWithTitle: @"Instances"];
	//ETLog(@"Archive %@", [[[popUpItem view] cell] XMLArchive]);
	[popUpItem setFrame: NSMakeRect(30, 30, 200, 100)];
	[[itemFactory windowGroup] addItem: popUpItem];
	[[itemFactory windowGroup] addItem: [popUpItem copy]];
#endif
	[[itemFactory windowGroup] setController: self];
	[self editAnonymousPackageDescription];
}

- (IBAction) openAndBrowseRepository: (id)sender
{
	// TODO: Bring an open panel	
}

- (IBAction) browseMainRepository: (id)sender
{
	ETModelRepository *repo = [ETModelRepository mainRepository];
	[openedRepositories addObject: repo];
	[[itemFactory windowGroup] addObject: [itemFactory browserWithRepository: repo]];
}

@end


@implementation MBRepositoryBrowserTemplate

- (NSString *) baseName
{
	return [NSString stringWithFormat: @"%@ %@", [super baseName], _(@"Repository")];
}

/** Instantiates a new repository and returns a new item group to edit it with a repository browser UI. */
- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	ETModelRepository *repo = [[ETModelRepository alloc] 
		initWithMetaRepository: AUTORELEASE([[ETModelDescriptionRepository alloc] init])];
	ETLayoutItem *item = [self newItemWithRepresentedObject: AUTORELEASE(repo) options: options];

	[item setName: [self nameFromBaseNameAndOptions: options]];

	return item;
}

@end


@implementation MBPackageEditorTemplate

- (NSString *) baseName
{
	return [NSString stringWithFormat: @"%@ %@", [super baseName], _(@"Package")];
}

/** Instantiates a new package description and returns a new item group to edit it with a package editor UI. */
- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	ETPackageDescription *packageDesc = 
		[ETPackageDescription descriptionWithName: [self nameFromBaseNameAndOptions: options]];

	// TODO: Should be 
	// return [self newItemWithRepresentedObject: packageDesc options: options];
	return RETAIN([[MBLayoutItemFactory factory] editorWithPackageDescription: packageDesc]);
}

- (ETLayoutItem *) newItemReadFromURL: (NSURL *)aURL options: (NSDictionary *)options
{
	CREATE_AUTORELEASE_POOL(pool);
	ETDeserializer *deserializer = [[ETSerializer serializerWithBackend: [ETSerializerBackendXML class]
	                                                             forURL: aURL] deserializer];
	[deserializer setVersion: 0];
	id object = RETAIN([deserializer restoreObjectGraph]);
	DESTROY(pool);

	ETLayoutItem *newItem = [self newItemWithRepresentedObject: object options: options];
	RELEASE(object);
 
	NSLog(@"Did open %@ from %@ with new item %@", object, aURL, newItem);	

	return newItem;
}


- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options
{
	NSURL *saveURL = [self URLFromRunningSavePanel];

	if (saveURL == nil) return NO;

	NSLog(@"Will save %@ at %@", [anItem representedObject], saveURL);

	CREATE_AUTORELEASE_POOL(pool);
	id object = [anItem representedObject];
	ETSerializer *serializer = [ETSerializer serializerWithBackend: [ETSerializerBackendXML class]
	                                                        forURL: saveURL];
	[serializer serializeObject: object withName: @"root"];
	DESTROY(pool);

	return YES;
}

@end
