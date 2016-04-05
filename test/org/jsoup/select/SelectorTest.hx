package org.jsoup.select;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.List;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import unifill.CodePoint;

import utest.Assert;

/*
import org.junit.Test;

import static org.junit.Assert.*;
*/

/**
 * Tests that the selector selects correctly.
 *
 * @author Jonathan Hedley, jonathan@hedley.net
 */
class SelectorTest {
	
	public function new() { }
	
    public function testByTag() {
        var els = Jsoup.parse("<div id=1><div id=2><p>Hello</p></div></div><div id=3>").select("div");
        Assert.equals(3, els.size);
        Assert.equals("1", els.get(0).id());
        Assert.equals("2", els.get(1).id());
        Assert.equals("3", els.get(2).id());

        var none = Jsoup.parse("<div id=1><div id=2><p>Hello</p></div></div><div id=3>").select("span");
        Assert.equals(0, none.size);
    }

    public function testById() {
        var els = Jsoup.parse("<div><p id=foo>Hello</p><p id=foo>Foo two!</p></div>").select("#foo");
        Assert.equals(2, els.size);
        Assert.equals("Hello", els.get(0).getText());
        Assert.equals("Foo two!", els.get(1).getText());

        var none = Jsoup.parse("<div id=1></div>").select("#foo");
        Assert.equals(0, none.size);
    }

    public function testByClass() {
        var els = Jsoup.parse("<p id=0 class='one two'><p id=1 class='one'><p id=2 class='two'>").select("p.one");
        Assert.equals(2, els.size);
        Assert.equals("0", els.get(0).id());
        Assert.equals("1", els.get(1).id());

        var none = Jsoup.parse("<div class='one'></div>").select(".foo");
        Assert.equals(0, none.size);

        var els2 = Jsoup.parse("<div class='One-Two'></div>").select(".one-two");
        Assert.equals(1, els2.size);
    }

    public function testByAttribute() {
        var h = "<div Title=Foo /><div Title=Bar /><div Style=Qux /><div title=Bam /><div title=SLAM />" +
                "<div data-name='with spaces'/>";
        var doc = Jsoup.parse(h);

        var withTitle = doc.select("[title]");
        Assert.equals(4, withTitle.size);

        var foo = doc.select("[title=foo]");
        Assert.equals(1, foo.size);

        var foo2 = doc.select("[title=\"foo\"]");
        Assert.equals(1, foo2.size);

        var foo3 = doc.select("[title=\"Foo\"]");
        Assert.equals(1, foo3.size);

        var dataName = doc.select("[data-name=\"with spaces\"]");
        Assert.equals(1, dataName.size);
        Assert.equals("with spaces", dataName.first().getAttr("data-name"));

        var not = doc.select("div[title!=bar]");
        Assert.equals(5, not.size);
        Assert.equals("Foo", not.first().getAttr("title"));

        var starts = doc.select("[title^=ba]");
        Assert.equals(2, starts.size);
        Assert.equals("Bar", starts.first().getAttr("title"));
        Assert.equals("Bam", starts.last().getAttr("title"));

        var ends = doc.select("[title$=am]");
        Assert.equals(2, ends.size);
        Assert.equals("Bam", ends.first().getAttr("title"));
        Assert.equals("SLAM", ends.last().getAttr("title"));

        var contains = doc.select("[title*=a]");
        Assert.equals(3, contains.size);
        Assert.equals("Bar", contains.first().getAttr("title"));
        Assert.equals("SLAM", contains.last().getAttr("title"));
    }

