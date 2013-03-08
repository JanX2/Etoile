SmalltalkCompiler extend [
	+dynamicDevSmalltalkCompiler
	[ | compiler |
		compiler := SmalltalkCompiler new.
		compiler transforms addObject: (DynamicIvarRewriter new).
		^compiler.
	]
]

NSObject subclass: MethodResolver
[
	| textView messageBox window class |
	initWithSkeleton: skel title: title
	[ | nib |
		super init.
		nib := NSNib alloc initWithNibNamed: 'MethodResolver' bundle: nil.
		nib instantiateNibWithOwner: self topLevelObjects: nil.
		window makeKeyAndOrderFront: self.
		textView textStorage replaceCharactersInRange: (NSValue rangeWithLocation: 0 length: 0)
		                                   withString: skel.
		messageBox setStringValue: title.
		NSApplication sharedApplication runModalForWindow: window.
		^self.
	]
	initWithObject: obj class: cls method: method
	[ | skel | 
		class := obj className.
		skel := class mutableCopy.
		skel appendString: ' extend [\n\t'.
		skel appendString: method.
		skel appendString: ' [\n\t\t\n\t]\n]'.
		^self initWithSkeleton: skel title: 'A message was sent with no corresponding method.  Please implement the method and continue.'.
	]
	initWithClass: className
	[ | skel |
		skel := 'NSObject subclass: ' mutableCopy.
		skel appendString: className.
		skel appendString: ' [\n\t\n]'.
		class := className.
		^self initWithSkeleton: skel title: 'A class that does not exist was referenced.  Please implement the class and continue.'
	]
	+resolveClass: className
	[
		self alloc initWithClass: className.
	]
	compile: sender
	[ | compiler source |
		compiler := SmalltalkCompiler dynamicDevSmalltalkCompiler.
		source := textView textStorage string.
		((compiler compileString: source) == nil) ifTrue: [
			'Failed to compile' log.
		] ifFalse: [
			| fn fm sourceFile |
			fm := NSFileManager defaultManager.
			fn := NSBundle mainBundle bundlePath.
			fn := fn stringByAppendingPathComponent: 'Resources'.
			fn := fn stringByAppendingPathComponent: class.
			fn := fn stringByAppendingPathExtension: 'st'.
			(fm fileExistsAtPath: fn) ifTrue: [
				sourceFile := NSMutableString stringWithContentsOfFile: fn.
				sourceFile appendString: '\n'.
				sourceFile appendString: source.
			] ifFalse: [
				sourceFile := source.
				DynamicDevelopment addFileToPlist: fn.
			].
			sourceFile writeToFile: fn atomically: true.
			window performClose: self.
		]
	]
	setTextView: tv [ textView := tv ]
	setWindow: w [ window := w ]
	abort: sender [ C abort: {}.  ]
]

NSObject subclass: RecurseChecker
[ | +recurse |
	+initialize
	[
		recurse := true
	]
	+ifNotRecursive: block
	[
		recurse ifTrue: [
			recurse := false.
			block value.
			recurse := true.
			^true.
		].
		^false.
	]
]

NSObject extend
[
	+resolveClassMethod: selector
	[
		^RecurseChecker ifNotRecursive: [
			MethodResolver alloc initWithObject: self class: self method: ('+' stringByAppendingString: (selector stringValue)).
		].
	]
	+resolveInstanceMethod: selector
	[
		^RecurseChecker ifNotRecursive: [
			MethodResolver alloc initWithObject: self class: (self class) method: selector stringValue.
		].
	]
]
ETClassMirror extend
[
	compare: other [ ^(self name) compare: (other name).  ]
]
ETInstanceVariableMirror extend
[
	compare: other [ ^(self name) compare: (other name).  ]
]

