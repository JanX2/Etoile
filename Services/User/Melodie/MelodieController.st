" This is the main class for Melodie. It coordinates CoreObject and EtoileUI,
  handles adding new songs to the library.

  Its only interaction with music playback is invoking
  'musicPlayerController playLayoutItem:start:' when a song is double-clicked. "
  
NSObject subclass: MelodieController
[
	| window search musicPlayerController knownExtensions
	  URLTextField addURLWindow smartGroup ctxt
	  mainContainer  playlistContainer
	  mainLayoutItemGroup playlistLayoutItemGroup
	  mainModel playlistModel |

	knownExtensions	[
		knownExtensions == nil ifTrue: [
			knownExtensions := NSMutableArray array.
			(ETUTI typeWithString: 'public.audio') allSubtypes
				foreach: [ :type | knownExtensions addObjectsFromArray: (type fileExtensions) ].
		].
		^ knownExtensions.
	]

	newContext [
		| defaults | 
		'Creating new object context' log.

		ctxt := COObjectContext alloc init.	
		COObjectContext setCurrentContext: ctxt.
	
		mainModel := ETPlaylist new.
		playlistModel := ETPlaylist new.

		'Registered objects: ' log.
		ctxt registeredObjects log.    

		defaults := NSUserDefaults standardUserDefaults.
		defaults setUUID: (ctxt UUID) forKey: 'MellodieObjectContextUUID'.
		defaults setUUID: (mainModel UUID) forKey: 'MellodieMainModelUUID'. 
		defaults setUUID: (playlistModel UUID) forKey: 'MellodiePlaylistModelUUID'. 
	]

	reloadModelVariablesFromContext [
		| defaults |
		
		defaults := NSUserDefaults standardUserDefaults.
		mainModel := ctxt objectForUUID: (defaults UUIDForKey: 'MellodieMainModelUUID').
		playlistModel := ctxt objectForUUID: (defaults UUIDForKey: 'MellodiePlaylistModelUUID').
	]

	loadContextWithUUID: uuid [
		'Requesting object context with UUID:' log.
		uuid log.

		ctxt := COObjectContext alloc initWithUUID: uuid.
		COObjectContext setCurrentContext: ctxt.
	
		self reloadModelVariablesFromContext.
			
		'Deserialized main model:' log.
		mainModel log.
		'Deserialized playlist model:' log.
		playlistModel log.
	]


	init [
		| uuid |
		'EtoileTunesController init' log.
		ETPlaylist setAutomaticallyMakeNewInstancesPersistent: true.
		ETMusicFile setAutomaticallyMakeNewInstancesPersistent: true.

		uuid := (NSUserDefaults standardUserDefaults UUIDForKey: 'MellodieObjectContextUUID').
		(uuid == nil) ifTrue: [ self newContext. ]
		             ifFalse: [ self loadContextWithUUID: uuid. ].
		
		ctxt setDelegate: self.

		^ self.
	]

	addFile: path [
		(self knownExtensions containsObject: (path pathExtension))
		    ifTrue: [ mainModel addMember: (ETMusicFile alloc initWithPath: path). ]
	]

	" The following two methods can be moved to blocks in addFiles: once Smalltalk supports
	  nested blocks accessing variables "

	addDirectory: path [
		(NSFileManager defaultManager enumeratorAtPath: path) allObjects foreach:
		    [ :file | self addFile: (path stringByAppendingPathComponent: file) ].
	]

	addPath: path [
		(NSFileManager defaultManager directoryExistsAtPath: path)
		    ifTrue: [ self addDirectory: path ]
		    ifFalse: [ self addFile: path ].
	]
	
	" Called when the user selects Add Files from the menu "
	addFiles: sender [
		| openPanel |

		openPanel := NSOpenPanel openPanel.
		openPanel setAllowsMultipleSelection: true.
		openPanel setCanChooseDirectories: true.
		openPanel runModalForTypes: (self knownExtensions).

		openPanel filenames foreach: [ :path | self addPath: path ].
		mainLayoutItemGroup reloadAndUpdateLayout.
	]

	undo: sender [
		ctxt undo.
	]

	redo: sender [	
		ctxt redo.
	]

	addURL: sender [
		| string URL |

		addURLWindow orderOut: self.
		string := URLTextField stringValue stringByAddingPercentEscapesUsingEncoding: @NSUTF8StringEncoding.
		URL := NSURL URLWithString: string.

		mainModel addMember: 
			((string hasSuffix: 'pls') ifTrue: [ ETPlaylist playlistForPLSFileAtURL: URL ]
			                          ifFalse: [ ETMusicFile alloc initWithURL: URL ]).

		mainLayoutItemGroup reloadAndUpdateLayout.
	]

	newPlaylist: sender [
		| newPlaylist |

		newPlaylist := ETPlaylist new.
		"Put a sample radio stream in the playlist."
		newPlaylist addMember:(ETMusicFile alloc initWithURL:
		    (NSURL URLWithString: 'http://scfire-chi0l-1.stream.aol.com/stream/1018')).
		playlistModel addMember: newPlaylist.
		playlistLayoutItemGroup reloadAndUpdateLayout.
	]

	awakeFromNib [
		| layout |

		'known extensions: ' log.
		self knownExtensions foreach: [ :ext | ext log ].

		layout := ETOutlineLayout layout.
	
		layout setDisplayName: 'Title' forProperty: 'kETTitleProperty';
			setDisplayName: 'Artist' forProperty: 'kETArtistProperty';
			setDisplayName: 'Album' forProperty: 'kETAlbumProperty';
			setDisplayName: 'URL' forProperty: 'kETURLProperty'.
	
		layout setDisplayedProperties:
		    {'icon'. 'kETTitleProperty'. 'kETArtistProperty'. 'kETAlbumProperty'. 'kETURLProperty' }.

		mainLayoutItemGroup := ETLayoutItem itemGroupWithRepresentedObject: mainModel.
		mainLayoutItemGroup setSource: mainLayoutItemGroup;
			setSupervisorView: mainContainer;
			setLayout: layout;
			reloadAndUpdateLayout.
		mainContainer setHasVerticalScroller: true;
			setTarget: self;
			setDoubleAction: 'doubleClickInContainer:'.

		playlistLayoutItemGroup := ETLayoutItem itemGroupWithRepresentedObject: playlistModel.
		playlistLayoutItemGroup setSource: playlistLayoutItemGroup;
			setSupervisorView: playlistContainer;
			setLayout: (ETOutlineLayout layout);
			reloadAndUpdateLayout.
		playlistContainer setHasVerticalScroller: false;
			setTarget: self;
			setDoubleAction: 'doubleClickInContainer:'.

		search setDelegate: self.

		ScriptCenter sharedInstance enableScriptingWithObjects:
		    (NSDictionary dictionaryWithObjects: { musicPlayerController  }
		                                forKeys: { 'MusicPlayerController' }).
	]

	" COObjectContext delegate method "
	objectContextDidMergeObjects: notif [
		'Merge occurred, reloading models from context and updating container layouts..' log.
		self reloadModelVariablesFromContext.
		mainLayoutItemGroup reloadAndUpdateLayout.
		playlistLayoutItemGroup reloadAndUpdateLayout.
	]

	controlTextDidChange: notif [
		smartGroup == nil ifTrue: [ self smartGroupOn. ].
		(search stringValue length = 0)
		    ifTrue: [ 
			mainLayoutItemGroup setRepresentedObject: mainModel.
		]  ifFalse: [
			mainLayoutItemGroup setRepresentedObject: smartGroup.
			smartGroup setPredicate:
			    (NSPredicate predicateWithFormat: '(%K CONTAINS[cd] %@) OR (%K CONTAINS[cd] %@)'
			        argumentArray: {'kETTitleProperty' . search stringValue . 'kETAlbumProperty' . search stringValue }).
		].
		mainLayoutItemGroup reloadAndUpdateLayout.
	]

	smartGroupOn [
		smartGroup := COSmartGroup alloc init.
		smartGroup setTarget: mainModel.
		mainLayoutItemGroup setRepresentedObject: smartGroup.
	]
	
	clearSearch: sender [
		search setStringValue: (NSString string). "change to ''"
		self controlTextDidChange: nil.
	]

	doubleClickInContainer: sender [
		musicPlayerController playLayoutItem: (sender doubleClickedItem) start: true.
	]
]