    public function testNamespacedTag() {
        var doc = Jsoup.parse("<div><abc:def id=1>Hello</abc:def></div> <abc:def class=bold id=2>There</abc:def>");
        var byTag = doc.select("abc|def");
        Assert.equals(2, byTag.size);
        Assert.equals("1", byTag.first().id());
        Assert.equals("2", byTag.last().id());

        var byAttr = doc.select(".bold");
        Assert.equals(1, byAttr.size);
        Assert.equals("2", byAttr.last().id());

        var byTagAttr = doc.select("abc|def.bold");
        Assert.equals(1, byTagAttr.size);
        Assert.equals("2", byTagAttr.last().id());

        var byContains = doc.select("abc|def:contains(e)");
        Assert.equals(2, byContains.size);
        Assert.equals("1", byContains.first().id());
        Assert.equals("2", byContains.last().id());
    }

    public function testByAttributeStarting() {
        var doc = Jsoup.parse("<div id=1 data-name=jsoup>Hello</div><p data-val=5 id=2>There</p><p id=3>No</p>");
        var withData = doc.select("[^data-]");
        Assert.equals(2, withData.size);
        Assert.equals("1", withData.first().id());
        Assert.equals("2", withData.last().id());

        withData = doc.select("p[^data-]");
        Assert.equals(1, withData.size);
        Assert.equals("2", withData.first().id());
    }

    public function testByAttributeRegex() {
	#if js
		Assert.warn("js doesn't support regexp inline modifiers (f.e.: (?i))"); 
	#end
        var doc = Jsoup.parse("<p><img src=foo.png id=1><img src=bar.jpg id=2><img src=qux.JPEG id=3><img src=old.gif><img></p>");
        var imgs = doc.select("img[src~=(?i)\\.(png|jpe?g)]");
        Assert.equals(3, imgs.size);
        Assert.equals("1", imgs.get(0).id());
        Assert.equals("2", imgs.get(1).id());
        Assert.equals("3", imgs.get(2).id());
    }

    public function testByAttributeRegexCharacterClass() {
        var doc = Jsoup.parse("<p><img src=foo.png id=1><img src=bar.jpg id=2><img src=qux.JPEG id=3><img src=old.gif id=4></p>");
        var imgs = doc.select("img[src~=[o]]");
        Assert.equals(2, imgs.size);
        Assert.equals("1", imgs.get(0).id());
        Assert.equals("4", imgs.get(1).id());
    }

    public function testByAttributeRegexCombined() {
        var doc = Jsoup.parse("<div><table class=x><td>Hello</td></table></div>");
        var els = doc.select("div table[class~=x|y]");
        Assert.equals(1, els.size);
        Assert.equals("Hello", els.text());
    }

    public function testCombinedWithContains() {
        var doc = Jsoup.parse("<p id=1>One</p><p>Two +</p><p>Three +</p>");
        var els = doc.select("p#1 + :contains(+)");
        Assert.equals(1, els.size);
        Assert.equals("Two +", els.text());
        Assert.equals("p", els.first().getTagName());
    }

    public function testAllElements() {
        var h = "<div><p>Hello</p><p><b>there</b></p></div>";
        var doc = Jsoup.parse(h);
        var allDoc = doc.select("*");
        var allUnderDiv = doc.select("div *");
        Assert.equals(8, allDoc.size);
        Assert.equals(3, allUnderDiv.size);
        Assert.equals("p", allUnderDiv.first().getTagName());
    }

    public function testAllWithClass() {
        var h = "<p class=first>One<p class=first>Two<p>Three";
        var doc = Jsoup.parse(h);
        var ps = doc.select("*.first");
        Assert.equals(2, ps.size);
    }

    public function testGroupOr() {
        var h = "<div title=foo /><div title=bar /><div /><p></p><img /><span title=qux>";
        var doc = Jsoup.parse(h);
        var els = doc.select("p,div,[title]");

        Assert.equals(5, els.size);
        Assert.equals("div", els.get(0).getTagName());
        Assert.equals("foo", els.get(0).getAttr("title"));
        Assert.equals("div", els.get(1).getTagName());
        Assert.equals("bar", els.get(1).getAttr("title"));
        Assert.equals("div", els.get(2).getTagName());
        Assert.isTrue(els.get(2).getAttr("title").length == 0); // missing attributes come back as empty string
        Assert.isFalse(els.get(2).hasAttr("title"));
        Assert.equals("p", els.get(3).getTagName());
        Assert.equals("span", els.get(4).getTagName());
    }

