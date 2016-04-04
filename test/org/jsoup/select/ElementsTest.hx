package org.jsoup.select;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.List;
import org.jsoup.helper.StringBuilder;
import org.jsoup.Jsoup;
import org.jsoup.TextUtil;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.FormElement;
import org.jsoup.nodes.Node;

import utest.Assert;

/*
import org.junit.Test;

import java.util.List;

import static org.junit.Assert.*;
*/

/**
 Tests for ElementList.

 @author Jonathan Hedley, jonathan@hedley.net */
class ElementsTest {
	
	public function new() { }
	
    public function testFilter() {
        var h = "<p>Excl</p><div class=headline><p>Hello</p><p>There</p></div><div class=headline><h1>Headline</h1></div>";
        var doc = Jsoup.parse(h);
        var els = doc.select(".headline").select("p");
        Assert.equals(2, els.size);
        Assert.equals("Hello", els.get(0).getText());
        Assert.equals("There", els.get(1).getText());
    }

    public function testAttributes() {
        var h = "<p title=foo><p title=bar><p class=foo><p class=bar>";
        var doc = Jsoup.parse(h);
        var withTitle = doc.select("p[title]");
        Assert.equals(2, withTitle.size);
        Assert.isTrue(withTitle.hasAttr("title"));
        Assert.isFalse(withTitle.hasAttr("class"));
        Assert.equals("foo", withTitle.getAttr("title"));

        withTitle.removeAttr("title");
        Assert.equals(2, withTitle.size); // existing Elements are not reevaluated
        Assert.equals(0, doc.select("p[title]").size);

        var ps:Elements = doc.select("p").setAttr("style", "classy");
        Assert.equals(4, ps.size);
        Assert.equals("classy", ps.last().getAttr("style"));
        Assert.equals("bar", ps.last().getAttr("class"));
    }
    
    public function testHasAttr() {
        var doc = Jsoup.parse("<p title=foo><p title=bar><p class=foo><p class=bar>");
        var ps = doc.select("p");
        Assert.isTrue(ps.hasAttr("class"));
        Assert.isFalse(ps.hasAttr("style"));
    }

    public function testHasAbsAttr() {
        var doc = Jsoup.parse("<a id=1 href='/foo'>One</a> <a id=2 href='http://jsoup.org'>Two</a>");
        var one = doc.select("#1");
        var two = doc.select("#2");
        var both = doc.select("a");
        Assert.isFalse(one.hasAttr("abs:href"));
        Assert.isTrue(two.hasAttr("abs:href"));
        Assert.isTrue(both.hasAttr("abs:href")); // hits on #2
    }
    
    public function testAttr() {
        var doc = Jsoup.parse("<p title=foo><p title=bar><p class=foo><p class=bar>");
		var classVal = doc.select("p").getAttr("class");
        Assert.equals("foo", classVal);
    }

    public function absAttr() {
        var doc = Jsoup.parse("<a id=1 href='/foo'>One</a> <a id=2 href='http://jsoup.org'>Two</a>");
        var one = doc.select("#1");
        var two = doc.select("#2");
        var both = doc.select("a");

        Assert.equals("", one.getAttr("abs:href"));
        Assert.equals("http://jsoup.org", two.getAttr("abs:href"));
        Assert.equals("http://jsoup.org", both.getAttr("abs:href"));
    }

    public function classes() {
        var doc = Jsoup.parse("<div><p class='mellow yellow'></p><p class='red green'></p>");

        var els = doc.select("p");
        Assert.isTrue(els.hasClass("red"));
        Assert.isFalse(els.hasClass("blue"));
        els.addClass("blue");
        els.removeClass("yellow");
        els.toggleClass("mellow");

        Assert.equals("blue", els.get(0).className());
        Assert.equals("red green blue mellow", els.get(1).className());
    }
    
    public function testText() {
        var h = "<div><p>Hello<p>there<p>world</div>";
        var doc = Jsoup.parse(h);
        Assert.equals("Hello there world", doc.select("div > *").text());
    }

