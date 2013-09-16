"
============================================================================

 The delayed action array records a number of delayed invocations so that they
 can be executed after parsing was successful.

============================================================================
"
NSObject subclass: PKDelayActionArray [
	| anArray |

	init [
		super init.
		anArray := NSMutableArray new.
	]

	addObject: anObject [
		anArray addObject: anObject
	]

	addAction: anObject [
		(anObject isArray and: (anObject == nil) not)
			ifTrue: [anObject do: [:each | self addObject: each]]
			ifFalse: [self addObject: anObject].
		^self
	]

	isArray [^true]

	do: aBlock [
		anArray do: aBlock
	]

	isExplicitAction [ ^true ]

	canReduce [^true]
	reduceOn: target [
		| result implicit |
		" Find out whether the array only contains implicit actions. In
		  this case, we want to rejoin them. "
		implicit := anArray leftFoldWithInitialValue: true
		                                   intoBlock: [ :acc :each | acc and: (each isExplicitAction not) ].
		result := anArray map: [:each | 
			each canReduce 
                   ifTrue: [each reduceOn: target]
				   ifFalse: [each]].
		(1 = result count) ifTrue: [ result := result objectAtIndex: 0]
			ifFalse: [
				implicit ifTrue: [
				" FIXME: Define generic protocol so that this
				  works for something other than strings. "
					result := result componentsJoinedByString: '']
			].
		
		^result.
	]

	description [
		^anArray leftFoldWithInitialValue: 'Delay:'
		                        intoBlock: [ :acc :action |
			'Delay:' = acc ifTrue: [acc, ' ', action description]
		                   ifFalse: [acc, ', ', action description]
		]           	
	]
]

