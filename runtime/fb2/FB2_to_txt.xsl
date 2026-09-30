<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns:fb="http://www.gribuser.ru/xml/fictionbook/2.0">

<xsl:param name="skipannotation" select="1"/>
<xsl:param name="new-track-at-section" select="1"/>
<xsl:param name="new-track-at-subsection" select="0"/>
<xsl:param name="notes-at-end" select="0"/>
<xsl:param name="wordwrap-length" select="65"/>
<xsl:param name="brstr" select="'&#010;'"/>
<xsl:param name="pointstr" select="'.'"/>
<xsl:param name="dblbr" select="0"/>
<xsl:param name="indent-str" select="''"/>
<xsl:param name="latin-from" select="'&#192;&#193;&#194;&#195;&#196;&#197;&#199;&#200;&#201;&#202;&#203;&#204;&#205;&#206;&#207;&#209;&#210;&#211;&#212;&#213;&#214;&#217;&#218;&#219;&#220;&#221;&#224;&#225;&#226;&#227;&#228;&#229;&#231;&#232;&#233;&#234;&#235;&#236;&#237;&#238;&#239;&#241;&#242;&#243;&#244;&#245;&#246;&#249;&#250;&#251;&#252;&#253;&#255;'"/>
<xsl:param name="latin-to" select="'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy'"/>

<xsl:strip-space elements="*"/>
<xsl:output method="text" encoding="utf-8"/>
<xsl:key name="note-link" match="fb:section|fb:p" use="@id"/>

<xsl:template match="*">
  <xsl:value-of select="fb:description/fb:title-info/fb:book-title"/>
  <xsl:value-of select="$pointstr"/>
  <xsl:call-template name="line-break"/>
  <xsl:for-each select="fb:description/fb:title-info/fb:author">
    <xsl:call-template name="author"/>
    <xsl:call-template name="line-break"/>
  </xsl:for-each>
  <xsl:call-template name="line-break"/>

  <xsl:if test="fb:description/fb:title-info/fb:sequence">
    <xsl:for-each select="fb:description/fb:title-info/fb:sequence">
      <xsl:call-template name="sequence"/>
      <xsl:value-of select="$pointstr"/>
    </xsl:for-each>
    <xsl:call-template name="line-break"/>
  </xsl:if>
  <xsl:if test="$skipannotation &lt; 1">
    <xsl:for-each select="fb:description/fb:title-info/fb:annotation">
      <xsl:call-template name="annotation"/>
      <xsl:call-template name="line-break"/>
    </xsl:for-each>
  </xsl:if>
  
  <!-- BUILD BOOK -->
  <xsl:for-each select="fb:body">
    <xsl:if test="position()!=1">
      <xsl:call-template name="line-break"/>
      <xsl:call-template name="line-break"/>
    </xsl:if>

    <xsl:if test="$notes-at-end &gt; 0 or not(@name = 'notes')">
      <xsl:if test="@name">
        <xsl:value-of select="@name"/>
        <xsl:call-template name="line-break"/>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:if>
  </xsl:for-each>
  <xsl:call-template name="line-break"/>
