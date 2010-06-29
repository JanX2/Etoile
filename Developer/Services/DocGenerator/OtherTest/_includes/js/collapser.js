function toggle(obj) {
	// Moz. or IE
	var sibling = (obj.nextSibling.nodeType == 3) ? obj.nextSibling.nextSibling : obj.nextSibling;
	// hide or show
	if(sibling.style.display == '' || sibling.style.display == 'block') {
		hide(obj);
	}
	else {
		show(obj);
	}
}

function hide(obj) {
	var sibling = (obj.nextSibling.nodeType == 3) ? obj.nextSibling.nextSibling : obj.nextSibling;
	sibling.style.display = 'none';
	obj.style.color = '#000';
}

function show(obj) {
	var sibling = (obj.nextSibling.nodeType == 3) ? obj.nextSibling.nextSibling : obj.nextSibling;
	sibling.style.display = 'block';
	obj.style.color = '#375dc7';
}

function showAll() {
	var dls = document.getElementsByTagName('dl');
	document.getElementById('shower').style.display = 'none';
	document.getElementById('hider').style.display = 'block';
	for(var i = 0; i < dls.length; i++) {
		var oDT = dls[i].getElementsByTagName('dt');
		for (var j = 0; j < oDT.length; j++) {
			oDT[j].onclick = function() {
							toggle(this);
						};
		  oDT[j].style.cursor = 'pointer';
		  show(oDT[j]);
		}
		oDT = null;
	}
}

function hideAll() {
	var dls = document.getElementsByTagName('dl');
	document.getElementById('shower').style.display = 'block';
	document.getElementById('hider').style.display = 'none';
	for(var i = 0; i < dls.length; i++) {
		var oDT = dls[i].getElementsByTagName('dt');
		for (var j = 0; j < oDT.length; j++) {
			oDT[j].onclick = function() {
							toggle(this);
						};
		  oDT[j].style.cursor = 'pointer';
		  hide(oDT[j]);
		}
		oDT = null;
	}
}

function readMore() {
	document.getElementById('overview-rest').style.display = 'inline';
	document.getElementById('more').style.display = 'none';
}

function readLess() {
	document.getElementById('overview-rest').style.display = 'none';
	document.getElementById('more').style.display = 'inline';	
}