LKASTVisitor subclass: DynamicIvarRewriter
[ | currentClass |
	visitSubclass: cls [
		currentClass := cls classname.
		^cls.
	]
	visitCategoryDef: cls [
		currentClass := cls classname.
		^cls.
	]
	idForRuntimeIVar: iVar inClass: cls
	[ | id |
		[ ((cls == nil) == 0) ] whileTrue: [
			id := (DynamicDevelopment runtimeIvarsForClass: cls) member: iVar.
			(id == nil) ifFalse: [ ^id ].
			cls := C NSClassFromString: cls.
			cls := C class_getSuperclass: cls.
			cls := cls className.
		].
		^id.
	]
	visitAssignExpr: expr 
	[ | runtimeIvar |
		runtimeIvar := self idForRuntimeIVar: (expr target description) inClass: currentClass.
		runtimeIvar ifNotNil: [
			| newExpr args key |
			newExpr := LKFunctionCall new.
			newExpr setFunctionName: 'objc_setAssociatedObject'.
			args := NSMutableArray new.
			args addObject: (LKSelfRef new).
			key := runtimeIvar integerPointerValue stringValue.
			args addObject: (LKNumberLiteral literalFromString: key).
			args addObject: (expr expression).
			args addObject: (LKEnumReference alloc initWithValue: 'OBJC_ASSOCIATION_RETAIN_NONATOMIC' inEnumeration: nil).
			newExpr setArguments: args.
			^newExpr.
		].
		^expr.
	]
	visitDeclRef: expr
	[ | runtimeIvar |
		runtimeIvar := self idForRuntimeIVar: (expr description) inClass: currentClass.
		runtimeIvar ifNotNil: [
			| newExpr args key |
			newExpr := LKFunctionCall new.
			key := runtimeIvar integerPointerValue stringValue.
			newExpr setFunctionName: 'objc_getAssociatedObject'.
			args := NSMutableArray new.
			args addObject: (LKSelfRef builtin).
			args addObject: (LKNumberLiteral literalFromString: key).
			newExpr setArguments: args.
			^newExpr.
		].
		"
		ETTranscript show: 'Reference to '; show: expr; show: ' in class: '; show: currentClass; cr.
		ETTranscript show: 'Runtime ivar? '; show: (self idForRuntimeIVar: (expr description) inClass: currentClass); cr.
		"
		^expr.
	]
]

