<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:atom="http://www.w3.org/2005/Atom">
	<xsl:template name="AtomDate">
		<xsl:param name="DateStamp" />
		<xsl:variable name="year">
			<xsl:value-of select="substring($DateStamp,1,4)" />
		</xsl:variable>
		<xsl:variable name="month">
			<xsl:value-of select="substring($DateStamp,6,2)" />
		</xsl:variable>
		<xsl:variable name="day">
			<xsl:value-of select="substring($DateStamp,9,2)" />
		</xsl:variable>
		<xsl:variable name="hour">
			<xsl:value-of select="substring($DateStamp,12,2)" />
		</xsl:variable>
		<xsl:variable name="minute">
			<xsl:value-of select="substring($DateStamp,15,2)" />
		</xsl:variable>
		<xsl:variable name="second">
			<xsl:value-of select="substring($DateStamp,18,2)" />
		</xsl:variable>
		<xsl:value-of select="$year" />-<xsl:value-of select="$month" />-<xsl:value-of select="$day" />
		at
		<xsl:value-of select="$hour" />:<xsl:value-of select="$minute" />
		UTC
		<!--:<xsl:value-of select="$second" /> -->
	</xsl:template>

	<xsl:template match="/">
		<xsl:text disable-output-escaping="yes">
				<![CDATA[
				<!DOCTYPE html 
			     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
				 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">]]></xsl:text>

		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title><xsl:value-of select="atom:feed/atom:title"/></title>
				<style type="text/css">
					div.mublog {
						width : 80%;
						margin-left : auto;
						margin-right : auto
					}
					div.entry {
						background-color : #f0f0ff;
						border : thin solid #80808f;
						margin : 2pt;
						padding : 3pt;
						-moz-background-gradient: vertical #ffffff #8080ff
						-moz-border-radius: 5px;
						-webkit-border-radius: 5px
					}
					span.date {
					font-style : italic ;
					font-size : xx-small ;
					}
					div.title {
						text-align : right
						}
					p.summary
					{
					margin : 4pt
					}

				</style>
				<xsl:if test="atom:feed/atom:link[@rel='self']">
					<link rel="alternate" type="application/atom+xml" title="Atom feed">
						<xsl:attribute name="href">
							<xsl:value-of select="atom:feed/atom:link[@rel='self']/@href" />
						</xsl:attribute>
					</link>
				</xsl:if>
			</head>
			<body>
				<h1><xsl:value-of select="atom:feed/atom:title"/></h1>
				<xsl:if test="atom:feed/atom:subtitle">
					<p>
						<xsl:value-of select="atom:feed/atom:subtitle" disable-output-escaping="yes" />
					</p>
				</xsl:if>
				<xsl:if test="atom:feed/atom:link[@rel='self']">
					<p>You can subscribe to this microblog using the <a>
						<xsl:attribute name="href">
							<xsl:value-of select="atom:feed/atom:link[@rel='self']/@href" />
						</xsl:attribute>
						atom feed</a>
					</p>
				</xsl:if>
				<xsl:if test="atom:feed/atom:updated">
					<p>Last updated: 
						<xsl:call-template name="AtomDate">
							<xsl:with-param name="DateStamp" select="atom:feed/atom:updated"/>
						</xsl:call-template>
					</p>
				</xsl:if>
				<div class="mublog">
				<xsl:for-each select="atom:feed/atom:entry">
					<xsl:sort select="atom:updated" order="descending" />
					<xsl:if test="position() &lt; 10">
						<div class="entry">
						<p class="summary">
							<xsl:value-of select="atom:summary" disable-output-escaping="yes" />
						</p>
						<div class="title">
							<span class="date">
								<xsl:call-template name="AtomDate">
									<xsl:with-param name="DateStamp" select="atom:updated"/>
								</xsl:call-template>
							</span>
							<!--
							<xsl:text> </xsl:text>
							<span class="title">
								<xsl:value-of select="atom:title"/>
							</span>
							-->
						</div>
					</div>
					</xsl:if>
				</xsl:for-each>
				</div>
				<p>
					<a href="http://validator.w3.org/check?uri=referer"><img
						src="http://www.w3.org/Icons/valid-xhtml10"
						alt="Valid XHTML 1.0 Strict" height="31" width="88" /></a>
				</p>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