    public function testGroupOrAttribute() {
        var h = "<div id=1 /><div id=2 /><div title=foo /><div title=bar />";
        var els = Jsoup.parse(h).select("[id],[title=foo]");

        Assert.equals(3, els.size);
        Assert.equals("1", els.get(0).id());
        Assert.equals("2", els.get(1).id());
        Assert.equals("foo", els.get(2).getAttr("title"));
    }

    public function testDescendant() {
        var h = "<div class=head><p class=first>Hello</p><p>There</p></div><p>None</p>";
        var doc = Jsoup.parse(h);
        var root = doc.getElementsByClass("head").first();
        
        var els = root.select(".head p");
        Assert.equals(2, els.size);
        Assert.equals("Hello", els.get(0).getText());
        Assert.equals("There", els.get(1).getText());

        var p = root.select("p.first");
        Assert.equals(1, p.size);
        Assert.equals("Hello", p.get(0).getText());

        var empty = root.select("p .first"); // self, not descend, should not match
        Assert.equals(0, empty.size);
        
        var aboveRoot = root.select("body div.head");
        Assert.equals(0, aboveRoot.size);
    }

    public function testAnd() {
        var h = "<div id=1 class='foo bar' title=bar name=qux><p class=foo title=bar>Hello</p></div";
        var doc = Jsoup.parse(h);

        var div = doc.select("div.foo");
        Assert.equals(1, div.size);
        Assert.equals("div", div.first().getTagName());

        var p = doc.select("div .foo"); // space indicates like "div *.foo"
        Assert.equals(1, p.size);
        Assert.equals("p", p.first().getTagName());

        var div2 = doc.select("div#1.foo.bar[title=bar][name=qux]"); // very specific!
        Assert.equals(1, div2.size);
        Assert.equals("div", div2.first().getTagName());

        var p2 = doc.select("div *.foo"); // space indicates like "div *.foo"
        Assert.equals(1, p2.size);
        Assert.equals("p", p2.first().getTagName());
    }

    public function testDeeperDescendant() {
        var h = "<div class=head><p><span class=first>Hello</div><div class=head><p class=first><span>Another</span><p>Again</div>";
        var doc = Jsoup.parse(h);
        var root = doc.getElementsByClass("head").first();

        var els = root.select("div p .first");
        Assert.equals(1, els.size);
        Assert.equals("Hello", els.first().getText());
        Assert.equals("span", els.first().getTagName());

        var aboveRoot = root.select("body p .first");
        Assert.equals(0, aboveRoot.size);
    }

    public function testParentChildElement() {
        var h = "<div id=1><div id=2><div id = 3></div></div></div><div id=4></div>";
        var doc = Jsoup.parse(h);

        var divs = doc.select("div > div");
        Assert.equals(2, divs.size);
        Assert.equals("2", divs.get(0).id()); // 2 is child of 1
        Assert.equals("3", divs.get(1).id()); // 3 is child of 2

        var div2 = doc.select("div#1 > div");
        Assert.equals(1, div2.size);
        Assert.equals("2", div2.get(0).id());
    }

    public function testParentWithClassChild() {
        var h = "<h1 class=foo><a href=1 /></h1><h1 class=foo><a href=2 class=bar /></h1><h1><a href=3 /></h1>";
        var doc = Jsoup.parse(h);

        var allAs = doc.select("h1 > a");
        Assert.equals(3, allAs.size);
        Assert.equals("a", allAs.first().getTagName());

        var fooAs = doc.select("h1.foo > a");
        Assert.equals(2, fooAs.size);
        Assert.equals("a", fooAs.first().getTagName());

        var barAs = doc.select("h1.foo > a.bar");
        Assert.equals(1, barAs.size);
    }

