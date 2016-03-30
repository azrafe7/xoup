package org.jsoup.nodes;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import org.jsoup.helper.StringBuilder;
import org.jsoup.Jsoup;
import org.jsoup.TextUtil;
import org.jsoup.parser.Tag;
import org.jsoup.select.NodeVisitor;

import utest.Assert;

/*import java.util.List;
import org.junit.Test;

import static org.junit.Assert.*;
*/

/**
 Tests Nodes

 @author Jonathan Hedley, jonathan@hedley.net */
class NodeTest {
	
	public function new() {}
	
    public function testHandlesBaseUri() {
        var tag = Tag.valueOf("a");
        var attribs = new Attributes();
        attribs.put("relHref", "/foo");
        attribs.put("absHref", "http://bar/qux");

        var noBase = new Element(tag, "", attribs);
        Assert.equals("", noBase.absUrl("relHref")); // with no base, should NOT fallback to href attrib, whatever it is
        Assert.equals("http://bar/qux", noBase.absUrl("absHref")); // no base but valid attrib, return attrib

        var withBase = new Element(tag, "http://foo/", attribs);
        Assert.equals("http://foo/foo", withBase.absUrl("relHref")); // construct abs from base + rel
        Assert.equals("http://bar/qux", withBase.absUrl("absHref")); // href is abs, so returns that
        Assert.equals("", withBase.absUrl("noval"));

        var dodgyBase = new Element(tag, "wtf://no-such-protocol/", attribs);
        Assert.equals("http://bar/qux", dodgyBase.absUrl("absHref")); // base fails, but href good, so get that
        Assert.equals("", dodgyBase.absUrl("relHref")); // base fails, only rel href, so return nothing 
    }

    public function testSetBaseUriIsRecursive() {
        var doc:Document = Jsoup.parse("<div><p></p></div>");
        var baseUri = "http://jsoup.org";
        doc.setBaseUri(baseUri);
        
        Assert.equals(baseUri, doc.getBaseUri());
        Assert.equals(baseUri, doc.select("div").first().getBaseUri());
        Assert.equals(baseUri, doc.select("p").first().getBaseUri());
    }

    public function testHandlesAbsPrefix() {
        var doc:Document = Jsoup.parse("<a href=/foo>Hello</a>", "http://jsoup.org/");
        var a:Element = doc.select("a").first();
        Assert.equals("/foo", a.getAttr("href"));
        Assert.equals("http://jsoup.org/foo", a.getAttr("abs:href"));
        Assert.isTrue(a.hasAttr("abs:href"));
    }

    public function testHandlesAbsOnImage() {
        var doc:Document = Jsoup.parse("<p><img src=\"/rez/osi_logo.png\" /></p>", "http://jsoup.org/");
        var img:Element = doc.select("img").first();
        Assert.equals("http://jsoup.org/rez/osi_logo.png", img.getAttr("abs:src"));
        Assert.equals(img.absUrl("src"), img.getAttr("abs:src"));
    }

    public function testHandlesAbsPrefixOnHasAttr() {
        // 1: no abs url; 2: has abs url
        var doc:Document = Jsoup.parse("<a id=1 href='/foo'>One</a> <a id=2 href='http://jsoup.org/'>Two</a>");
        var one:Element = doc.select("#1").first();
        var two:Element = doc.select("#2").first();

        Assert.isFalse(one.hasAttr("abs:href"));
        Assert.isTrue(one.hasAttr("href"));
        Assert.equals("", one.absUrl("href"));

        Assert.isTrue(two.hasAttr("abs:href"));
        Assert.isTrue(two.hasAttr("href"));
        Assert.equals("http://jsoup.org/", two.absUrl("href"));
    }

    public function testLiteralAbsPrefix() {
        // if there is a literal attribute "abs:xxx", don't try and make absolute.
        var doc:Document = Jsoup.parse("<a abs:href='odd'>One</a>");
        var el:Element = doc.select("a").first();
		Assert.isTrue(el.hasAttr("abs:href"));
        Assert.equals("odd", el.getAttr("abs:href"));
    }

    public function testHandleAbsOnFileUris() {
        var doc:Document = Jsoup.parse("<a href='password'>One/a><a href='/var/log/messages'>Two</a>", "file:/etc/");
        var one:Element = doc.select("a").first();
		Assert.equals("file:/etc/password", one.absUrl("href"));
        var two:Element = doc.select("a").get(1);
        Assert.equals("file:/var/log/messages", two.absUrl("href"));
    }
	
