function log(message) {
	if(!log.window_ || log.window_.closed) {
		var win = window.open("", null, "width=400,height=200," +
	                   			"scrollbars=yes,resizable=yes,status=no," +
	                   			"location=no,menubar=no,toolbar=no");
		if (!win) return;
		var doc = win.document;
		doc.write("<html><head><title>Debug Log</title></head>" +
		       		"<body></body></html>");
		doc.close();
		log.window_ = win;
	}
	var logLine = log.window_.document.createElement("div");
	logLine.appendChild(log.window_.document.createTextNode(message));
	log.window_.document.body.appendChild(logLine);
}


function getElementsByClass(searchClass,node,tag) {
  var classElements = new Array();
  if (node == null)
    node = document;
  if (tag == null)
    tag = '*';
  var els = node.getElementsByTagName(tag);
  var elsLen = els.length;
  var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
  for (i = 0, j = 0; i < elsLen; i++) {
    if (pattern.test(els[i].className) ) {
      classElements[j] = els[i];
      j++;
    }
  }
  return classElements;
}


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
	//obj.style.color = '#000';
	
	var returnTypes = getElementsByClass('returnType', obj, 'span');
	for(var i = 0; i < returnTypes.length; i++) {
		returnTypes[i].style.display = 'none';
	}
	
	var parameters = getElementsByClass('parameter', obj, 'span');
	for(var i = 0; i < parameters.length; i++) {
		parameters[i].style.display = 'none';
	}
}

function show(obj) {
	var sibling = (obj.nextSibling.nodeType == 3) ? obj.nextSibling.nextSibling : obj.nextSibling;
	sibling.style.display = 'block';
	//obj.style.color = '#375dc7';
	
	var returnTypes = getElementsByClass('returnType', obj, 'span');
	for(var i = 0; i < returnTypes.length; i++) {
		returnTypes[i].style.display = 'inline';
	}
	
	var parameters = getElementsByClass('parameter', obj, 'span');
	for(var i = 0; i < parameters.length; i++) {
		parameters[i].style.display = 'inline';
	}
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
	
	var returnTypes = document.getElementsByClass('returnType', document, 'span');
	for(var i = 0; i < returnTypes.length; i++) {
		returnTypes[i].style.display = 'inline';
	}
	
	var parameters = document.getElementsByClass('parameter', document, 'span');
	for(var i = 0; i < parameters.length; i++) {
		parameters[i].style.display = 'inline';
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
	
	var returnTypes = document.getElementsByClass('returnType', document, 'span');
	for(var i = 0; i < returnTypes.length; i++) {
		returnTypes[i].style.display = 'none';
	}
	
	var parameters = document.getElementsByClass('parameter', document, 'span');
	for(var i = 0; i < parameters.length; i++) {
		parameters[i].style.display = 'none';
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