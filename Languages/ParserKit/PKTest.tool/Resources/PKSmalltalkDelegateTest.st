NSObject subclass:  SmalltalkMessage [
	| message arguments |

	initWithMessage: msg arguements: args [
		message := msg.
		arguments := args
	]
]

NSObject subclass: SmalltalkMessagePart [
	| messagePart argument |
	initWithMessage: msgPart argument: args [
		messagePart := msgPart.
		argument := args
	]

	getMessagePart [ ^messagePart ]
	getArgument [ ^argument ]
]

PKParserAbstractGenerator subclass: SmalltalkAstGenerator [

	makeUnaryMessage: msg [
		^SmalltalkMessage alloc initWithMessage: msg arguements: {}
	]

	makeBinaryMessage: msg argument: arg [
		^SmalltalkMessage alloc initWithMessage: msg arguements: { arg }
	]

	makeMessageKeywordPart: keywordPart arguement: identPart [
		^SmalltalkMessagePart alloc initWithMessage: keywordPart arguement: identPart
	]

	makrKeywordMessage: partList [
		^SmalltalkMessage alloc 
                initWithMessage: (partList inject: '' into: [:acc :value | acc, value getMessagePart ])  
				 arguments: (partList select: [:each | each getArgument ])
	]
]