</xsl:template>

  
<xsl:template name="remove-char">
  <xsl:param name="char"/>
  <xsl:param name="text"/>
  <xsl:choose>
    <xsl:when test="contains($text, $char)">
      <xsl:value-of select="substring-before($text, $char)"/>
      <xsl:call-template name="remove-char">
        <xsl:with-param name="char" select="$char"/>
        <xsl:with-param name="text" select="substring-after($text, $char)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="text()">
  <xsl:param name="text0" select="translate(normalize-space( . ), '&#8209;', '-')"/>
  <xsl:param name="text1" select="translate($text0, $latin-from, $latin-to)"/>
  <xsl:variable name="text2" >
    <xsl:call-template name="remove-char">
      <xsl:with-param name="char" select="'&#769;'"/>
      <xsl:with-param name="text" select="$text1"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="wrap-string">
    <xsl:with-param name="str" select="$text2" />
    <xsl:with-param name="wrap-col" select="$wordwrap-length" />
    <xsl:with-param name="break-mark" select="$brstr" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="wrap-string">
  <xsl:param name="str" />
  <xsl:param name="wrap-col" />
  <xsl:param name="break-mark" />
  <xsl:param name="pos" select="0" />
  <xsl:param name="first-line" select="true()" />
  <xsl:value-of select="$str" />
  <!-- fails on very large paragraphs
  <xsl:choose>
    <xsl:when test="contains( $str, ' ' )">
      <xsl:variable name="before" select="substring-before( $str, ' ' )" />
      <xsl:variable name="pos-now" select="$pos + 1 + string-length( $before )" />

      <xsl:choose>
        <xsl:when test="$pos = 0 and $first-line">
          <xsl:value-of select="$before" />
          <xsl:call-template name="wrap-string">
            <xsl:with-param name="str" select="substring-after( $str, ' ' )" />
            <xsl:with-param name="wrap-col" select="$wrap-col" />
            <xsl:with-param name="break-mark" select="$break-mark" />
            <xsl:with-param name="pos" select="$pos-now" />
            <xsl:with-param name="first-line" select="$first-line" />
          </xsl:call-template>
        </xsl:when>

        <xsl:when test="$pos &gt;= $wrap-col and substring($before, 1, 1) != '&#8211;'">
          <xsl:value-of select="$break-mark" />
          <xsl:value-of select="$before" />
          <xsl:call-template name="wrap-string">
            <xsl:with-param name="str" select="substring-after( $str, ' ' )" />
            <xsl:with-param name="wrap-col" select="$wrap-col" />
            <xsl:with-param name="break-mark" select="$break-mark" />
            <xsl:with-param name="pos" select="string-length( $before )" />
            <xsl:with-param name="first-line" select="false()" />
          </xsl:call-template>
        </xsl:when>

        <xsl:otherwise>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$before" />
          <xsl:call-template name="wrap-string">
            <xsl:with-param name="str" select="substring-after( $str, ' ' )" />
            <xsl:with-param name="wrap-col" select="$wrap-col" />
            <xsl:with-param name="break-mark" select="$break-mark" />
            <xsl:with-param name="pos" select="$pos-now" />
            <xsl:with-param name="first-line" select="$first-line" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="$pos &gt; 0">
        <xsl:choose>
        <xsl:when test="$pos &gt;= $wrap-col">
          <xsl:value-of select="$break-mark" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:value-of select="$str" />
    </xsl:otherwise>
  </xsl:choose>
  -->
</xsl:template>

<!-- author template -->
<xsl:template name="author">
  <xsl:value-of select="fb:first-name"/>
  <xsl:text>&#032;</xsl:text>
  <xsl:if test="fb:middle-name and fb:middle-name!=''">
    <xsl:value-of select="fb:middle-name" />
    <xsl:text>&#032;</xsl:text>
  </xsl:if> 
<xsl:value-of select="fb:last-name"/>
<xsl:value-of select="$pointstr"/>
<xsl:call-template name="line-break"/>
</xsl:template>

<!-- secuence template -->
<xsl:template name="sequence">
  <xsl:value-of select="@name"/>
  <xsl:if test="@number">
    <xsl:text>&#032;#</xsl:text>
    <xsl:value-of select="@number"/>
  </xsl:if>
  <xsl:if test="fb:sequence">
    <xsl:for-each select="fb:sequence">
       <xsl:call-template name="sequence"/>
    </xsl:for-each>
  </xsl:if>
</xsl:template>

<!-- description -->
<xsl:template match="fb:description">
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<!-- body -->
<xsl:template match="fb:body">
  <xsl:call-template name="line-break"/>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="fb:section">
  <xsl:call-template name="line-break"/>
  <xsl:apply-templates select="./*"/>
</xsl:template>
	
	
<!-- section/title -->
<xsl:template match="fb:title">
  <xsl:call-template name="line-break"/>
  <xsl:call-template name="line-break"/>
  <xsl:if test="name(parent::node())='section' and not(parent::node()/parent::node()/@name='notes')">
    <xsl:if test="$new-track-at-section &gt; 0">
    <xsl:call-template name="new-track"/>
    </xsl:if>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:value-of select="$pointstr"/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<!-- subtitle -->
