NSObject subclass:  SmalltalkMessage [
	| message arguments |

	initWithMessage: msg arguements: args [
		message := msg.
		arguements := args
	]
]

NSObject subclass: SmalltalkMessagePart [
	| messagePart argument |
	initWithMessage: msgPart argument: args [
		messagePart := msgPart.
		arguement := args
	]

	getMessagePart [ ^messagePart ]
	getArgument [ ^arguement ]
]


SmalltalkAstGenerator subclass: PKParserAbstractGenerator [

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
                initWithMessage: (partList inject: '' into: [:acc :value | acc, value messagePart ])  
				 arguments: (partList select: [:each | each argument ])
	]
]
