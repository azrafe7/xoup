package org.jsoup.parser;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Attribute;
import org.jsoup.nodes.Attributes;
import org.jsoup.nodes.BooleanAttribute;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import utest.Assert;

/*
import org.junit.Test;

import java.util.List;

import static org.junit.Assert.*;
*/

/**
 Test suite for attribute parser.

 @author Jonathan Hedley, jonathan@hedley.net */
class AttributeParseTest {

	public function new() { }
	
    public function testParsesRoughAttributeString() {
        var html = "<a id=\"123\" class=\"baz = 'bar'\" style = 'border: 2px'qux zim foo = 12 mux=18 />";
        // should be: <id=123>, <class=baz = 'bar'>, <qux=>, <zim=>, <foo=12>, <mux.=18>

        var el = Jsoup.parse(html).getElementsByTag("a").get(0);
        var attr:Attributes = el.getAttributes();
        Assert.equals(7, attr.size);
        Assert.equals("123", attr.get("id"));
        Assert.equals("baz = 'bar'", attr.get("class"));
        Assert.equals("border: 2px", attr.get("style"));
        Assert.equals("", attr.get("qux"));
        Assert.equals("", attr.get("zim"));
        Assert.equals("12", attr.get("foo"));
        Assert.equals("18", attr.get("mux"));
    }

    public function testHandlesNewLinesAndReturns() {
        var html = "<a\r\nfoo='bar\r\nqux'\r\nbar\r\n=\r\ntwo>One</a>";
        var el = Jsoup.parse(html).select("a").first();
        Assert.equals(2, el.getAttributes().size);
        Assert.equals("bar\r\nqux", el.getAttr("foo")); // currently preserves newlines in quoted attributes. todo confirm if should.
        Assert.equals("two", el.getAttr("bar"));
    }

    public function testParsesEmptyString() {
        var html = "<a />";
        var el = Jsoup.parse(html).getElementsByTag("a").get(0);
        var attr = el.getAttributes();
        Assert.equals(0, attr.size);
    }

    public function testCanStartWithEq() {
        var html = "<a =empty />";
        var el = Jsoup.parse(html).getElementsByTag("a").get(0);
        var attr = el.getAttributes();
        Assert.equals(1, attr.size);
        Assert.isTrue(attr.hasKey("=empty"));
        Assert.equals("", attr.get("=empty"));
    }

    public function testStrictAttributeUnescapes() {
        var html = "<a id=1 href='?foo=bar&mid&lt=true'>One</a> <a id=2 href='?foo=bar&lt;qux&lg=1'>Two</a>";
        var els = Jsoup.parse(html).select("a");
        Assert.equals("?foo=bar&mid&lt=true", els.first().getAttr("href"));
        Assert.equals("?foo=bar<qux&lg=1", els.last().getAttr("href"));
    }

    public function testMoreAttributeUnescapes() {
        var html = "<a href='&wr_id=123&mid-size=true&ok=&wr'>Check</a>";
        var els = Jsoup.parse(html).select("a");
        Assert.equals("&wr_id=123&mid-size=true&ok=&wr", els.first().getAttr("href"));
    }
    
    public function testParsesBooleanAttributes() {
        var html = "<a normal=\"123\" boolean empty=\"\"></a>";
        var el = Jsoup.parse(html).select("a").first();
        
        Assert.equals("123", el.getAttr("normal"));
        Assert.equals("", el.getAttr("boolean"));
        Assert.equals("", el.getAttr("empty"));
        
        var attributes:List<Attribute> = el.getAttributes().asList();
        Assert.equals(3, attributes.size, "There should be 3 attribute present");
        
        // Assuming the list order always follows the parsed html
		Assert.isFalse(Std.is(attributes.get(0), BooleanAttribute), "'normal' attribute should not be boolean");
		Assert.isTrue(Std.is(attributes.get(1), BooleanAttribute), "'boolean' attribute should be boolean");
		Assert.isFalse(Std.is(attributes.get(2), BooleanAttribute), "'empty' attribute should not be boolean");
        
        Assert.equals(html, el.outerHtml());
    }
    
}