    public function testHandleAbsOnLocalhostFileUris() {
        var doc:Document = Jsoup.parse("<a href='password'>One/a><a href='/var/log/messages'>Two</a>", "file://localhost/etc/");
        var one:Element = doc.select("a").first();
        Assert.equals("file://localhost/etc/password", one.absUrl("href"));
    }

    public function testHandlesAbsOnProtocolessAbsoluteUris() {
        var doc1:Document = Jsoup.parse("<a href='//example.net/foo'>One</a>", "http://example.com/");
        var doc2:Document = Jsoup.parse("<a href='//example.net/foo'>One</a>", "https://example.com/");

        var one:Element = doc1.select("a").first();
        var two:Element = doc2.select("a").first();

        Assert.equals("http://example.net/foo", one.absUrl("href"));
        Assert.equals("https://example.net/foo", two.absUrl("href"));

        var doc3:Document = Jsoup.parse("<img src=//www.google.com/images/errors/logo_sm.gif alt=Google>", "https://google.com");
        Assert.equals("https://www.google.com/images/errors/logo_sm.gif", doc3.select("img").getAttr("abs:src"));
    }

    /*
    Test for an issue with Java's abs URL handler.
     */
    public function testAbsHandlesRelativeQuery() {
        var doc:Document = Jsoup.parse("<a href='?foo'>One</a> <a href='bar.html?foo'>Two</a>", "http://jsoup.org/path/file?bar");

        var a1:Element = doc.select("a").first();
        Assert.equals("http://jsoup.org/path/file?foo", a1.absUrl("href"));

        var a2:Element = doc.select("a").get(1);
        Assert.equals("http://jsoup.org/path/bar.html?foo", a2.absUrl("href"));
    }

    public function testAbsHandlesDotFromIndex() {
        var doc:Document = Jsoup.parse("<a href='./one/two.html'>One</a>", "http://example.com");
        var a1:Element = doc.select("a").first();
        Assert.equals("http://example.com/one/two.html", a1.absUrl("href"));
    }
    
    public function testRemove() {
        var doc:Document = Jsoup.parse("<p>One <span>two</span> three</p>");
        var p:Element = doc.select("p").first();
        p.childNode(0).remove();
        
        Assert.equals("two three", p.getText());
        Assert.equals("<span>two</span> three", TextUtil.stripNewlines(p.getHtml()));
    }
    
    public function testReplace() {
        var doc:Document = Jsoup.parse("<p>One <span>two</span> three</p>");
        var p:Element = doc.select("p").first();
        var insert:Element = doc.createElement("em").setText("foo");
        p.childNode(1).replaceWith(insert);
        
        Assert.equals("One <em>foo</em> three", p.getHtml());
    }
    
    public function testOwnerDocument() {
        var doc:Document = Jsoup.parse("<p>Hello");
        var p:Element = doc.select("p").first();
        Assert.isTrue(p.ownerDocument() == doc);
        Assert.isTrue(doc.ownerDocument() == doc);
        Assert.isNull(doc.parent());
    }

    public function testBefore() {
        var doc:Document = Jsoup.parse("<p>One <b>two</b> three</p>");
        var newNode:Element = new Element(Tag.valueOf("em"), "", new Attributes());
        newNode.appendText("four");

        doc.select("b").first().beforeNode(newNode);
        Assert.equals("<p>One <em>four</em><b>two</b> three</p>", doc.body().getHtml());

        doc.select("b").first().before("<i>five</i>");
        Assert.equals("<p>One <em>four</em><i>five</i><b>two</b> three</p>", doc.body().getHtml());
    }

    public function testAfter() {
        var doc:Document = Jsoup.parse("<p>One <b>two</b> three</p>");
        var newNode:Element = new Element(Tag.valueOf("em"), "", new Attributes());
        newNode.appendText("four");

        doc.select("b").first().afterNode(newNode);
        Assert.equals("<p>One <b>two</b><em>four</em> three</p>", doc.body().getHtml());

        doc.select("b").first().after("<i>five</i>");
        Assert.equals("<p>One <b>two</b><i>five</i><em>four</em> three</p>", doc.body().getHtml());
    }

