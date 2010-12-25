#!/bin/sh

rm ./TestFiles/GSDoc/*
autogsdoc -Project DocGenerator -DocumentationDirectory ./TestFiles/GSDoc -GenerateHtml YES  -GenerateParagraphMarkup YES -DTDs /Library/DTDs *.h *.m
