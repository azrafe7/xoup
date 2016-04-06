package org.jsoup.parser;

import org.jsoup.Jsoup;
import org.jsoup.TextUtil;
import org.jsoup.helper.StringUtil;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;

import org.jsoup.integration.ParseTest;

import utest.Assert;

/*
import org.junit.Ignore;
import org.junit.Test;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.util.List;

import static org.jsoup.nodes.Document.OutputSettings.Syntax;
import static org.junit.Assert.*;
*/

/**
 * Tests XmlTreeBuilder.
 *
 * @author Jonathan Hedley
 */
class XmlTreeBuilderTest {

    public function new() { }
	
	public function testSimpleXmlParse() {
        var xml = "<doc id=2 href='/bar'>Foo <br /><link>One</link><link>Two</link></doc>";
        var tb = new XmlTreeBuilder();
        var doc = tb.parse(xml, "http://foo.com/");
        Assert.equals("<doc id=\"2\" href=\"/bar\">Foo <br /><link>One</link><link>Two</link></doc>",
                TextUtil.stripNewlines(doc.getHtml()));
        Assert.equals(doc.getElementById("2").absUrl("href"), "http://foo.com/bar");
    }
    
    public function testPopToClose() {
        // test: </val> closes Two, </bar> ignored
        var xml = "<doc><val>One<val>Two</val></bar>Three</doc>";
        var tb = new XmlTreeBuilder();
        var doc = tb.parse(xml, "http://foo.com/");
        Assert.equals("<doc><val>One<val>Two</val>Three</val></doc>",
                TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testCommentAndDocType() {
        var xml = "<!DOCTYPE html><!-- a comment -->One <qux />Two";
        var tb = new XmlTreeBuilder();
        var doc = tb.parse(xml, "http://foo.com/");
        Assert.equals("<!DOCTYPE html><!-- a comment -->One <qux />Two",
                TextUtil.stripNewlines(doc.getHtml()));
    }
	
    public function testSupplyParserToJsoupClass() {
        var xml = "<doc><val>One<val>Two</val></bar>Three</doc>";
        var doc = Jsoup.parse(xml, "http://foo.com/", Parser.xmlParser());
        Assert.equals("<doc><val>One<val>Two</val>Three</val></doc>",
                TextUtil.stripNewlines(doc.getHtml()));
    }
    
	/*@Ignore*/
    public function testSupplyParserToConnection() {
		Assert.warn("ignored (requires connection)");
        /*var xmlUrl = "http://direct.infohound.net/tools/jsoup-xml-test.xml";

        // parse with both xml and html parser, ensure different
        var xmldoc = Jsoup.connect(xmlUrl).parser(Parser.xmlParser()).get();
        Document htmlDoc = Jsoup.connect(xmlUrl).parser(Parser.htmlParser()).get();
        Document autoXmlDoc = Jsoup.connect(xmlUrl).get(); // check connection auto detects xml, uses xml parser

        Assert.equals("<doc><val>One<val>Two</val>Three</val></doc>",
                TextUtil.stripNewlines(xmlDoc.getHtml()));
        assertFalse(htmlDoc.equals(xmlDoc));
        Assert.equals(xmlDoc, autoXmlDoc);
        Assert.equals(1, htmlDoc.select("head").size()); // html parser normalises
        Assert.equals(0, xmlDoc.select("head").size()); // xml parser does not
        Assert.equals(0, autoXmlDoc.select("head").size()); // xml parser does not*/
    }
    
    public function testSupplyParserToDataStream() {
        var resource = ParseTest.getFile("htmltests/xml-test.xml");
        var doc = Jsoup.parse(resource, /*null,*/ "http://foo.com", Parser.xmlParser());
        Assert.equals("<doc><val>One<val>Two</val>Three</val></doc>",
                TextUtil.stripNewlines(doc.getHtml()));
    }
    
    public function testDoesNotForceSelfClosingKnownTags() {
        // html will force "<br>one</br>" to logically "<br />One<br />". XML should be stay "<br>one</br> -- don't recognise tag.
        var htmlDoc = Jsoup.parse("<br>one</br>");
        Assert.equals("<br>one\n<br>", htmlDoc.body().getHtml());

        var xmlDoc = Jsoup.parse("<br>one</br>", "", Parser.xmlParser());
        Assert.equals("<br>one</br>", xmlDoc.getHtml());
    }

    public function testHandlesXmlDeclarationAsDeclaration() {
        var html = "<?xml encoding='UTF-8' ?><body>One</body><!-- comment -->";
        var doc = Jsoup.parse(html, "", Parser.xmlParser());
        Assert.equals("<?xml encoding='UTF-8' ?> <body> One </body> <!-- comment -->",
                StringUtil.normaliseWhitespace(doc.outerHtml()));
        Assert.equals("#declaration", doc.childNode(0).nodeName());
        Assert.equals("#comment", doc.childNode(2).nodeName());
    }

    public function testXmlFragment() {
        var xml = "<one src='/foo/' />Two<three><four /></three>";
        var nodes = Parser.parseXmlFragment(xml, "http://example.com/");
        Assert.equals(3, nodes.size);

        Assert.equals("http://example.com/foo/", nodes.get(0).absUrl("src"));
        Assert.equals("one", nodes.get(0).nodeName());
		
		var tn:TextNode = cast nodes.get(1);
        Assert.equals("Two", tn.getText());
    }

    public function testXmlParseDefaultsToHtmlOutputSyntax() {
        var doc = Jsoup.parse("x", "", Parser.xmlParser());
        Assert.equals(Syntax.xml, doc.getOutputSettings().getSyntax());
    }

    public function testDoesHandleEOFInTag() {
        var html = "<img src=asdf onerror=\"alert(1)\" x=";
        var xmlDoc = Jsoup.parse(html, "", Parser.xmlParser());
        Assert.equals("<img src=\"asdf\" onerror=\"alert(1)\" x=\"\" />", xmlDoc.getHtml());
    }
}
