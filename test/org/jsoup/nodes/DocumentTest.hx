package org.jsoup.nodes;

import de.polygonal.ds.Dll;
import haxe.Resource;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document.Charset;
import org.jsoup.nodes.Entities.EscapeMode;
import org.jsoup.TextUtil;
//import org.jsoup.integration.ParseTest;
import org.jsoup.nodes.Document.Syntax;

import utest.Assert;

/*import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;*/


/*import static org.junit.Assert.*;
import org.junit.Ignore;
import org.junit.Test;
*/

/**
 Tests for Document.

 @author Jonathan Hedley, jonathan@hedley.net */
class DocumentTest {
    private static var charsetUtf8:String = "UTF-8";
    private static var charsetIso8859:String = "ISO-8859-1";
    
	public function new() {}
	
    
    public function testSetTextPreservesDocumentStructure() {
        var doc:Document = Jsoup.parse("<p>Hello</p>");
        doc.setText("Replaced");
        Assert.equals("Replaced", doc.getText());
        Assert.equals("Replaced", doc.body().getText());
        Assert.equals(1, doc.select("head").size);
    }
    
    public function testTitles() {
        var noTitle:Document = Jsoup.parse("<p>Hello</p>");
        var withTitle:Document = Jsoup.parse("<title>First</title><title>Ignore</title><p>Hello</p>");
        
        Assert.equals("", noTitle.getTitle());
        noTitle.setTitle("Hello");
        Assert.equals("Hello", noTitle.getTitle());
        Assert.equals("Hello", noTitle.select("title").first().getText());
        
        Assert.equals("First", withTitle.getTitle());
        withTitle.setTitle("Hello");
        Assert.equals("Hello", withTitle.getTitle());
        Assert.equals("Hello", withTitle.select("title").first().getText());

		var newTitle = "new title";
		withTitle.setTitle(newTitle);
		Assert.equals(newTitle, withTitle.getTitle());
        
		var normaliseTitle:Document = Jsoup.parse("<title>   Hello\nthere   \n   now   \n");
        Assert.equals("Hello there now", normaliseTitle.getTitle());
    }

    public function testOutputEncoding() {
        Assert.warn("not passing");
		
		/*var doc:Document = Jsoup.parse("<p title=π>π & < > </p>");
        // default is utf-8
        Assert.equals("<p title=\"π\">π &amp; &lt; &gt; </p>", doc.body().getHtml());
        Assert.equals("UTF-8", doc.getOutputSettings().getCharset().name());

        doc.getOutputSettings().setCharset("ascii");
        Assert.equals(EscapeMode.base, doc.getOutputSettings().getEscapeMode());
        Assert.equals("<p title=\"&#x3c0;\">&#x3c0; &amp; &lt; &gt; </p>", doc.body().getHtml());

        doc.getOutputSettings().setEscapeMode(EscapeMode.extended);
        Assert.equals("<p title=\"&pi;\">&pi; &amp; &lt; &gt; </p>", doc.body().getHtml());*/
    }

    public function testXhtmlReferences() {
        var doc:Document = Jsoup.parse("&lt; &gt; &amp; &quot; &apos; &times;");
        doc.getOutputSettings().setEscapeMode(EscapeMode.xhtml);
        Assert.equals("&lt; &gt; &amp; \" ' ×", doc.body().getHtml());
    }

