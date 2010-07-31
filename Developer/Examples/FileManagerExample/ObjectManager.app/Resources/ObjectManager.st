CODirectory extend
[
	+fsRoot
	[
		^ self objectWithURL: (NSURL fileURLWithPath: '/').
	]
]

NSObject subclass: ObjectManager
[
	run 
	[ | app |

		app := ETApplication sharedApplication.
		NSBundle loadNibNamed: 'MainMenu' owner: app.
		app run.
	]
]

ETController subclass: ObjectManagerMainController
[
	dateFormatter
	[
		^ NSDateFormatter alloc initWithDateFormat: '%1m %B %Y %H:%M' allowNaturalLanguage: true.
	]

	visit: sender
	[
		('visit ', (sender description)) log.
		sender setRepresentedObject: (sender doubleClickedItem representedObject).
		sender reloadAndUpdateLayout.
	]

	awakeFromNib
	[ | itemFactory managerItem controller |
		
		itemFactory := ETUIItemFactory factory.
	
		managerItem := itemFactory itemGroupWithRepresentedObject: CODirectory fsRoot.
		managerItem setSource: managerItem; 
			setFrame: (NSValue rectWithX: 300 Y: 150 width: 500 height: 400);
			setDoubleAction: 'visit:';
			setTarget: self;
			setController: ETController new;
			setHasVerticalScroller: true;
			setLayout: ETOutlineLayout layout.

		managerItem layout setDisplayedProperties: { 'icon'. 'displayName'. 'kCOModificationDateProperty'. 'kCOSizeProperty' };	
			setEditable: true forProperty: 'displayName';
			setDisplayName: 'Modification Date' forProperty: 'kCOModificationDateProperty';
			setFormatter: self dateFormatter forProperty: 'kCOModificationDate';
			setDisplayName: 'Size' forProperty: 'kCOSizeProperty';
			setFormatter: ETByteSizeFormatter new forProperty: 'kCOSizeProperty'.

		managerItem setShouldMutateRepresentedObject: true.
		managerItem controller setAllowedPickTypes: { ETUTI typeWithClass: (COFile class) }.
		managerItem controller setAllowedDropTypes: { ETUTI typeWithClass: (COFile class) } 
		                             forTargetType: (ETUTI typeWithClass: (CODirectory class)).

		managerItem reloadAndUpdateLayout.
		itemFactory windowGroup setController: self.
		self setTemplateItemGroup: managerItem.
		self addNewGroup: nil.
	]
]