    public function testParentChildStar() {
        var h = "<div id=1><p>Hello<p><b>there</b></p></div><div id=2><span>Hi</span></div>";
        var doc = Jsoup.parse(h);
        var divChilds = doc.select("div > *");
        Assert.equals(3, divChilds.size);
        Assert.equals("p", divChilds.get(0).getTagName());
        Assert.equals("p", divChilds.get(1).getTagName());
        Assert.equals("span", divChilds.get(2).getTagName());
    }

    public function testMultiChildDescent() {
        var h = "<div id=foo><h1 class=bar><a href=http://example.com/>One</a></h1></div>";
        var doc = Jsoup.parse(h);
        var els = doc.select("div#foo > h1.bar > a[href*=example]");
        Assert.equals(1, els.size);
        Assert.equals("a", els.first().getTagName());
    }

    public function testCaseInsensitive() {
        var h = "<dIv tItle=bAr><div>"; // mixed case so a simple toLowerCase() on value doesn't catch
        var doc = Jsoup.parse(h);

        Assert.equals(2, doc.select("DIV").size);
        Assert.equals(1, doc.select("DIV[TITLE]").size);
        Assert.equals(1, doc.select("DIV[TITLE=BAR]").size);
        Assert.equals(0, doc.select("DIV[TITLE=BARBARELLA").size);
    }

    public function testAdjacentSiblings() {
        var h = "<ol><li>One<li>Two<li>Three</ol>";
        var doc = Jsoup.parse(h);
        var sibs = doc.select("li + li");
        Assert.equals(2, sibs.size);
        Assert.equals("Two", sibs.get(0).getText());
        Assert.equals("Three", sibs.get(1).getText());
    }

    public function testAdjacentSiblingsWithId() {
        var h = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>";
        var doc = Jsoup.parse(h);
        var sibs = doc.select("li#1 + li#2");
        Assert.equals(1, sibs.size);
        Assert.equals("Two", sibs.get(0).getText());
    }

    public function testNotAdjacent() {
        var h = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>";
        var doc = Jsoup.parse(h);
        var sibs = doc.select("li#1 + li#3");
        Assert.equals(0, sibs.size);
    }

    public function testMixCombinator() {
        var h = "<div class=foo><ol><li>One<li>Two<li>Three</ol></div>";
        var doc = Jsoup.parse(h);
        var sibs = doc.select("body > div.foo li + li");

        Assert.equals(2, sibs.size);
        Assert.equals("Two", sibs.get(0).getText());
        Assert.equals("Three", sibs.get(1).getText());
    }

    public function testMixCombinatorGroup() {
        var h = "<div class=foo><ol><li>One<li>Two<li>Three</ol></div>";
        var doc = Jsoup.parse(h);
        var els = doc.select(".foo > ol, ol > li + li");

        Assert.equals(3, els.size);
        Assert.equals("ol", els.get(0).getTagName());
        Assert.equals("Two", els.get(1).getText());
        Assert.equals("Three", els.get(2).getText());
    }

    public function testGeneralSiblings() {
        var h = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>";
        var doc = Jsoup.parse(h);
        var els = doc.select("#1 ~ #3");
        Assert.equals(1, els.size);
        Assert.equals("Three", els.first().getText());
    }

    // for http://github.com/jhy/jsoup/issues#issue/10
    public function testCharactersInIdAndClass() {
        // using CSS spec for identifiers (id and class): a-z0-9, -, _. NOT . (which is OK in html spec, but not css)
        var h = "<div><p id='a1-foo_bar'>One</p><p class='b2-qux_bif'>Two</p></div>";
        var doc = Jsoup.parse(h);

        var el1 = doc.getElementById("a1-foo_bar");
        Assert.equals("One", el1.getText());
        var el2 = doc.getElementsByClass("b2-qux_bif").first();
        Assert.equals("Two", el2.getText());

        var el3 = doc.select("#a1-foo_bar").first();
        Assert.equals("One", el3.getText());
        var el4 = doc.select(".b2-qux_bif").first();
        Assert.equals("Two", el4.getText());
    }

