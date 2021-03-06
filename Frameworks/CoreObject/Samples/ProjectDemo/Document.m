#import "Document.h"

@implementation Document

+ (ETEntityDescription*)newEntityDescription
{
    ETEntityDescription *docEntity = [ETEntityDescription descriptionWithName: @"Document"];
    [docEntity setParent: (id)@"COObject"];
    
	ETPropertyDescription *projectProperty = [ETPropertyDescription descriptionWithName: @"project"
                                                                                  type: (id)@"Project"];
	[projectProperty setOpposite: (id)@"Project.documents"];
    [projectProperty setPersistent: NO];
	
    ETPropertyDescription *screenRectProperty = [ETPropertyDescription descriptionWithName: @"screenRect"
                                                                                      type: (id)@"NSRect"];
    [screenRectProperty setPersistent: YES];
    
    ETPropertyDescription *isOpenProperty = [ETPropertyDescription descriptionWithName: @"isOpen"
                                                                                  type: (id)@"NSNumber"];
    [isOpenProperty setPersistent: YES];
    
    ETPropertyDescription *documentTypeProperty = [ETPropertyDescription descriptionWithName: @"documentType"
                                                                                        type: (id)@"NSString"];
    [documentTypeProperty setPersistent: YES];
    
    ETPropertyDescription *documentNameProperty = [ETPropertyDescription descriptionWithName: @"documentName"
                                                                                        type: (id)@"NSString"];
    [documentNameProperty setPersistent: YES];
    
    ETPropertyDescription *rootObjectProperty = [ETPropertyDescription descriptionWithName: @"rootDocObject"
                                                                                      type: (id)@"NSObject"];
    [rootObjectProperty setPersistent: YES];
    [rootObjectProperty setOpposite: (id)@"DocumentItem.document"];
    
    ETPropertyDescription *tagsProperty = [ETPropertyDescription descriptionWithName: @"docTags"
                                                                                type: (id)@"Tag"];
    [tagsProperty setPersistent: YES];
    [tagsProperty setMultivalued: YES];
    
    
    [docEntity setPropertyDescriptions: A(projectProperty, screenRectProperty, isOpenProperty, documentTypeProperty, rootObjectProperty, documentNameProperty, tagsProperty)];
    
    return docEntity;
}

- (NSRect) screenRect
{
	return [[self valueForStorageKey: @"screenRect"] rectValue];
}
- (void) setScreenRect:(NSRect)r
{
    [self willChangeValueForProperty: @"screenRect"];
    [self setValue: [NSValue valueWithRect: r] forStorageKey: @"screenRect"];
	[self didChangeValueForProperty: @"screenRect"];
}

- (BOOL) isOpen
{
	return [[self valueForStorageKey: @"isOpen"] boolValue];
}
- (void) setIsOpen:(BOOL)i
{
	[self willChangeValueForProperty: @"isOpen"];
    [self setValue: @(i) forStorageKey: @"isOpen"];
	[self didChangeValueForProperty: @"isOpen"];
}

@dynamic project;
@dynamic documentType;
@dynamic rootDocObject;
@dynamic documentName;
@dynamic docTags;

- (void) addDocTagToDocument: (Tag *)tag
{
    [[self mutableSetValueForKey: @"docTags"] addObject: tag];
}
- (void) removeDocTagFromDocument: (Tag *)tag
{
    [[self mutableSetValueForKey: @"docTags"] removeObject: tag];}

@end