    public function testHasText() {
        var doc = Jsoup.parse("<div><p>Hello</p></div><div><p></p></div>");
        var divs = doc.select("div");
        Assert.isTrue(divs.hasText());
        Assert.isFalse(doc.select("div + div").hasText());
    }
    
    public function tesHtml() {
        var doc = Jsoup.parse("<div><p>Hello</p></div><div><p>There</p></div>");
        var divs = doc.select("div");
        Assert.equals("<p>Hello</p>\n<p>There</p>", divs.getHtml());
    }
    
    public function testOuterHtml() {
        var doc = Jsoup.parse("<div><p>Hello</p></div><div><p>There</p></div>");
        var divs = doc.select("div");
        Assert.equals("<div><p>Hello</p></div><div><p>There</p></div>", TextUtil.stripNewlines(divs.outerHtml()));
    }
    
    public function testSetHtml() {
        var doc = Jsoup.parse("<p>One</p><p>Two</p><p>Three</p>");
        var ps = doc.select("p");
        
        ps.prepend("<b>Bold</b>").append("<i>Ital</i>");
        Assert.equals("<p><b>Bold</b>Two<i>Ital</i></p>", TextUtil.stripNewlines(ps.get(1).outerHtml()));
        
        ps.setHtml("<span>Gone</span>");
        Assert.equals("<p><span>Gone</span></p>", TextUtil.stripNewlines(ps.get(1).outerHtml()));
    }
    
    public function testVal() {
        var doc = Jsoup.parse("<input value='one' /><textarea>two</textarea>");
        var els = doc.select("input, textarea");
        Assert.equals(2, els.size);
        Assert.equals("one", els.getVal());
        Assert.equals("two", els.last().getVal());
        
        els.setVal("three");
        Assert.equals("three", els.first().getVal());
        Assert.equals("three", els.last().getVal());
        Assert.equals("<textarea>three</textarea>", els.last().outerHtml());
    }
    
    public function testBefore() {
        var doc = Jsoup.parse("<p>This <a>is</a> <a>jsoup</a>.</p>");
        doc.select("a").before("<span>foo</span>");
        Assert.equals("<p>This <span>foo</span><a>is</a> <span>foo</span><a>jsoup</a>.</p>", TextUtil.stripNewlines(doc.body().getHtml()));
    }
    