    // for http://github.com/jhy/jsoup/issues#issue/13
    public function testSupportsLeadingCombinator() {
        var h = "<div><p><span>One</span><span>Two</span></p></div>";
        var doc = Jsoup.parse(h);

        var p = doc.select("div > p").first();
        var spans = p.select("> span");
        Assert.equals(2, spans.size);
        Assert.equals("One", spans.first().getText());

        // make sure doesn't get nested
        h = "<div id=1><div id=2><div id=3></div></div></div>";
        doc = Jsoup.parse(h);
        var div = doc.select("div").select(" > div").first();
        Assert.equals("2", div.id());
    }

    public function testPseudoLessThan() {
        var doc = Jsoup.parse("<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>");
        var ps = doc.select("div p:lt(2)");
        Assert.equals(3, ps.size);
        Assert.equals("One", ps.get(0).getText());
        Assert.equals("Two", ps.get(1).getText());
        Assert.equals("Four", ps.get(2).getText());
    }

    public function testPseudoGreaterThan() {
        var doc = Jsoup.parse("<div><p>One</p><p>Two</p><p>Three</p></div><div><p>Four</p>");
        var ps = doc.select("div p:gt(0)");
        Assert.equals(2, ps.size);
        Assert.equals("Two", ps.get(0).getText());
        Assert.equals("Three", ps.get(1).getText());
    }

    public function testPseudoEquals() {
        var doc = Jsoup.parse("<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>");
        var ps = doc.select("div p:eq(0)");
        Assert.equals(2, ps.size);
        Assert.equals("One", ps.get(0).getText());
        Assert.equals("Four", ps.get(1).getText());

        var ps2 = doc.select("div:eq(0) p:eq(0)");
        Assert.equals(1, ps2.size);
        Assert.equals("One", ps2.get(0).getText());
        Assert.equals("p", ps2.get(0).getTagName());
    }

    public function testPseudoBetween() {
        var doc = Jsoup.parse("<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>");
        var ps = doc.select("div p:gt(0):lt(2)");
        Assert.equals(1, ps.size);
        Assert.equals("Two", ps.get(0).getText());
    }

    public function testPseudoCombined() {
        var doc = Jsoup.parse("<div class='foo'><p>One</p><p>Two</p></div><div><p>Three</p><p>Four</p></div>");
        var ps = doc.select("div.foo p:gt(0)");
        Assert.equals(1, ps.size);
        Assert.equals("Two", ps.get(0).getText());
    }

    public function testPseudoHas() {
        var doc = Jsoup.parse("<div id=0><p><span>Hello</span></p></div> <div id=1><span class=foo>There</span></div> <div id=2><p>Not</p></div>");

        var divs1 = doc.select("div:has(span)");
        Assert.equals(2, divs1.size);
        Assert.equals("0", divs1.get(0).id());
        Assert.equals("1", divs1.get(1).id());

        var divs2 = doc.select("div:has([class]");
        Assert.equals(1, divs2.size);
        Assert.equals("1", divs2.get(0).id());

        var divs3 = doc.select("div:has(span, p)");
        Assert.equals(3, divs3.size);
        Assert.equals("0", divs3.get(0).id());
        Assert.equals("1", divs3.get(1).id());
        Assert.equals("2", divs3.get(2).id());

        var els1 = doc.body().select(":has(p)");
        Assert.equals(3, els1.size); // body, div, dib
        Assert.equals("body", els1.first().getTagName());
        Assert.equals("0", els1.get(1).id());
        Assert.equals("2", els1.get(2).id());
    }