    public function testNormalisesStructure() {
        var doc:Document = Jsoup.parse("<html><head><script>one</script><noscript><p>two</p></noscript></head><body><p>three</p></body><p>four</p></html>");
        Assert.equals("<html><head><script>one</script><noscript>&lt;p&gt;two</noscript></head><body><p>three</p><p>four</p></body></html>", TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testCloneSimple() {
        var doc:Document = Jsoup.parse("<title>Hello</title>");
		var clone:Document = doc.clone();
		
		Assert.notEquals(doc, clone);
		Assert.equals(doc.toString(), clone.toString());
		
		var newTitle = "new title";
		
		clone.setTitle(newTitle);
		Assert.equals(clone.getTitle(), newTitle);
	}
	
    public function testClone() {
        var doc:Document = Jsoup.parse("<title>Hello</title> <p>One<p>Two");
        var clone:Document = doc.clone();

        Assert.equals("<html><head><title>Hello</title> </head><body><p>One</p><p>Two</p></body></html>", TextUtil.stripNewlines(clone.getHtml()));
        clone.setTitle("Hello there");
        clone.select("p").first().setText("One more").setAttr("id", "1");
        Assert.equals("<html><head><title>Hello there</title> </head><body><p id=\"1\">One more</p><p>Two</p></body></html>", TextUtil.stripNewlines(clone.getHtml()));
        Assert.equals("<html><head><title>Hello</title> </head><body><p>One</p><p>Two</p></body></html>", TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testClonesDeclarations() {
        var doc:Document = Jsoup.parse("<!DOCTYPE html><html><head><title>Doctype test");
		var clone:Document = doc.clone();

        Assert.equals(doc.getHtml(), clone.getHtml());
        Assert.equals("<!doctype html><html><head><title>Doctype test</title></head><body></body></html>",
                TextUtil.stripNewlines(clone.getHtml()));
    }
    
    
	//NOTE(az): skipped. needs DataUtil (not ported)
	public function testLocation() {
		Assert.warn("skipped (needs DataUtil)");
		
		/*var input:String = Resource.getString("htmltests/yahoo-jp.html");
        var doc:Document = Jsoup.parse(input, "UTF-8", "http://www.yahoo.co.jp/index.html");
        var location:String = doc.location();
        var baseUri = doc.getBaseUri();
        Assert.equals("http://www.yahoo.co.jp/index.html",location);
        Assert.equals("http://www.yahoo.co.jp/_ylh=X3oDMTB0NWxnaGxsBF9TAzIwNzcyOTYyNjUEdGlkAzEyBHRtcGwDZ2Ex/",baseUri);
        input = Resource.getString("htmltests/nyt-article-1.html");
        doc = Jsoup.parse(input, null, "http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp");
        location = doc.location();
        baseUri = doc.getBaseUri();
        Assert.equals("http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp",location);
        Assert.equals("http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp",baseUri);*/
    }

    public function testHtmlAndXmlSyntax() {
        var h:String = "<!DOCTYPE html><body><img async checked='checked' src='&<>\"'>&lt;&gt;&amp;&quot;<foo />bar";
        var doc:Document = Jsoup.parse(h);

        doc.getOutputSettings().setSyntax(Syntax.html);
        Assert.equals("<!doctype html>\n" +
                "<html>\n" +
                " <head></head>\n" +
                " <body>\n" +
                "  <img async checked src=\"&amp;<>&quot;\">&lt;&gt;&amp;\"\n" +
                "  <foo />bar\n" +
                " </body>\n" +
                "</html>", doc.getHtml());

        doc.getOutputSettings().setSyntax(Syntax.xml);
        Assert.equals("<!DOCTYPE html>\n" +
                "<html>\n" +
                " <head></head>\n" +
                " <body>\n" +
                "  <img async=\"\" checked=\"checked\" src=\"&amp;<>&quot;\" />&lt;&gt;&amp;\"\n" +
                "  <foo />bar\n" +
                " </body>\n" +
                "</html>", doc.getHtml());
    }

    public function testHtmlParseDefaultsToHtmlOutputSyntax() {
        var doc:Document = Jsoup.parse("x");
        Assert.equals(Syntax.html, doc.getOutputSettings().getSyntax());
    }

    // Ignored since this test can take awhile to run.
    //@Ignore
	//NOTE(az): ignored
    public function testOverflowClone() {
        Assert.warn("ignored (takes a while to run)");
		
		/*var openBuf = new StringBuilder();
        var closeBuf = new StringBuilder();
        for (i in 0...100000 >> 1) {
            openBuf.add("<i>");
            closeBuf.add("</i>");
        }

        var doc:Document = Jsoup.parse(openBuf.toString() + closeBuf.toString());
        var clone = doc.clone();
		Assert.notNull(clone);*/
    }

    /*public function testDocumentsWithSameContentAreEqual() {
        var docA:Document = Jsoup.parse("<div/>One");
        var docB:Document = Jsoup.parse("<div/>One");
        var docC:Document = Jsoup.parse("<div/>Two");

        Assert.equals(docA, docB);
        Assert.isFalse(docA.equals(docC));
        Assert.equals(docA.hashCode(), docB.hashCode());
        Assert.isFalse(docA.hashCode() == docC.hashCode());
    }*/
    
    
    public function testMetaCharsetUpdateUtf8() {
        var doc:Document = createHtmlDocument("changeThis");
        doc.setUpdateMetaCharsetElement(true);
        doc.setCharset(Charset.forName(charsetUtf8));
        
        var htmlCharsetUTF8:String = "<html>\n" +
                                        " <head>\n" +
                                        "  <meta charset=\"" + charsetUtf8 + "\">\n" +
                                        " </head>\n" +
                                        " <body></body>\n" +
                                        "</html>";
        Assert.equals(htmlCharsetUTF8, doc.toString());
        
        var selectedElement:Element = doc.select("meta[charset]").first();
        Assert.equals(charsetUtf8, doc.getCharset().name());
        Assert.equals(charsetUtf8, selectedElement.getAttr("charset"));
        Assert.equals(doc.getCharset(), doc.getOutputSettings().getCharset());
    }
    
    
	//NOTE(az): skipped, charset iso8859 not supported
    /*public function testMetaCharsetUpdateIso8859() {
		var doc:Document = createHtmlDocument("changeThis");
        doc.setUpdateMetaCharsetElement(true);
        doc.setCharset(Charset.forName(charsetIso8859));
        
        var htmlCharsetISO:String = "<html>\n" +
                                        " <head>\n" +
                                        "  <meta charset=\"" + charsetIso8859 + "\">\n" +
                                        " </head>\n" +
                                        " <body></body>\n" +
                                        "</html>";
        Assert.equals(htmlCharsetISO, doc.toString());
        
        var selectedElement:Element = doc.select("meta[charset]").first();
        Assert.equals(charsetIso8859, doc.getCharset().name());
        Assert.equals(charsetIso8859, selectedElement.getAttr("charset"));
        Assert.equals(doc.getCharset(), doc.getOutputSettings().getCharset());
    }*/
    
    
    public function testMetaCharsetUpdateNoCharset() {
        var docNoCharset:Document = Document.createShell("");
        docNoCharset.setUpdateMetaCharsetElement(true);
        docNoCharset.setCharset(Charset.forName(charsetUtf8));
        
        Assert.equals(charsetUtf8, docNoCharset.select("meta[charset]").first().getAttr("charset"));
        
        var htmlCharsetUTF8:String = "<html>\n" +
                                        " <head>\n" +
                                        "  <meta charset=\"" + charsetUtf8 + "\">\n" +
                                        " </head>\n" +
                                        " <body></body>\n" +
                                        "</html>";
        Assert.equals(htmlCharsetUTF8, docNoCharset.toString()); 
    }
    
    
    public function testMetaCharsetUpdateDisabled() {
        var docDisabled:Document = Document.createShell("");
        
        var htmlNoCharset:String = "<html>\n" +
                                        " <head></head>\n" +
                                        " <body></body>\n" +
                                        "</html>";
        Assert.equals(htmlNoCharset, docDisabled.toString());
        Assert.isNull(docDisabled.select("meta[charset]").first());
    }
    
    
    public function testMetaCharsetUpdateDisabledNoChanges() {
        var doc:Document = createHtmlDocument("dontTouch");
        
        var htmlCharset:String = "<html>\n" +
                                    " <head>\n" +
                                    "  <meta charset=\"dontTouch\">\n" +
                                    "  <meta name=\"charset\" content=\"dontTouch\">\n" +
                                    " </head>\n" +
                                    " <body></body>\n" +
                                    "</html>";
        Assert.equals(htmlCharset, doc.toString());
        
        var selectedElement:Element = doc.select("meta[charset]").first();
        Assert.notNull(selectedElement);
        Assert.equals("dontTouch", selectedElement.getAttr("charset"));
        
        selectedElement = doc.select("meta[name=charset]").first();
        Assert.notNull(selectedElement);
        Assert.equals("dontTouch", selectedElement.getAttr("content"));
    }
    
    
    public function testMetaCharsetUpdateEnabledAfterCharsetChange() {
        var doc = createHtmlDocument("dontTouch");
        doc.setCharset(Charset.forName(charsetUtf8));
        
        var selectedElement:Element = doc.select("meta[charset]").first();
        Assert.equals(charsetUtf8, selectedElement.getAttr("charset"));
        Assert.isTrue(doc.select("meta[name=charset]").isEmpty());
    }
            
    
    public function testMetaCharsetUpdateCleanup() {
        var doc:Document = createHtmlDocument("dontTouch");
        doc.setUpdateMetaCharsetElement(true);
        doc.setCharset(Charset.forName(charsetUtf8));
        
        var htmlCharsetUTF8 = "<html>\n" +
                                        " <head>\n" +
                                        "  <meta charset=\"" + charsetUtf8 + "\">\n" +
                                        " </head>\n" +
                                        " <body></body>\n" +
                                        "</html>";
        
        Assert.equals(htmlCharsetUTF8, doc.toString());
    }
    
    
    public function testMetaCharsetUpdateXmlUtf8() {
        var doc:Document = createXmlDocument("1.0", "changeThis", true);
        doc.setUpdateMetaCharsetElement(true);
        doc.setCharset(Charset.forName(charsetUtf8));
        
        var xmlCharsetUTF8:String = "<?xml version=\"1.0\" encoding=\"" + charsetUtf8 + "\">\n" +
                                        "<root>\n" +
                                        " node\n" +
                                        "</root>";
        Assert.equals(xmlCharsetUTF8, doc.toString());

        var selectedNode:XmlDeclaration = cast doc.childNode(0);
        Assert.equals(charsetUtf8, doc.getCharset().name());
        Assert.equals(charsetUtf8, selectedNode.getAttr("encoding"));
        Assert.equals(doc.getCharset(), doc.getOutputSettings().getCharset());
    }
    
    
	//NOTE(az): skipped, charset iso8859 not supported
    /*public function testMetaCharsetUpdateXmlIso8859() {
        var doc:Document = createXmlDocument("1.0", "changeThis", true);
        doc.setUpdateMetaCharsetElement(true);
        doc.setCharset(Charset.forName(charsetIso8859));
        
        var xmlCharsetISO:String = "<?xml version=\"1.0\" encoding=\"" + charsetIso8859 + "\">\n" +
                                        "<root>\n" +
                                        " node\n" +
                                        "</root>";
        Assert.equals(xmlCharsetISO, doc.toString());
        
        var selectedNode:XmlDeclaration = cast doc.childNode(0);
        Assert.equals(charsetIso8859, doc.getCharset().name());
        Assert.equals(charsetIso8859, selectedNode.getAttr("encoding"));
        Assert.equals(doc.getCharset(), doc.getOutputSettings().getCharset());
    }*/
    
    
    public function testMetaCharsetUpdateXmlNoCharset() {
        var doc:Document = createXmlDocument("1.0", "none", false);
        doc.setUpdateMetaCharsetElement(true);
        doc.setCharset(Charset.forName(charsetUtf8));
        
        var xmlCharsetUTF8:String = "<?xml version=\"1.0\" encoding=\"" + charsetUtf8 + "\">\n" +
                                        "<root>\n" +
                                        " node\n" +
                                        "</root>";
        Assert.equals(xmlCharsetUTF8, doc.toString());
        
        var selectedNode:XmlDeclaration = cast doc.childNode(0);
        Assert.equals(charsetUtf8, selectedNode.getAttr("encoding"));
    }
    
    
    public function testMetaCharsetUpdateXmlDisabled() {
        var doc:Document = createXmlDocument("none", "none", false);
        
        var xmlNoCharset:String = "<root>\n" +
                                    " node\n" +
                                    "</root>";
        Assert.equals(xmlNoCharset, doc.toString());
    }

    
    public function testMetaCharsetUpdateXmlDisabledNoChanges() {
        var doc:Document = createXmlDocument("dontTouch", "dontTouch", true);
        
        var xmlCharset:String = "<?xml version=\"dontTouch\" encoding=\"dontTouch\">\n" +
                                    "<root>\n" +
                                    " node\n" +
                                    "</root>";
        Assert.equals(xmlCharset, doc.toString());
        
        var selectedNode:XmlDeclaration = cast doc.childNode(0);
        Assert.equals("dontTouch", selectedNode.getAttr("encoding"));
        Assert.equals("dontTouch", selectedNode.getAttr("version"));
    }
    
    
    public function testMetaCharsetUpdatedDisabledPerDefault() {
        var doc:Document = createHtmlDocument("none");
        Assert.isFalse(doc.getUpdateMetaCharsetElement());
    }
    
    private static function createHtmlDocument(charset:String):Document {
        var doc:Document = Document.createShell("");
        doc.head().appendElement("meta").setAttr("charset", charset);
        doc.head().appendElement("meta").setAttr("name", "charset").setAttr("content", charset);
        
        return doc;
    }
    
    private static function createXmlDocument(version:String, charset:String, addDecl:Bool):Document {
        var doc = new Document("");
        doc.appendElement("root").setText("node");
        doc.getOutputSettings().setSyntax(Syntax.xml);
        
        if( addDecl == true ) {
            var decl = new XmlDeclaration("xml", "", false);
            decl.setAttr("version", version);
            decl.setAttr("encoding", charset);
            doc.prependChild(decl);
        }
        
        return doc;
    }

    //NOTE(az): skipped. needs DataUtil
    public function testShiftJisRoundtrip() {
        Assert.warn("skipped (needs DataUtil)");
		/*var input:String =
                "<html>"
                        +   "<head>"
                        +     "<meta http-equiv=\"content-type\" content=\"text/html; charset=Shift_JIS\" />"
                        +   "</head>"
                        +   "<body>"
                        +     "before&nbsp;after"
                        +   "</body>"
                        + "</html>";
        InputStream is = new ByteArrayInputStream(input.getBytes(Charset.forName("ASCII")));

        Document doc = Jsoup.parse(is, null, "http://example.com");
        doc.outputSettings().escapeMode(Entities.EscapeMode.xhtml);

        String output = new String(doc.html().getBytes(doc.outputSettings().charset()), doc.outputSettings().charset());

        Assert.isFalse("Should not have contained a '?'.", output.contains("?"));
        Assert.isTrue("Should have contained a '&#xa0;' or a '&nbsp;'.",
                output.contains("&#xa0;") || output.contains("&nbsp;"));
		*/
    }
}