NSWindowController subclass: ClassBrowserController
[ | ivarWindow selectedClass classBrowser instanceBrowser codeEditor editedFile editedClass editedLocation |
	addString: string toMatrix: aMatrix isLeaf: leaf
	[ | cell |
		cell := NSBrowserCell new.
		cell setTitle: string.
		cell setLeaf: leaf.
		aMatrix addRowWithCells: (NSArray arrayWithObject: cell).
	]
	classBrowser: aBrowser createRowsForColumn: aColumn inMatrix: aMatrix
	[ | class className classMirror subclassMirrors path |
		(aColumn == 0) ifTrue: [
			subclassMirrors := ETReflection reflectAllRootClasses.
			subclassMirrors foreach: [ :cls |
				self addString: (cls name) toMatrix: aMatrix isLeaf: (((cls subclassMirrors) count) == 0).
			]
		] ifFalse: [
			path := aBrowser pathToColumn: (aColumn).
			className := path lastPathComponent.
			class := C NSClassFromString: className.
			classMirror := ETReflection reflectClass: class.
			subclassMirrors := classMirror subclassMirrors.
			subclassMirrors := subclassMirrors sortedArrayUsingSelector: #compare: .
			subclassMirrors foreach: [ :cls |
				self addString: (cls name) toMatrix: aMatrix isLeaf: (((cls subclassMirrors) count) == 0).
			]
		]
	]
	methodBrowser: aBrowser createRowsForColumn: aColumn inMatrix: aMatrix
	[
		
		(aColumn == 0) ifTrue: [
			self addString: 'Instance Variables' toMatrix: aMatrix isLeaf: false.
			self addString: 'Class Methods' toMatrix: aMatrix isLeaf: false.
			self addString: 'Instance Methods' toMatrix: aMatrix isLeaf: false.
		].
		(aColumn == 1) ifTrue: [
			| class mirrors option |
			option := (aBrowser pathToColumn: 1) lastPathComponent.
			class := C NSClassFromString: selectedClass.
			mirrors := ETReflection reflectClass: class.
			(option = 'Instance Variables') ifTrue: [
				| runtimeIvars |
				mirrors := mirrors instanceVariableMirrors.
				runtimeIvars := DynamicDevelopment runtimeIvarsForClass: selectedClass.
				runtimeIvars allObjects foreach: [ :ivar |
					self addString: ivar toMatrix: aMatrix isLeaf: true.
				]
			].
			(option = 'Instance Methods') ifTrue: [
				mirrors := mirrors methodMirrors mutableCopy.
				mirrors filterOut isClassMethod.
			].
			(option = 'Class Methods') ifTrue: [
				mirrors := mirrors methodMirrors mutableCopy.
				mirrors filter isClassMethod.
			].
			mirrors := mirrors sortedArrayUsingSelector: #compare: .
			mirrors foreach: [ :cls |
				self addString: (cls name) toMatrix: aMatrix isLeaf: true.
			]
		]
	]
	browser: aBrowser createRowsForColumn: aColumn inMatrix: aMatrix
	[
		(aBrowser tag == 0) ifTrue: [
			self classBrowser: aBrowser createRowsForColumn: aColumn inMatrix: aMatrix.
		] ifFalse: [
			self methodBrowser: aBrowser createRowsForColumn: aColumn inMatrix: aMatrix.
		]
	]
	selectClass: sender
	[
		selectedClass := sender path lastPathComponent .
		instanceBrowser setPath: ''.
	]
	addIMethod: sender
	[
		editedFile := nil.
		editedLocation := nil.
		editedClass := selectedClass.
		codeEditor textStorage replaceCharactersInRange: (NSValue rangeWithLocation: 0 length: (codeEditor textStorage length))
		                                     withString: 'newMethod\n[\n\t\n]'.
	]
	addCMethod: sender
	[
		editedFile := nil.
		editedLocation := nil.
		editedClass := selectedClass.
		codeEditor textStorage replaceCharactersInRange: (NSValue rangeWithLocation: 0 length: (codeEditor textStorage length))
		                                     withString: '+newMethod\n[\n\t\n]'.
	]
	addIvar: sender
	[ | loc file fileName range iVarName |
		loc := DynamicDevelopment locationForInstanceVariable: nil inClass: selectedClass.
		fileName := loc objectAtIndex: 0.
		range := loc objectAtIndex: 1.
		iVarName := ivarWindow stringValue.
		iVarName := (' ' stringByAppendingString: iVarName) stringByAppendingString: ' '.
		(range length == 0) ifTrue: [
			iVarName := (' |' stringByAppendingString: iVarName) stringByAppendingString: '| '.
		].
		range := NSValue rangeWithLocation: (range location) length: 0.
		file := NSMutableString stringWithContentsOfFile: fileName.
		file replaceCharactersInRange: range withString: iVarName.
		file writeToFile: fileName atomically: true.
		DynamicDevelopment addIvar: (ivarWindow stringValue) forClass: selectedClass.
		DynamicDevelopment reparseFile: fileName.
		instanceBrowser loadColumnZero.
		instanceBrowser setPath: ('Instance Variables' stringByAppendingPathComponent: (ivarWindow stringValue)).
	]
	addSubclass: sender
	[ | fm superClass |
		editedLocation := nil.
		editedClass := selectedClass.
		editedLocation := nil.
		superClass := selectedClass.
		(superClass == nil) ifTrue: [ superClass := 'NSObject' ].
		superClass := superClass mutableCopy.
		superClass appendString: ' subclass: <NewClass>\n[ | <ivars> |\n\t\n]'.
		codeEditor textStorage replaceCharactersInRange: (NSValue rangeWithLocation: 0 length: (codeEditor textStorage length))
		                                     withString: superClass.
	]
	runSelection: sender
	[ | stubMethod source range compiler ast |
		stubMethod := 'DynamicDevelopment extend [ +stub [ ' mutableCopy.
		range := codeEditor selectedRanges.
		(range count == 0) ifTrue: [ ^nil ].
		range := range objectAtIndex: 0.
		source := codeEditor textStorage string substringWithRange: range.
		stubMethod appendString: source.
		stubMethod appendString: ' ]]'.
		compiler := SmalltalkCompiler dynamicDevSmalltalkCompiler.
		ast := (compiler compileString: stubMethod).
		ast ifNotNil: [
			DynamicDevelopment stub.
		].
	]
	compile: sender
	[ | jitSource compiler sourceString ast path |
		sourceString := codeEditor textStorage string.
		(editedClass == nil) ifTrue: [
			jitSource := sourceString.
		] ifFalse: [
			" First generate a complete module source to JIT"
			jitSource := selectedClass mutableCopy.
			jitSource appendString: ' extend [ '.
			jitSource appendString: sourceString.
			jitSource appendString: ' ]'.
		].
		compiler := SmalltalkCompiler dynamicDevSmalltalkCompiler.
		" If we can correctly compile it, run it "
		ast := compiler compileString: jitSource.
		ast ifNotNil: [
			| sourceFile |
			(editedFile == nil) ifTrue: [
				| className classHierarchy classes insertPoint |
				classes := ast allClasses.
				(classes count > 0) ifTrue: [
					className := (classes objectAtIndex: 0) classname.
				] ifFalse: [
					classes := ast allCategories.
					(classes count > 0) ifTrue: [
						className := (classes objectAtIndex: 0) classname.
					] ifFalse: [
						className := 'Misc'.
					].
				].
				insertPoint := DynamicDevelopment insertionPointForClass: className.
				(insertPoint == nil) ifTrue: [
					editedFile := NSBundle mainBundle bundlePath.
					editedFile := editedFile stringByAppendingPathComponent: 'Resources'.
					editedFile := editedFile stringByAppendingPathComponent: className.
					editedFile := editedFile stringByAppendingPathExtension: 'st'.
					(NSFileManager defaultManager fileExistsAtPath: editedFile) ifTrue: [
						sourceFile := NSString stringWithContentsOfFile: editedFile.
						editedLocation := NSValue rangeWithLocation: (sourceFile length - 1)
															 length: 0.
					] ifFalse: [
						editedLocation := NSValue rangeWithLocation: 0 length: 0.
						sourceFile := ''.
						DynamicDevelopment addFileToPlist: editedFile.
					].
					(editedClass == nil) ifFalse: [
						sourceString := jitSource.
					].
				] ifFalse: [
					editedFile := insertPoint objectAtIndex: 0.
					editedLocation := insertPoint objectAtIndex: 1.
					sourceFile := NSString stringWithContentsOfFile: editedFile.
					sourceString := '\n' stringByAppendingString: (codeEditor textStorage string).
					sourceString := sourceString stringByAppendingString: '\n'.
				].
				classHierarchy := NSMutableArray new.
				[ (className == nil) not ] whileTrue: [
					classHierarchy insertObject: className atIndex: 0.
					className := C NSClassFromString: className.
					className := C class_getSuperclass: className.
					className := className className.
				].
				classBrowser setPath: (NSString pathWithComponents: classHierarchy).
			] ifFalse: [
				sourceFile := NSString stringWithContentsOfFile: editedFile.
			].
			sourceFile := sourceFile stringByReplacingCharactersInRange: editedLocation
			                                                 withString: sourceString.
			sourceFile writeToFile: editedFile atomically: true.
			DynamicDevelopment reparseFile: editedFile.
			editedLocation := NSValue rangeWithLocation: (editedLocation location) length: (sourceString length).
		].
		path := instanceBrowser path.
		instanceBrowser loadColumnZero.
		instanceBrowser setPath: path.
		path := classBrowser path.
		classBrowser loadColumnZero.
		classBrowser setPath: path.
		" FIXME: Present errors in a helpful way"
	]
	selectMethod: sender
	[ | path type name location file methodText textStorage |
		path := sender path pathComponents.
		type := path objectAtIndex: 1.
		name := path objectAtIndex: 2.
		textStorage := codeEditor textStorage.
		textStorage replaceCharactersInRange: (NSValue rangeWithLocation: 0 length: textStorage length)
		                          withString: ''.
		editedFile := nil.
		editedClass := nil.
		(name = '/') ifTrue: [ ^nil. ].
		(type = 'Instance Variables') ifTrue: [ ^nil ].
		(type = 'Instance Methods') ifTrue: [
			location := DynamicDevelopment locationForInstanceMethod: name inClass: selectedClass .
		].
		(type = 'Class Methods') ifTrue: [
			location := DynamicDevelopment locationForClassMethod: name inClass: selectedClass .
		].
		(location == nil) ifTrue: [ ^nil ].
		editedFile := location objectAtIndex: 0.
		editedLocation := location objectAtIndex: 1.
		methodText := NSString stringWithContentsOfFile: editedFile.
		methodText := methodText substringWithRange: editedLocation.
		textStorage replaceCharactersInRange: (NSValue rangeWithLocation: 0 length: textStorage length)
		                          withString: methodText.
		editedClass := selectedClass.
		^nil.
	]
	setInstanceBrowser: b [ instanceBrowser := b ]
	setClassBrowser: b [ classBrowser := b ]
	setCodeEditor: e [ codeEditor := e ]
	setIvarWindow: i [ ivarWindow := i ]
]