    public function testNestedHas() {
	#if js
		Assert.warn("js doesn't support regexp inline modifiers (f.e.: (?i))"); 
	#end
        var doc = Jsoup.parse("<div><p><span>One</span></p></div> <div><p>Two</p></div>");
        var divs = doc.select("div:has(p:has(span))");
        Assert.equals(1, divs.size);
        Assert.equals("One", divs.first().getText());

        // test matches in has
        divs = doc.select("div:has(p:matches((?i)two))");
        Assert.equals(1, divs.size);
        Assert.equals("div", divs.first().getTagName());
        Assert.equals("Two", divs.first().getText());

        // test contains in has
        divs = doc.select("div:has(p:contains(two))");
        Assert.equals(1, divs.size);
        Assert.equals("div", divs.first().getTagName());
        Assert.equals("Two", divs.first().getText());
    }

    public function testPseudoContains() {
        var doc = Jsoup.parse("<div><p>The Rain.</p> <p class=light>The <i>rain</i>.</p> <p>Rain, the.</p></div>");

        var ps1 = doc.select("p:contains(Rain)");
        Assert.equals(3, ps1.size);

        var ps2 = doc.select("p:contains(the rain)");
        Assert.equals(2, ps2.size);
        Assert.equals("The Rain.", ps2.first().getHtml());
        Assert.equals("The <i>rain</i>.", ps2.last().getHtml());

        var ps3 = doc.select("p:contains(the Rain):has(i)");
        Assert.equals(1, ps3.size);
        Assert.equals("light", ps3.first().className());

        var ps4 = doc.select(".light:contains(rain)");
        Assert.equals(1, ps4.size);
        Assert.equals("light", ps3.first().className());

        var ps5 = doc.select(":contains(rain)");
        Assert.equals(8, ps5.size); // html, body, div,...
    }

    public function testPseudoContainsWithParentheses() {
        var doc = Jsoup.parse("<div><p id=1>This (is good)</p><p id=2>This is bad)</p>");

        var ps1 = doc.select("p:contains(this (is good))");
        Assert.equals(1, ps1.size);
        Assert.equals("1", ps1.first().id());

        var ps2 = doc.select("p:contains(this is bad\\))");
        Assert.equals(1, ps2.size);
        Assert.equals("2", ps2.first().id());
    }

    public function testContainsOwn() {
        var doc = Jsoup.parse("<p id=1>Hello <b>there</b> now</p>");
        var ps = doc.select("p:containsOwn(Hello now)");
        Assert.equals(1, ps.size);
        Assert.equals("1", ps.first().id());

        Assert.equals(0, doc.select("p:containsOwn(there)").size);
    }

    public function testMatches() {
	#if js
		Assert.warn("js doesn't support regexp inline modifiers (f.e.: (?i))"); 
	#end
        var doc = Jsoup.parse("<p id=1>The <i>Rain</i></p> <p id=2>There are 99 bottles.</p> <p id=3>Harder (this)</p> <p id=4>Rain</p>");

        var p1 = doc.select("p:matches(The rain)"); // no match, case sensitive
        Assert.equals(0, p1.size);

        var p2 = doc.select("p:matches((?i)the rain)"); // case insense. should include root, html, body
        Assert.equals(1, p2.size);
        Assert.equals("1", p2.first().id());

        var p4 = doc.select("p:matches((?i)^rain$)"); // bounding
        Assert.equals(1, p4.size);
        Assert.equals("4", p4.first().id());

        var p5 = doc.select("p:matches(\\d+)");
        Assert.equals(1, p5.size);
        Assert.equals("2", p5.first().id());

        var p6 = doc.select("p:matches(\\w+\\s+\\(\\w+\\))"); // test bracket matching
        Assert.equals(1, p6.size);
        Assert.equals("3", p6.first().id());

        var p7 = doc.select("p:matches((?i)the):has(i)"); // multi
        Assert.equals(1, p7.size);
        Assert.equals("1", p7.first().id());
    }

