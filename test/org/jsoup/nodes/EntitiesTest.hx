package org.jsoup.nodes;

//import org.jsoup.Jsoup;
import org.jsoup.nodes.Document.OutputSettings;
import org.jsoup.nodes.Entities.EscapeMode.*;
import unifill.CodePoint;

import utest.Assert;


class EntitiesTest {
    static public function testEscape() {
        var text = "Hello &<> Å å π 新 there ¾ © »";
        var escapedAscii = Entities.escape(text, new OutputSettings().setCharset("ascii").setEscapeMode(base));
        var escapedAsciiFull = Entities.escape(text, new OutputSettings().setCharset("ascii").setEscapeMode(extended));
        var escapedAsciiXhtml = Entities.escape(text, new OutputSettings().setCharset("ascii").setEscapeMode(xhtml));
        var escapedUtfFull = Entities.escape(text, new OutputSettings().setCharset("UTF-8").setEscapeMode(extended));
        var escapedUtfMin = Entities.escape(text, new OutputSettings().setCharset("UTF-8").setEscapeMode(xhtml));

        Assert.equals("Hello &amp;&lt;&gt; &Aring; &aring; &#x3c0; &#x65b0; there &frac34; &copy; &raquo;", escapedAscii);
        Assert.equals("Hello &amp;&lt;&gt; &angst; &aring; &pi; &#x65b0; there &frac34; &copy; &raquo;", escapedAsciiFull);
        Assert.equals("Hello &amp;&lt;&gt; &#xc5; &#xe5; &#x3c0; &#x65b0; there &#xbe; &#xa9; &#xbb;", escapedAsciiXhtml);
        Assert.equals("Hello &amp;&lt;&gt; Å å π 新 there ¾ © »", escapedUtfFull);
        Assert.equals("Hello &amp;&lt;&gt; Å å π 新 there ¾ © »", escapedUtfMin);
        // odd that it's defined as aring in base but angst in full

        // round trip
        Assert.equals(text, Entities.unescape(escapedAscii));
        Assert.equals(text, Entities.unescape(escapedAsciiFull));
        Assert.equals(text, Entities.unescape(escapedAsciiXhtml));
        Assert.equals(text, Entities.unescape(escapedUtfFull));
        Assert.equals(text, Entities.unescape(escapedUtfMin));
    }

    static public function testEscapeSupplementaryCharacter(){
        var text = CodePoint.fromInt(135361).toString();
        var escapedAscii = Entities.escape(text, new OutputSettings().setCharset("ascii").setEscapeMode(base));
        Assert.equals("&#x210c1;", escapedAscii);
        var escapedUtf = Entities.escape(text, new OutputSettings().setCharset("UTF-8").setEscapeMode(base));
        Assert.equals(text, escapedUtf);
    }

    static public function testUnescape() {
        var text = "Hello &amp;&LT&gt; &reg &angst; &angst &#960; &#960 &#x65B0; there &! &frac34; &copy; &COPY;";
        Assert.equals("Hello &<> ® Å &angst π π 新 there &! ¾ © ©", Entities.unescape(text));

        Assert.equals("&0987654321; &unknown", Entities.unescape("&0987654321; &unknown"));
    }

    static public function testStrictUnescape() { // for attributes, enforce strict unescaping (must look like &#xxx; , not just &#xxx)
        var text = "Hello &amp= &amp;";
        Assert.equals("Hello &amp= &", Entities.unescape(text, true));
        Assert.equals("Hello &= &", Entities.unescape(text));
        Assert.equals("Hello &= &", Entities.unescape(text, false));
    }

    
    static public function testCaseSensitive() {
        var unescaped = "Ü ü & &";
        Assert.equals("&Uuml; &uuml; &amp; &amp;",
                Entities.escape(unescaped, new OutputSettings().setCharset("ascii").setEscapeMode(extended)));
        
        var escaped = "&Uuml; &uuml; &amp; &AMP";
        Assert.equals("Ü ü & &", Entities.unescape(escaped));
    }
    
    static public function testQuoteReplacements() {
        var escaped = "&#92; &#36;";
        var unescaped = "\\ $";
        
        Assert.equals(unescaped, Entities.unescape(escaped));
    }

    static public function testLetterDigitEntities() {
        var html = "<p>&sup1;&sup2;&sup3;&frac14;&frac12;&frac34;</p>";
        var doc:Document = Jsoup.parse(html);
        doc.outputSettings().charset("ascii");
        var p:Element = doc.select("p").first();
        Assert.equals("&sup1;&sup2;&sup3;&frac14;&frac12;&frac34;", p.html());
        Assert.equals("¹²³¼½¾", p.text());
        doc.outputSettings().charset("UTF-8");
        Assert.equals("¹²³¼½¾", p.html());
    }

    static public function testNoSpuriousDecodes() {
        var string = "http://www.foo.com?a=1&num_rooms=1&children=0&int=VA&b=2";
        Assert.equals(string, Entities.unescape(string));
    }

    static public function testEscapesGtInXmlAttributesButNotInHtml() {
        // https://github.com/jhy/jsoup/issues/528 - < is OK in HTML attribute values, but not in XML


        var docHtml = "<a title='<p>One</p>'>One</a>";
        var doc:Document = Jsoup.parse(docHtml);
        var element:Element = doc.select("a").first();

        doc.outputSettings().escapeMode(base);
        Assert.equals("<a title=\"<p>One</p>\">One</a>", element.outerHtml());

        doc.outputSettings().escapeMode(xhtml);
        Assert.equals("<a title=\"&lt;p>One&lt;/p>\">One</a>", element.outerHtml());
    }
}