NSObject subclass: SourceFile
[ | file classes metaClasses ivars |
	description [ ^ classes description ]
	init
	[
		super init.
		classes := NSMutableDictionary new.
		metaClasses := NSMutableDictionary new.
		ivars := NSMutableDictionary new.
		^self.
	]
	addMethod: m location: l inClass: c
	[ | class methods |
		class := classes objectForKey: c.
		(nil == class) ifTrue: [
			class := NSMutableDictionary new.
			classes setObject: class forKey: c.
		].
		class setObject: l forKey: m.
	]
	addClassMethod: m location: l inClass: c
	[ | class methods |
		class := metaClasses objectForKey: c.
		(nil == class) ifTrue: [
			class := NSMutableDictionary new.
			metaClasses setObject: class forKey: c.
		].
		class setObject: l forKey: m.
	]
	locationForInstanceMethod: m inClass: c
	[
		^(classes objectForKey: c) objectForKey: m.
	]
	locationForClassMethod: m inClass: c
	[
		^(metaClasses objectForKey: c) objectForKey: m.
	]
	locationForInstanceVariable: v inClass: c
	[
		(v == nil) ifTrue: [
			^(ivars objectForKey: c) objectEnumerator nextObject.
		].
		^(ivars objectForKey: c) objectForKey: v.
	]
	insertionPointForClass: c
	[ | class range |
		class := classes objectForKey: c.
		(class == nil) ifTrue: [
			class := metaClasses objectForKey: c.
		].
		range := class objectEnumerator nextObject.
		range ifNotNil: [
			range := NSValue rangeWithLocation: (range location) length: 0.
		].
		^range.
	]
	findMethod: method
	[ | i sig ob cb com start len depth |
		"Character literals don't work with the lemon-based parser"
		ob := '[' characterAtIndex: 0.
		cb := ']' characterAtIndex: 0.
		com := '"' characterAtIndex: 0.
		len := file length.
		sig := method signature selector.
		start := sig sourceLocation location.
		(method isKindOfClass: (LKClassMethod)) ifTrue: [ start := start - 1. ].
		"Find the first brace."
		i := file rangeOfString: '[' options: 0 range: (NSValue rangeWithLocation: start length: (len - start)).
		i := i location + 1.
		depth := 1.
		" We really should have a whileFalse: on blocks..."
		[ (depth = 0) == 0 ] whileTrue: [
			| c |
			" Find the matching close brace  "
			c := file characterAtIndex: i.
			(c == ob) ifTrue: [ depth := depth + 1 ].
			(c == cb) ifTrue: [ depth := depth - 1 ].
			(c == com) ifTrue: [
				i := i + 1.
				i := file rangeOfString: '"' options: 0 range: (NSValue rangeWithLocation: i length: (len - i)).
				i := i location + 1.
			].
			i := i + 1.
		].
		^(NSValue rangeWithLocation: start length: (i - start))
	]
	addMethodsForClass: aClass
	[ | range |
		aClass methods foreach: [ :m |
			range := self findMethod: m.
			m isClassMethod ifTrue: [
				self addClassMethod: (m signature selector) location: range inClass: (aClass classname).
			] ifFalse: [
				self addMethod: (m signature selector) location: range inClass: (aClass classname).
			].
		].
	]
	addMethodsForCategory: aCategory
	[ | range |
		aCategory methods foreach: [ :m |
			range := self findMethod: m.
			m isClassMethod ifTrue: [
				self addClassMethod: (m signature selector) location: range inClass: (aCategory classname).
			] ifFalse: [
				self addMethod: (m signature selector) location: range inClass: (aCategory classname).
			]
		].
	]
	addIvarsForClass: aClass
	[ | class classname |
		classname := aClass classname.
		class := ivars objectForKey: classname.
		(nil == class) ifTrue: [
			class := NSMutableDictionary new.
			ivars setObject: class forKey: classname.
		].
		(aClass instanceVariables count > 0) ifTrue: [
			aClass instanceVariables foreach: [ :i |
				class setObject: (i sourceLocation)
				         forKey: i.
			]
		] ifFalse: [
			| classLoc end |
			classLoc := aClass classname sourceLocation.
			classLoc := classLoc location + classLoc length.
			end := file length - classLoc.
			classLoc := NSValue rangeWithLocation: classLoc length: end.
			classLoc := file rangeOfString: '[' options: 0 range: classLoc.
			classLoc := NSValue rangeWithLocation: (classLoc location + 1) length: 0.
			class setObject: classLoc
			         forKey: ''.
		].
	]
	collectClassesFromFile: fileName
	[ | mod parser |
		file := (NSString stringWithContentsOfFile: fileName).
		parser := SmalltalkParser new.
		mod := parser parseString: file.
		mod allClasses do: [ :c |
			self addMethodsForClass: c.
			self addIvarsForClass: c.
		].
		mod allCategories do: [ :c |
			self addMethodsForCategory: c
		].
		^self
	]
]

