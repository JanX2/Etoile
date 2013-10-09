"
  PKInputStream maintains the position into the stream being parsed, the
  corresponding environment and memoized matches.
  
  Subclassing note: Input stream subclasses that want to parse something other
  than strings need to override -substreamWithRange:, -emptyStream and
  potentially -length.
"
NSObject subclass: PKInputStream [
    | memo stream position positionStack environmentStack |

    initWithStream: input [
		super init.
		stream := input.
		memo := NSMutableDictionary new.
		positionStack := NSMutableArray new.
		position := 0.
		environmentStack := PKEnvironmentStack new.
		self
	]

	description [
		^(self substreamWithRange: (NSValue rangeWithLocation: position length: (self length) - position)), ' pos: ', positionStack description
	]

	inEnvironmentDo: aBlock [
		environmentStack pushEnvironment.
		aBlock value.
		environmentStack popEnvironment.
	]

	bind: name object: anObject [
		environmentStack setValue: anObject forKey: name

	]

	bind: name action: anAction match: match [
		environmentStack setAction: anAction forKey: name fromMatch: match.
	]

	environment [^environmentStack ]

    addMatch: parserMatch at: position named: aString [
		| matchList |
		((memo objectForKey: position) == nil)
			 ifTrue: [memo setValue: NSMutableDictionary new forKey: position].
		matchList := memo objectForKey: position.
		matchList setValue: parserMatch forKey: aString
	]

	matchRule: string [
		^self matchAt: position rule: string
	]

	matchAt: position rule: aString [
		| matchList |
		matchList := memo objectForKey: position.
		^(matchList == nil)
            ifTrue: [nil]
			ifFalse: [matchList objectForKey: aString]
	]

	pushPosition: anInt [
		positionStack addObject: position.
		position := anInt
	]

	lastPosition [
		^positionStack lastObject
	]

	popPosition [
		position := positionStack lastObject.
		positionStack removeLastObject.
	]

	fromRange: range [
		^(range length == 0) ifTrue: [self emptyStream]
			ifFalse: [
				self substreamWithRange: range]
	]

	head [
		^self head: 1
	]
	
	head: size [
		"Todo non local return seems broken"
		^(position + size) > self length ifTrue: [self emptyStream]
			ifFalse: [self fromRange: (NSValue rangeWithLocation: position length: size)]
	]

	mergePosition [
		positionStack count >= 2 ifFalse: [NSException raise: 'PKParser' format: 'Not enought position to merge'].
		positionStack removeLastObject
	]

	position [^position]
	positionStack [^positionStack]
	length [ ^stream length]
	atEnd [^self position = self length]
	
	stream [ ^stream ]

	substreamWithRange: range [
		^stream substringWithRange: range
	]

	emptyStream [ ^'']
]