    public function testMatchesOwn() {
	#if js
		Assert.warn("js doesn't support regexp inline modifiers (f.e.: (?i))"); 
	#end
        var doc = Jsoup.parse("<p id=1>Hello <b>there</b> now</p>");

        var p1 = doc.select("p:matchesOwn((?i)hello now)");
        Assert.equals(1, p1.size);
        Assert.equals("1", p1.first().id());

        Assert.equals(0, doc.select("p:matchesOwn(there)").size);
    }

    public function testRelaxedTags() {
        var doc = Jsoup.parse("<abc_def id=1>Hello</abc_def> <abc-def id=2>There</abc-def>");

        var el1 = doc.select("abc_def");
        Assert.equals(1, el1.size);
        Assert.equals("1", el1.first().id());

        var el2 = doc.select("abc-def");
        Assert.equals(1, el2.size);
        Assert.equals("2", el2.first().id());
    }

    public function testNotParas() {
        var doc = Jsoup.parse("<p id=1>One</p> <p>Two</p> <p><span>Three</span></p>");

        var el1 = doc.select("p:not([id=1])");
        Assert.equals(2, el1.size);
        Assert.equals("Two", el1.first().getText());
        Assert.equals("Three", el1.last().getText());

        var el2 = doc.select("p:not(:has(span))");
        Assert.equals(2, el2.size);
        Assert.equals("One", el2.first().getText());
        Assert.equals("Two", el2.last().getText());
    }

    public function testNotAll() {
        var doc = Jsoup.parse("<p>Two</p> <p><span>Three</span></p>");

        var el1 = doc.body().select(":not(p)"); // should just be the span
        Assert.equals(2, el1.size);
        Assert.equals("body", el1.first().getTagName());
        Assert.equals("span", el1.last().getTagName());
    }

    public function testNotClass() {
        var doc = Jsoup.parse("<div class=left>One</div><div class=right id=1><p>Two</p></div>");

        var el1 = doc.select("div:not(.left)");
        Assert.equals(1, el1.size);
        Assert.equals("1", el1.first().id());
    }

    public function testHandlesCommasInSelector() {
        var doc = Jsoup.parse("<p name='1,2'>One</p><div>Two</div><ol><li>123</li><li>Text</li></ol>");

        var ps = doc.select("[name=1,2]");
        Assert.equals(1, ps.size);

        var containers = doc.select("div, li:matches([0-9,]+)");
        Assert.equals(2, containers.size);
        Assert.equals("div", containers.get(0).getTagName());
        Assert.equals("li", containers.get(1).getTagName());
        Assert.equals("123", containers.get(1).getText());
    }

    public function testSelectSupplementaryCharacter() {
        var s = CodePoint.fromInt(135361).toString();
        var doc = Jsoup.parse("<div k" + s + "='" + s + "'>^" + s +"$/div>");
        Assert.equals("div", doc.select("div[k" + s + "]").first().getTagName());
        Assert.equals("div", doc.select("div:containsOwn(" + s + ")").first().getTagName());
    }
    
    public function testSelectClassWithSpace() {
        var html = "<div class=\"value\">class without space</div>\n"
                          + "<div class=\"value \">class with space</div>";
        
        var doc = Jsoup.parse(html);
        
        var found = doc.select("div[class=value ]");
        Assert.equals(2, found.size);
        Assert.equals("class without space", found.get(0).getText());
        Assert.equals("class with space", found.get(1).getText());
        
        found = doc.select("div[class=\"value \"]");
        Assert.equals(2, found.size);
        Assert.equals("class without space", found.get(0).getText());
        Assert.equals("class with space", found.get(1).getText());
        
        found = doc.select("div[class=\"value\\ \"]");
        Assert.equals(0, found.size);
    }

    public function testSelectSameElements() {
        var html = "<div>one</div><div>one</div>";

        var doc = Jsoup.parse(html);
        var els = doc.select("div");
        Assert.equals(2, els.size);

        var subSelect = els.select(":contains(one)");
        Assert.equals(2, subSelect.size);
    }
}
