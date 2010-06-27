#!/bin/sh

echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN""http://www.w3.org/TR/REC-html40/loose.dtd">"
echo "<html>"
echo "<head>"
echo "<title>&Eacute;toil&eacute; API References</title>"
echo "</head>"
echo "<body>"

echo "<h1>&Eacute;toil&eacute; API References</h1>"

for file in *; do
	if [ -d $file ]; then

echo "<ul>"
echo "<li><a href=\"./${file}/index.html\">${file}</a></li>"
echo "</ul>"

	fi
done

echo "</body>"
echo "</html>"

