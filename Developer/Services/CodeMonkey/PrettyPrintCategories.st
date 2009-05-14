
NSFont extend [
	italic [
		| fm |
		fm := NSFontManager sharedFontManager.
		^ fm convertFont: self toHaveTrait: @NSItalicFontMask.
	]
]

LKAST extend [
    prettyprint [
	| writer |
	writer := PrettyPrintWriter new.
	self prettyprintToWriter: writer.
	^ writer value
    ]
    
    prettyprintToWriter: writer [
	"The default implementation: A lispy coloured output that
	also prints the AST node's class name."
	"writer append: '('."
	"writer blue: [ writer append: self className; append: ' '. ]."
	"writer red: [ writer append: self description. ]."
	writer append: self description.
	"writer append: ')'."
    ]
]

LKToken extend [
    prettyprintToWriter: writer [
	writer append: self.
    ]
]

LKReturn extend [
    prettyprintToWriter: writer [
	writer append: '^'.
	writer append: ret description.
    ]
]

LKIfStatement extend [
    prettyprintToWriter: writer [
	condition prettyprintToWriter: writer.
    ]
]

LKComment extend [
    prettyprintToWriter: writer [
	writer commentToken: self description.
    ]
]

LKModule extend [
    prettyprintToWriter: writer [
	classes do: [ :class |
	    class prettyprintToWriter: writer.
	].
	categories do: [ :category |
	    category prettyprintToWriter: writer.
	].
    ]
]

LKCompare extend [
    prettyprintToWriter: writer [
	lhs prettyprintToWriter: writer.
	writer append: ' = '.
	rhs prettyprintToWriter: writer.
    ]
]

LKCategoryDef extend [
    prettyprintToWriter: writer [
        writer append: classname; append: ' extend ['; cr.
        writer indent: [
	        methods do: [ :method |
                method prettyprintToWriter: writer.
	        ].
        ].
        writer append: ']'; cr.
    ]
]

LKSubclass extend [
    prettyprintToWriter: writer [
        writer append: superclass; append: ' subclass: ';
               append: classname; append: ' ['; cr.
	    
	    writer indent: [
	        (ivars count > 0) ifTrue: [
                writer append: '| '.
                ivars do: [ :ivar |
                    writer append: ivar; append: ' '.
                ].
                writer append: '|'; cr; cr.
	        ].
	        
            methods do: [ :method |
                method prettyprintFromClassToWriter: writer.
            ].
        ].
    
    writer append: ']'; cr.
    ]
]

LKMethod extend [
    prettyprintFromClassToWriter: writer [
	((self class) = (LKClassMethod class)) ifTrue: [
		writer append: '+'
	].
        signature prettyprintToWriter: writer.
        writer append: ' ['; cr.
	writer indent: [
		self prettyprintToWriter: writer.
	].
	writer append: ']'; cr.
    ]

    prettyprintToWriter: writer [
	"Print local variables"
	(symbols locals count > 0) ifTrue: [
	    writer localVariableToken: '| '.
	    symbols locals do: [ :symbol |
		writer localVariableToken: symbol; append: ' '.
	    ].
	    writer localVariableToken: '|'; cr.
	].
	"Print statements"
	statements do: [ :stmt |
	    stmt prettyprintToWriter: writer.
	    (stmt isKindOfClass: (LKComment class)) ifTrue: [
		writer cr.
	    ] ifFalse: [
		writer append: '.'; cr.
	    ]
	].
    ]
]

LKMessageSend extend [
    xxprettyprintToWriter: writer [
	| sel |
	target prettyprintToWriter: writer.
	writer append: ' '.
	sel = selector componentsSeparatedByString: ':'.
	(sel count == 1) ifTrue: [
		writer red: selector.
	] ifFalse: [
		writer red: (sel objectAtIndex: 0).
	].
	(arguments count > 0) ifTrue: [
		writer red: ' '.
		(arguments objectAtIndex: 0) prettyprintToWriter: writer.
	].
	1 to: ((arguments count) - 1) do: [:i|
		(i < (sel count)) ifTrue: [
			writer append: ' '.
			writer red: (sel objectAtIndex: i).
		].
		writer red: ' '.
		(arguments objectAtIndex: i) prettyprintToWriter: writer.
	]
    ]
]

LKMessageCascade extend [
	prettyprintToWriter: writer [
		receiver prettyprintToWriter: writer.
		(messages objectAtIndex: 0) prettyprintToWriter: writer.
		writer append: ';'.
		writer indent: [
			1 to: ((messages count) - 1) do: [ :i |
				writer cr.
				(messages objectAtIndex: i) prettyprintToWriter: writer.
				i < ((messages count) - 1) ifTrue: [
					writer append: ';'.
				].
			].
		].
	]
]

LKAssignExpr extend [
    prettyprintToWriter: writer [
	target prettyprintToWriter: writer.
	writer append: ' := '.
	expr prettyprintToWriter: writer.
    ]
]

LKStringLiteral extend [
    prettyprintToWriter: writer [
        writer stringToken: self description.
    ]
]

LKDeclRef extend [
    prettyprintToWriter: writer [
	 ((symbols scopeOfSymbol: symbol) > 4) ifTrue: [
		"ivar and cvar"
		writer bold: self description.
	] ifFalse: [
	 	((symbols scopeOfSymbol: symbol) = 4) ifTrue: [
			writer localVariableToken: self description.
		] ifFalse: [
			writer append: self description.
		]
	].
    ]
]

LKBlockExpr extend [
    prettyprintToWriter: writer [
	writer append: '['; cr.
	writer indent: [
		statements do: [ :stmt |
			stmt prettyprintToWriter: writer.
			writer append: '.'; cr.
		].
	].
	writer append: ']'.
    ]
]