    public function testAfter() {
        var doc = Jsoup.parse("<p>This <a>is</a> <a>jsoup</a>.</p>");
        doc.select("a").after("<span>foo</span>");
        Assert.equals("<p>This <a>is</a><span>foo</span> <a>jsoup</a><span>foo</span>.</p>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testWrap() {
        var h = "<p><b>This</b> is <b>jsoup</b></p>";
        var doc = Jsoup.parse(h);
        doc.select("b").wrap("<i></i>");
        Assert.equals("<p><i><b>This</b></i> is <i><b>jsoup</b></i></p>", doc.body().getHtml());
    }

    public function testWrapDiv() {
        var h = "<p><b>This</b> is <b>jsoup</b>.</p> <p>How do you like it?</p>";
        var doc = Jsoup.parse(h);
        doc.select("p").wrap("<div></div>");
        Assert.equals("<div><p><b>This</b> is <b>jsoup</b>.</p></div> <div><p>How do you like it?</p></div>",
                TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testUnwrap() {
        var h = "<div><font>One</font> <font><a href=\"/\">Two</a></font></div";
        var doc = Jsoup.parse(h);
        doc.select("font").unwrap();
        Assert.equals("<div>One <a href=\"/\">Two</a></div>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testUnwrapP() {
        var h = "<p><a>One</a> Two</p> Three <i>Four</i> <p>Fix <i>Six</i></p>";
        var doc = Jsoup.parse(h);
        doc.select("p").unwrap();
        Assert.equals("<a>One</a> Two Three <i>Four</i> Fix <i>Six</i>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testUnwrapKeepsSpace() {
        var h = "<p>One <span>two</span> <span>three</span> four</p>";
        var doc = Jsoup.parse(h);
        doc.select("span").unwrap();
        Assert.equals("<p>One two three four</p>", doc.body().getHtml());
    }

    public function testEmpty() {
        var doc = Jsoup.parse("<div><p>Hello <b>there</b></p> <p>now!</p></div>");
        doc.getOutputSettings().setPrettyPrint(false);

        doc.select("p").empty();
        Assert.equals("<div><p></p> <p></p></div>", doc.body().getHtml());
    }

    public function testRemove() {
        var doc = Jsoup.parse("<div><p>Hello <b>there</b></p> jsoup <p>now!</p></div>");
        doc.getOutputSettings().setPrettyPrint(false);
        
        doc.select("p").removeMatched();
        Assert.equals("<div> jsoup </div>", doc.body().getHtml());
    }
    
    public function testEq() {
        var h = "<p>Hello<p>there<p>world";
        var doc = Jsoup.parse(h);
        Assert.equals("there", doc.select("p").eq(1).text());
        Assert.equals("there", doc.select("p").get(1).getText());
    }
    
    public function testIs() {
        var h = "<p>Hello<p title=foo>there<p>world";
        var doc = Jsoup.parse(h);
        var ps = doc.select("p");
        Assert.isTrue(ps.is("[title=foo]"));
        Assert.isFalse(ps.is("[title=bar]"));
    }

    public function testParents() {
        var doc = Jsoup.parse("<div><p>Hello</p></div><p>There</p>");
        var parents = doc.select("p").parents();

        Assert.equals(3, parents.size);
        Assert.equals("div", parents.get(0).getTagName());
        Assert.equals("body", parents.get(1).getTagName());
        Assert.equals("html", parents.get(2).getTagName());
    }

    public function testNot() {
        var doc = Jsoup.parse("<div id=1><p>One</p></div> <div id=2><p><span>Two</span></p></div>");

        var div1 = doc.select("div").not(":has(p > span)");
        Assert.equals(1, div1.size);
        Assert.equals("1", div1.first().id());

        var div2 = doc.select("div").not("#1");
        Assert.equals(1, div2.size);
        Assert.equals("2", div2.first().id());
    }

    public function testTagNameSet() {
        var doc = Jsoup.parse("<p>Hello <i>there</i> <i>now</i></p>");
        doc.select("i").tagName("em");

        Assert.equals("<p>Hello <em>there</em> <em>now</em></p>", doc.body().getHtml());
    }

    public function testTraverse() {
        var doc = Jsoup.parse("<div><p>Hello</p></div><div>There</div>");
        var accum = new StringBuilder();
		var visitor:NodeVisitor = {
            head:function(node:Node, depth:Int) {
                accum.add("<" + node.nodeName() + ">");
            },

            tail:function(node:Node, depth:Int) {
                accum.add("</" + node.nodeName() + ">");
            }
		};
        
		doc.select("div").traverse(visitor);
        Assert.equals("<div><p><#text></#text></p></div><div><#text></#text></div>", accum.toString());
    }

    public function testForms() {
        var doc = Jsoup.parse("<form id=1><input name=q></form><div /><form id=2><input name=f></form>");
        var els = doc.select("*");
        Assert.equals(9, els.size);

        var forms:List<FormElement> = els.forms();
        Assert.equals(2, forms.size);
        Assert.isTrue(forms.get(0) != null);
        Assert.isTrue(forms.get(1) != null);
        Assert.equals("1", forms.get(0).id());
        Assert.equals("2", forms.get(1).id());
    }

    public function testClassWithHyphen() {
        var doc = Jsoup.parse("<p class='tab-nav'>Check</p>");
        var els = doc.getElementsByClass("tab-nav");
        Assert.equals(1, els.size);
        Assert.equals("Check", els.text());
    }
}