<xsl:template match="fb:subtitle">
  <xsl:call-template name="line-break"/>
  <xsl:if test="$new-track-at-subsection &gt; 0">
    <xsl:call-template name="new-track"/>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:value-of select="$pointstr"/>
  <xsl:call-template name="line-break"/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<xsl:template match="fb:table">
  <xsl:apply-templates/>
</xsl:template>
<xsl:template match="fb:tr">
  <xsl:call-template name="line-break"/>
  <xsl:text>===================================</xsl:text>
  <xsl:call-template name="line-break"/>
  <xsl:apply-templates/>
</xsl:template>
<xsl:template match="fb:td">
  <xsl:if test="position()=1">
    <xsl:text>| </xsl:text>
  </xsl:if>
  <xsl:apply-templates/>
  <xsl:text> | </xsl:text>
</xsl:template>

<!-- p -->
<xsl:template match="fb:p">
  <xsl:value-of select="$indent-str"/>
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
  <xsl:if test="$dblbr &gt; 0">
    <xsl:call-template name="line-break"/>
  </xsl:if>
</xsl:template>

<xsl:template match="fb:p" mode="note">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="fb:title" mode="note">
  <xsl:apply-templates mode="note"/>
  <xsl:text disable-output-escaping="yes"> - </xsl:text>
</xsl:template>


<!--<xsl:template match="fb:strong">*<xsl:apply-templates/>*</xsl:template>
<xsl:template match="fb:emphasis">/<xsl:apply-templates/>/</xsl:template>-->
<xsl:template match="fb:sup|fb:sub">^<xsl:apply-templates/>^</xsl:template>
<xsl:template match="fb:strikethrough">-<xsl:apply-templates/>-</xsl:template>
<xsl:template match="fb:emphasis|fb:strong"><xsl:apply-templates/></xsl:template>
<xsl:template match="fb:style"><xsl:apply-templates/></xsl:template>

<xsl:template match="fb:a">
  <xsl:choose>
    <xsl:when test="(@type) = 'note'">
      <xsl:choose>
        <xsl:when test="starts-with(@xlink:href,'#')">
          <xsl:for-each select="key('note-link',substring-after(@xlink:href,'#'))">[<xsl:apply-templates mode="note"/>]</xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="key('note-link',@xlink:href)">[<xsl:apply-templates mode="note"/>]</xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates/>
      <xsl:if test="not(starts-with(@xlink:href,'#'))">
         <xsl:apply-templates/>(<xsl:value-of select="@xlink:href"/>)
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="fb:empty-line">
  <xsl:call-template name="line-break"/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<!-- annotation -->
<xsl:template name="annotation">
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<!-- epigraph -->
<xsl:template match="fb:epigraph">
  <xsl:apply-templates/>
  <xsl:value-of select="$pointstr"/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<!-- cite -->
<xsl:template match="fb:cite">
  <xsl:call-template name="line-break"/>
  <xsl:call-template name="line-break"/>
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
</xsl:template>


<!-- cite/text-author -->
<xsl:template match="fb:text-author">
  <xsl:text>&#160;&#160;&#160;&#160;</xsl:text>
  <xsl:apply-templates/>
  <xsl:value-of select="$pointstr"/>
  <xsl:call-template name="line-break"/>
</xsl:template>
	<!-- date -->
<xsl:template match="fb:date">
  <xsl:text>&#160;&#160;&#160;&#160;</xsl:text>
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<xsl:template match="fb:poem">
  <xsl:apply-templates/>
</xsl:template>

	<!-- stanza -->
<xsl:template match="fb:stanza">
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
</xsl:template>
	<!-- v -->
<xsl:template match="fb:v">
  <xsl:text>	</xsl:text>
  <xsl:apply-templates/>
  <xsl:call-template name="line-break"/>
</xsl:template>

<xsl:template name="line-break">
  <xsl:value-of select="$brstr"/>
</xsl:template>

<xsl:template name="new-track">
  <xsl:text>@@bookmania:new-track;</xsl:text>
</xsl:template>

</xsl:stylesheet>