    public function testUnwrap() {
        var doc:Document = Jsoup.parse("<div>One <span>Two <b>Three</b></span> Four</div>");
        var span:Element = doc.select("span").first();
        var twoText:Node = span.childNode(0);
        var node:Node = span.unwrap();

        Assert.equals("<div>One Two <b>Three</b> Four</div>", TextUtil.stripNewlines(doc.body().getHtml()));
        Assert.isTrue(Std.is(node, TextNode));
        Assert.equals("Two ", cast(node, TextNode).getText());
        Assert.equals(node, twoText);
        Assert.equals(node.parent(), doc.select("div").first());
    }

    public function testUnwrapNoChildren() {
        var doc:Document = Jsoup.parse("<div>One <span></span> Two</div>");
        var span:Element = doc.select("span").first();
        var node:Node = span.unwrap();
        Assert.equals("<div>One  Two</div>", TextUtil.stripNewlines(doc.body().getHtml()));
        Assert.isTrue(node == null);
    }

    public function testTraverse() {
        var doc:Document = Jsoup.parse("<div><p>Hello</p></div><div>There</div>");
        var accum = new StringBuilder();
		
		var visitor:NodeVisitor = {
            head: function(node:Node, depth:Int):Void {
                accum.add("<" + node.nodeName() + ">");
            },

            tail: function(node:Node, depth:Int):Void {
                accum.add("</" + node.nodeName() + ">");
            }
		};
		
        doc.select("div").first().traverse(visitor);
        Assert.equals("<div><p><#text></#text></p></div>", accum.toString());
    }

    public function testOrphanNodeReturnsNullForSiblingElements() {
        var node:Node = new Element(Tag.valueOf("p"), "", null);
        var el:Element = new Element(Tag.valueOf("p"), "", null);

        Assert.equals(0, node.getSiblingIndex());
        Assert.equals(0, node.siblingNodes().size);

        Assert.isNull(node.previousSibling());
        Assert.isNull(node.nextSibling());

        Assert.equals(0, el.siblingElements().size);
        Assert.isNull(el.previousElementSibling());
        Assert.isNull(el.nextElementSibling());
    }

    public function testNodeIsNotASiblingOfItself() {
        var doc:Document = Jsoup.parse("<div><p>One<p>Two<p>Three</div>");
        var p2:Element = doc.select("p").get(1);

        Assert.equals("Two", p2.getText());
        var nodes:List<Node> = p2.siblingNodes();
        Assert.equals(2, nodes.size);
        Assert.equals("<p>One</p>", nodes.get(0).outerHtml());
        Assert.equals("<p>Three</p>", nodes.get(1).outerHtml());
    }

    public function testChildNodesCopy() {
        var doc:Document = Jsoup.parse("<div id=1>Text 1 <p>One</p> Text 2 <p>Two<p>Three</div><div id=2>");
        var div1:Element = doc.select("#1").first();
        var div2:Element = doc.select("#2").first();
        var divChildren:List<Node> = div1.childNodesCopy();
        Assert.equals(5, divChildren.size);
        var tn1:TextNode = cast div1.childNode(0);
        var tn2:TextNode = cast divChildren.get(0);
        tn2.setText("Text 1 updated");
        Assert.equals("Text 1 ", tn1.getText());
        div2.insertChildren(-1, divChildren);
        Assert.equals("<div id=\"1\">Text 1 <p>One</p> Text 2 <p>Two</p><p>Three</p></div><div id=\"2\">Text 1 updated"
            +"<p>One</p> Text 2 <p>Two</p><p>Three</p></div>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testSupportsClone() {
        var doc:Document = org.jsoup.Jsoup.parse("<div class=foo>Text</div>");
        var el:Element = doc.select("div").first();
        Assert.isTrue(el.hasClass("foo"));

        var elClone:Element = doc.clone().select("div").first();
        Assert.isTrue(elClone.hasClass("foo"));
        Assert.isTrue(elClone.getText() == ("Text"));

        el.removeClass("foo");
        el.setText("None");
        Assert.isFalse(el.hasClass("foo"));
        Assert.isTrue(elClone.hasClass("foo"));
        Assert.isTrue(el.getText() == ("None"));
        Assert.isTrue(elClone.getText() == ("Text"));
    }
}
