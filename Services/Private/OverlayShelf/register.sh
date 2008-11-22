#!/bin/sh
defaults write Corner CornerScript "CornerDelegate extend [\
	enterBottomLeft [\
		 'opening shelf' log.\
		Tell application: 'OverlayShelf' to: [ :dict | (dict valueForKey: 'Shelf') show. ].\
	]\
	enterTopLeft [\
		Tell application: 'OverlayShelf' to: [ :dict | (dict valueForKey: 'Shelf') hide. ].\
	]\
        enterTopRight [\
                Tell application: 'OverlayShelf' to: [ :dict | (dict valueForKey: 'Shelf') hide. ].\
        ]\
        enterBottomRight [\
                Tell application: 'OverlayShelf' to: [ :dict | (dict valueForKey: 'Shelf') hide. ].\
        ]\
]"
