<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" indent="yes"/>

<xsl:template match="/log">
  <html>
    <head>
      <title>Commits with SKIP_SANITY_CHECK</title>
    </head>
    <body>
      <h1>Commits with SKIP_SANITY_CHECK</h1>
      <p>Commits done between
	<xsl:value-of select="logentry[1]/date"/>
	-
	<xsl:value-of select="logentry[last()]/date"/>
      </p>
      <hr/>
      <xsl:for-each select="logentry">
	<xsl:if test="contains(msg, 'SKIP_SANITY_CHECK')">
	  <pre>
	    <xsl:value-of select="msg"/>
	  </pre>
	  <a>
	    <xsl:attribute name="href">
	      <xsl:text>http://svn.arrisi.com/commits_by_num.php?repo=dev&amp;rev=</xsl:text>
	      <xsl:value-of select="@revision"/>
	    </xsl:attribute>
	    <xsl:text>r</xsl:text><xsl:value-of select="@revision"/>
	  </a>
	  <xsl:text> (author: </xsl:text>
	  <xsl:value-of select="author"/>
	  <xsl:text>)</xsl:text>	    
	  <br/>
	  <hr/>
	</xsl:if>
      </xsl:for-each>
      <p>XML log file processing completed.</p>
    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
