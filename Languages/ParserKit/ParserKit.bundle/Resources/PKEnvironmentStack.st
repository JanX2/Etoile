

"The environment stack maintains a scoped list of all bound variables in an 
 OMeta parse tree."
NSObject subclass: PKEnvironmentStack [
	| environmentStack top |
	init [
		environmentStack := NSMutableArray new.
		top := NSMutableDictionary new.
		top setValue: NSMutableDictionary new
		      forKey: '$_matches'.
		^self
	]

	setValue: val forKey: key [
		top setValue: val forKey: key.
	]

	setObject: obj forKey: key [
		self setValue: obj forKey: key.
	]

	setAction: action forKey: key fromMatch: match [
		self setValue: action forKey: key.
		self registerMatch: match forKey: key.
	]

	registerMatch: match forKey: name [
		(top objectForKey: '$_matches') setValue: match forKey: name.
	]
	objectForKey: key [
		| object |
		object := top objectForKey: key.
		^(object == nil) ifTrue: [ self searchStackFor: key ]
		                ifFalse: [ object ]	
	]

	searchStackFor: key [
		| object |
		object := nil.
		" The stack top is at index 0, so we can just iterate over the array to
		  return the most locally scoped binding first. "
		environmentStack do: [ :each |
			(nil == object) ifTrue: [
				object := each objectForKey: key.
			]
		].
		^object
	]


	" This method replaces the value of a binding in place. This is needed for
	  predicates that reduce their arguments during parsing. "
	replaceObject: newObject forKey: key [
		| oldObject |
		oldObject := top objectForKey: key.
		((oldObject == nil) not) ifTrue: [top setObject: newObject forKey: key]
		                     ifFalse: [
			environmentStack do: [ :each |
				(nil == oldObject) ifTrue: [
					oldObject := each objectForKey: key.
					(nil == oldObject) ifFalse: [each setObject: newObject
					                                     forKey: key].
				]
			]
		]
	]

	pushEnvironment [
		environmentStack insertObject: top atIndex: 0.
		top := NSMutableDictionary new.
		top setValue: NSMutableDictionary new
		      forKey: '$_matches'.
	]

	popEnvironment [
		self restoreActions.
		top := environmentStack objectAtIndex: 0.
		environmentStack removeObjectAtIndex: 0.
	]

	" It is necessary to restore actions for memoized matches "
	restoreActions [
		| matches |
		matches := top objectForKey: '$_matches'.
		matches allKeys do: [ :each |
			|match action |
			match := matches objectForKey: each.
			action := top objectForKey: each.
			"Only perform the restore if there is no new action that has overriden this one"
			(match matchAction == nil) ifTrue: [
				match attachAction: action
			] ifFalse: [
				"But we also reattach the action if the new one is only implicit "
				match matchAction isExplicitAction ifFalse: [ match attachAction: action ].
			].	
		].
	]

	description [ ^'Env stack: ', environmentStack description, ' top: ', top description]
]