NSObject subclass: DynamicDevelopment
[ | +browser +runtimeIvars +codeFiles +sourceFiles |
	+start
	[
		sourceFiles := NSMutableDictionary new.
		LKCompiler addClassLoader: [ :className | MethodResolver resolveClass: className ].
		browser := (ClassBrowserController alloc initWithWindowNibName: 'ClassBrowser').
		browser window.
		runtimeIvars := NSMutableDictionary new.
		codeFiles := (NSBundle mainBundle pathsForResourcesOfType: 'st' inDirectory: nil).
		codeFiles foreach: [ :file |
			sourceFiles setObject: (
				(SourceFile new) collectClassesFromFile: file)
				forKey: file.
		].
	]
	+reparseFile: file
	[
		sourceFiles setObject: ((SourceFile new) collectClassesFromFile: file)
		               forKey: file.
	]
	+locationForClassMethod: m inClass: c
	[ | loc |
		sourceFiles allKeys foreach: [ :file |
			loc := (sourceFiles objectForKey: file) locationForClassMethod: m inClass: c.
			(loc == nil) ifFalse: [
				| array |
				array := NSMutableArray new.
				array addObject: file.
				array addObject: loc.
				^array.
			].
		].
		^nil.
	]
	+insertionPointForClass: c
	[ | loc |
		sourceFiles allKeys foreach: [ :file |
			loc := (sourceFiles objectForKey: file) insertionPointForClass: c.
			(loc == nil) ifFalse: [
				| array |
				array := NSMutableArray new.
				array addObject: file.
				array addObject: loc.
				^array.
			].
		].
		^nil.
	]
	+locationForInstanceMethod: m inClass: c
	[ | loc |
		sourceFiles allKeys foreach: [ :file |
			loc := (sourceFiles objectForKey: file) locationForInstanceMethod: m inClass: c.
			(loc == nil) ifFalse: [
				| array |
				"
				array := {file . loc}.
				^array.
				"
				array := NSMutableArray new.
				array addObject: file.
				array addObject: loc.
				^array.
			].
		].
		^nil.
	]
	+locationForInstanceVariable: v inClass: c
	[ | loc |
		sourceFiles allKeys foreach: [ :file |
			loc := (sourceFiles objectForKey: file) locationForInstanceVariable: v inClass: c.
			(loc == nil) ifFalse: [
				| array |
				array := NSMutableArray new.
				array addObject: file.
				array addObject: loc.
				^array.
			].
		].
		^nil.
	]
	+addIvar: anIvar forClass: aClass
	[ | ivars |
		ivars := runtimeIvars objectForKey: aClass.
		(ivars == nil) ifTrue: [
			ivars := NSMutableSet new.
			runtimeIvars setObject: ivars forKey: aClass.
		].
		ivars addObject: anIvar.
	]
	+runtimeIvarsForClass: aClass
	[
		^runtimeIvars objectForKey: aClass.
	]
	+addFileToPlist: fn
	[
		| plistPath plist sourceList |
		plistPath := NSBundle mainBundle pathForResource: 'LKInfo' ofType: 'plist'.
		plist := NSMutableDictionary dictionaryWithContentsOfFile: plistPath.
		sourceList := plist objectForKey: 'Sources'.
		plist setObject: (sourceList arrayByAddingObject: (fn lastPathComponent))
				 forKey: 'Sources'.
		plist writeToFile: plistPath atomically: true.
	]
	+stub []
]
