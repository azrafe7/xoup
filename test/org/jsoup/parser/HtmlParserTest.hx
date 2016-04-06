package org.jsoup.parser;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import haxe.Timer;
import org.jsoup.helper.StringBuilder;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Entities.EscapeMode;
import org.jsoup.parser.tokens.Token.TokenDoctype;
import org.jsoup.TextUtil;
import org.jsoup.helper.StringUtil;
import org.jsoup.integration.ParseTest;
import org.jsoup.nodes.*;
import org.jsoup.select.Elements;

import utest.Assert;

/*
import org.junit.Test;

import java.io.File;
import java.io.IOException;
import java.util.List;

import static org.junit.Assert.Assert.equals;
import static org.junit.Assert.Assert.isTrue;
*/

/**
 Tests for the Parser

 @author Jonathan Hedley, jonathan@hedley.net */
class HtmlParserTest {

	public function new() { }
	
    public function testParsesSimpleDocument() {
        var html = "<html><head><title>First!</title></head><body><p>First post! <img src=\"foo.png\" /></p></body></html>";
        var doc = Jsoup.parse(html);
        // need a better way to verify these:
        var p = doc.body().child(0);
        Assert.equals("p", p.getTagName());
        var img = p.child(0);
        Assert.equals("foo.png", img.getAttr("src"));
        Assert.equals("img", img.getTagName());
    }

    public function testParsesRoughAttributes() {
        var html = "<html><head><title>First!</title></head><body><p class=\"foo > bar\">First post! <img src=\"foo.png\" /></p></body></html>";
        var doc = Jsoup.parse(html);

        // need a better way to verify these:
        var p = doc.body().child(0);
        Assert.equals("p", p.getTagName());
        Assert.equals("foo > bar", p.getAttr("class"));
    }

    public function testParsesQuiteRoughAttributes() {
        var html = "<p =a>One<a <p>Something</p>Else";
        // this gets a <p> with attr '=a' and an <a tag with an attribue named '<p'; and then auto-recreated
        var doc = Jsoup.parse(html);
        Assert.equals("<p =a>One<a <p>Something</a></p>\n" +
                "<a <p>Else</a>", doc.body().getHtml());

        doc = Jsoup.parse("<p .....>");
        Assert.equals("<p .....></p>", doc.body().getHtml());
    }

    public function testParsesComments() {
        var html = "<html><head></head><body><img src=foo><!-- <table><tr><td></table> --><p>Hello</p></body></html>";
        var doc = Jsoup.parse(html);

        var body = doc.body();
        var comment:Comment = cast body.childNode(1); // comment should not be sub of img, as it's an empty tag
        Assert.equals(" <table><tr><td></table> ", comment.getData());
        var p = body.child(1);
        var text:TextNode = cast p.childNode(0);
        Assert.equals("Hello", text.getWholeText());
    }

    public function testParsesUnterminatedComments() {
        var html = "<p>Hello<!-- <tr><td>";
        var doc = Jsoup.parse(html);
        var p = doc.getElementsByTag("p").get(0);
        Assert.equals("Hello", p.getText());
        var text:TextNode = cast p.childNode(0);
        Assert.equals("Hello", text.getWholeText());
        var comment:Comment = cast p.childNode(1);
        Assert.equals(" <tr><td>", comment.getData());
    }

    public function testDropsUnterminatedTag() {
        // jsoup used to parse this to <p>, but whatwg, webkit will drop.
        var h1 = "<p";
        var doc = Jsoup.parse(h1);
        Assert.equals(0, doc.getElementsByTag("p").size);
        Assert.equals("", doc.getText());

        var h2 = "<div id=1<p id='2'";
        doc = Jsoup.parse(h2);
        Assert.equals("", doc.getText());
    }

    public function testDropsUnterminatedAttribute() {
        // jsoup used to parse this to <p id="foo">, but whatwg, webkit will drop.
        var h1 = "<p id=\"foo";
        var doc = Jsoup.parse(h1);
        Assert.equals("", doc.getText());
    }

    public function testParsesUnterminatedTextarea() {
        // don't parse right to end, but break on <p>
        var doc = Jsoup.parse("<body><p><textarea>one<p>two");
        var t = doc.select("textarea").first();
        Assert.equals("one", t.getText());
        Assert.equals("two", doc.select("p").get(1).getText());
    }

    public function testParsesUnterminatedOption() {
        // bit weird this -- browsers and spec get stuck in select until there's a </select>
        var doc = Jsoup.parse("<body><p><select><option>One<option>Two</p><p>Three</p>");
        var options = doc.select("option");
        Assert.equals(2, options.size);
        Assert.equals("One", options.first().getText());
        Assert.equals("TwoThree", options.last().getText());
    }

    public function testSpaceAfterTag() {
        var doc = Jsoup.parse("<div > <a name=\"top\"></a ><p id=1 >Hello</p></div>");
        Assert.equals("<div> <a name=\"top\"></a><p id=\"1\">Hello</p></div>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testCreatesDocumentStructure() {
        var html = "<meta name=keywords /><link rel=stylesheet /><title>jsoup</title><p>Hello world</p>";
        var doc = Jsoup.parse(html);
        var head = doc.head();
        var body = doc.body();

        Assert.equals(1, doc.children().size); // root node: contains html node
        Assert.equals(2, doc.child(0).children().size); // html node: head and body
        Assert.equals(3, head.children().size);
        Assert.equals(1, body.children().size);

        Assert.equals("keywords", head.getElementsByTag("meta").get(0).getAttr("name"));
        Assert.equals(0, body.getElementsByTag("meta").size);
        Assert.equals("jsoup", doc.getTitle());
        Assert.equals("Hello world", body.getText());
        Assert.equals("Hello world", body.children().get(0).getText());
    }

    public function testCreatesStructureFromBodySnippet() {
        // the bar baz stuff naturally goes into the body, but the 'foo' goes into root, and the normalisation routine
        // needs to move into the start of the body
        var html = "foo <b>bar</b> baz";
        var doc = Jsoup.parse(html);
        Assert.equals("foo bar baz", doc.getText());

    }

    public function testHandlesEscapedData() {
        var html = "<div title='Surf &amp; Turf'>Reef &amp; Beef</div>";
        var doc = Jsoup.parse(html);
        var div = doc.getElementsByTag("div").get(0);

        Assert.equals("Surf & Turf", div.getAttr("title"));
        Assert.equals("Reef & Beef", div.getText());
    }

    public function testHandlesDataOnlyTags() {
        var t = "<style>font-family: bold</style>";
        var tels:List<Element> = Jsoup.parse(t).getElementsByTag("style");
        Assert.equals("font-family: bold", tels.get(0).data());
        Assert.equals("", tels.get(0).getText());

        var s = "<p>Hello</p><script>obj.insert('<a rel=\"none\" />');\ni++;</script><p>There</p>";
        var doc = Jsoup.parse(s);
        Assert.equals("Hello There", doc.getText());
        Assert.equals("obj.insert('<a rel=\"none\" />');\ni++;", doc.data());
    }

    public function testHandlesTextAfterData() {
        var h = "<html><body>pre <script>inner</script> aft</body></html>";
        var doc = Jsoup.parse(h);
        Assert.equals("<html><head></head><body>pre <script>inner</script> aft</body></html>", TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testHandlesTextArea() {
        var doc = Jsoup.parse("<textarea>Hello</textarea>");
        var els = doc.select("textarea");
        Assert.equals("Hello", els.text());
        Assert.equals("Hello", els.getVal());
    }

    public function testPreservesSpaceInTextArea() {
        // preserve because the tag is marked as preserve white space
        var doc = Jsoup.parse("<textarea>\n\tOne\n\tTwo\n\tThree\n</textarea>");
        var expect = "One\n\tTwo\n\tThree"; // the leading and trailing spaces are dropped as a convenience to authors
        var el = doc.select("textarea").first();
        Assert.equals(expect, el.getText());
        Assert.equals(expect, el.getVal());
        Assert.equals(expect, el.getHtml());
        Assert.equals("<textarea>\n\t" + expect + "\n</textarea>", el.outerHtml()); // but preserved in round-trip html
    }

    public function testPreservesSpaceInScript() {
        // preserve because it's content is a data node
        var doc = Jsoup.parse("<script>\nOne\n\tTwo\n\tThree\n</script>");
        var expect = "\nOne\n\tTwo\n\tThree\n";
        var el = doc.select("script").first();
        Assert.equals(expect, el.data());
        Assert.equals("One\n\tTwo\n\tThree", el.getHtml());
        Assert.equals("<script>" + expect + "</script>", el.outerHtml());
    }

    public function testDoesNotCreateImplicitLists() {
        // old jsoup used to wrap this in <ul>, but that's not to spec
        var h = "<li>Point one<li>Point two";
        var doc = Jsoup.parse(h);
        var ol = doc.select("ul"); // should NOT have created a default ul.
        Assert.equals(0, ol.size);
        var lis = doc.select("li");
        Assert.equals(2, lis.size);
        Assert.equals("body", lis.first().parent().getTagName());

        // no fiddling with non-implicit lists
        var h2 = "<ol><li><p>Point the first<li><p>Point the second";
        var doc2 = Jsoup.parse(h2);

        Assert.equals(0, doc2.select("ul").size);
        Assert.equals(1, doc2.select("ol").size);
        Assert.equals(2, doc2.select("ol li").size);
        Assert.equals(2, doc2.select("ol li p").size);
        Assert.equals(1, doc2.select("ol li").get(0).children().size); // one p in first li
    }

    public function testDiscardsNakedTds() {
        // jsoup used to make this into an implicit table; but browsers make it into a text run
        var h = "<td>Hello<td><p>There<p>now";
        var doc = Jsoup.parse(h);
        Assert.equals("Hello<p>There</p><p>now</p>", TextUtil.stripNewlines(doc.body().getHtml()));
        // <tbody> is introduced if no implicitly creating table, but allows tr to be directly under table
    }

    public function testHandlesNestedImplicitTable() {
        var doc = Jsoup.parse("<table><td>1</td></tr> <td>2</td></tr> <td> <table><td>3</td> <td>4</td></table> <tr><td>5</table>");
        Assert.equals("<table><tbody><tr><td>1</td></tr> <tr><td>2</td></tr> <tr><td> <table><tbody><tr><td>3</td> <td>4</td></tr></tbody></table> </td></tr><tr><td>5</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesWhatWgExpensesTableExample() {
        // http://www.whatwg.org/specs/web-apps/current-work/multipage/tabular-data.html#examples-0
        var doc = Jsoup.parse("<table> <colgroup> <col> <colgroup> <col> <col> <col> <thead> <tr> <th> <th>2008 <th>2007 <th>2006 <tbody> <tr> <th scope=rowgroup> Research and development <td> $ 1,109 <td> $ 782 <td> $ 712 <tr> <th scope=row> Percentage of net sales <td> 3.4% <td> 3.3% <td> 3.7% <tbody> <tr> <th scope=rowgroup> Selling, general, and administrative <td> $ 3,761 <td> $ 2,963 <td> $ 2,433 <tr> <th scope=row> Percentage of net sales <td> 11.6% <td> 12.3% <td> 12.6% </table>");
        Assert.equals("<table> <colgroup> <col> </colgroup><colgroup> <col> <col> <col> </colgroup><thead> <tr> <th> </th><th>2008 </th><th>2007 </th><th>2006 </th></tr></thead><tbody> <tr> <th scope=\"rowgroup\"> Research and development </th><td> $ 1,109 </td><td> $ 782 </td><td> $ 712 </td></tr><tr> <th scope=\"row\"> Percentage of net sales </th><td> 3.4% </td><td> 3.3% </td><td> 3.7% </td></tr></tbody><tbody> <tr> <th scope=\"rowgroup\"> Selling, general, and administrative </th><td> $ 3,761 </td><td> $ 2,963 </td><td> $ 2,433 </td></tr><tr> <th scope=\"row\"> Percentage of net sales </th><td> 11.6% </td><td> 12.3% </td><td> 12.6% </td></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesTbodyTable() {
        var doc = Jsoup.parse("<html><head></head><body><table><tbody><tr><td>aaa</td><td>bbb</td></tr></tbody></table></body></html>");
        Assert.equals("<table><tbody><tr><td>aaa</td><td>bbb</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesImplicitCaptionClose() {
        var doc = Jsoup.parse("<table><caption>A caption<td>One<td>Two");
        Assert.equals("<table><caption>A caption</caption><tbody><tr><td>One</td><td>Two</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testnoTableDirectInTable() {
        var doc = Jsoup.parse("<table> <td>One <td><table><td>Two</table> <table><td>Three");
        Assert.equals("<table> <tbody><tr><td>One </td><td><table><tbody><tr><td>Two</td></tr></tbody></table> <table><tbody><tr><td>Three</td></tr></tbody></table></td></tr></tbody></table>",
                TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testIgnoresDupeEndTrTag() {
        var doc = Jsoup.parse("<table><tr><td>One</td><td><table><tr><td>Two</td></tr></tr></table></td><td>Three</td></tr></table>"); // two </tr></tr>, must ignore or will close table
        Assert.equals("<table><tbody><tr><td>One</td><td><table><tbody><tr><td>Two</td></tr></tbody></table></td><td>Three</td></tr></tbody></table>",
                TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesBaseTags() {
        // only listen to the first base href
        var h = "<a href=1>#</a><base href='/2/'><a href='3'>#</a><base href='http://bar'><a href=/4>#</a>";
        var doc = Jsoup.parse(h, "http://foo/");
        Assert.equals("http://foo/2/", doc.getBaseUri()); // gets set once, so doc and descendants have first only

        var anchors = doc.getElementsByTag("a");
        Assert.equals(3, anchors.size);

        Assert.equals("http://foo/2/", anchors.get(0).getBaseUri());
        Assert.equals("http://foo/2/", anchors.get(1).getBaseUri());
        Assert.equals("http://foo/2/", anchors.get(2).getBaseUri());

        Assert.equals("http://foo/2/1", anchors.get(0).absUrl("href"));
        Assert.equals("http://foo/2/3", anchors.get(1).absUrl("href"));
        Assert.equals("http://foo/4", anchors.get(2).absUrl("href"));
    }

    public function testHandlesProtocolRelativeUrl() {
        var base = "https://example.com/";
        var html = "<img src='//example.net/img.jpg'>";
        var doc = Jsoup.parse(html, base);
        var el = doc.select("img").first();
        Assert.equals("https://example.net/img.jpg", el.absUrl("src"));
    }

    public function testHandlesCdata() {
        // todo: as this is html namespace, should actually treat as bogus comment, not cdata. keep as cdata for now
        var h = "<div id=1><![CDATA[<html>\n<foo><&amp;]]></div>"; // the &amp; in there should remain literal
        var doc = Jsoup.parse(h);
        var div = doc.getElementById("1");
        Assert.equals("<html> <foo><&amp;", div.getText());
        Assert.equals(0, div.children().size);
        Assert.equals(1, div.childNodeSize()); // no elements, one text node
    }

    public function testHandlesUnclosedCdataAtEOF() {
        // https://github.com/jhy/jsoup/issues/349 would crash, as character reader would try to seek past EOF
        var h = "<![CDATA[]]";
        var doc = Jsoup.parse(h);
        Assert.equals(1, doc.body().childNodeSize());
    }

    public function testHandlesInvalidStartTags() {
        var h = "<div>Hello < There <&amp;></div>"; // parse to <div {#text=Hello < There <&>}>
        var doc = Jsoup.parse(h);
        Assert.equals("Hello < There <&>", doc.select("div").first().getText());
    }

    public function testHandlesUnknownTags() {
        var h = "<div><foo title=bar>Hello<foo title=qux>there</foo></div>";
        var doc = Jsoup.parse(h);
        var foos = doc.select("foo");
        Assert.equals(2, foos.size);
        Assert.equals("bar", foos.first().getAttr("title"));
        Assert.equals("qux", foos.last().getAttr("title"));
        Assert.equals("there", foos.last().getText());
    }

    public function testPandlesUnknownInlineTags() {
        var h = "<p><cust>Test</cust></p><p><cust><cust>Test</cust></cust></p>";
        var doc = Jsoup.parseBodyFragment(h);
        var out = doc.body().getHtml();
        Assert.equals(h, TextUtil.stripNewlines(out));
    }

    public function testParsesBodyFragment() {
        var h = "<!-- comment --><p><a href='foo'>One</a></p>";
        var doc = Jsoup.parseBodyFragment(h, "http://example.com");
        Assert.equals("<body><!-- comment --><p><a href=\"foo\">One</a></p></body>", TextUtil.stripNewlines(doc.body().outerHtml()));
        Assert.equals("http://example.com/foo", doc.select("a").first().absUrl("href"));
    }

    public function testHandlesUnknownNamespaceTags() {
        // note that the first foo:bar should not really be allowed to be self closing, if parsed in html mode.
        var h = "<foo:bar id='1' /><abc:def id=2>Foo<p>Hello</p></abc:def><foo:bar>There</foo:bar>";
        var doc = Jsoup.parse(h);
        Assert.equals("<foo:bar id=\"1\" /><abc:def id=\"2\">Foo<p>Hello</p></abc:def><foo:bar>There</foo:bar>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesKnownEmptyBlocks() {
        // if a known tag, allow self closing outside of spec, but force an end tag. unknown tags can be self closing.
        var h = "<div id='1' /><script src='/foo' /><div id=2><img /><img></div><a id=3 /><i /><foo /><foo>One</foo> <hr /> hr text <hr> hr text two";
        var doc = Jsoup.parse(h);
        Assert.equals("<div id=\"1\"></div><script src=\"/foo\"></script><div id=\"2\"><img><img></div><a id=\"3\"></a><i></i><foo /><foo>One</foo> <hr> hr text <hr> hr text two", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesSolidusAtAttributeEnd() {
        // this test makes sure [<a href=/>link</a>] is parsed as [<a href="/">link</a>], not [<a href="" /><a>link</a>]
        var h = "<a href=/>link</a>";
        var doc = Jsoup.parse(h);
        Assert.equals("<a href=\"/\">link</a>", doc.body().getHtml());
    }

    public function testHandlesMultiClosingBody() {
        var h = "<body><p>Hello</body><p>there</p></body></body></html><p>now";
        var doc = Jsoup.parse(h);
        Assert.equals(3, doc.select("p").size);
        Assert.equals(3, doc.body().children().size);
    }

    public function testHandlesUnclosedDefinitionLists() {
        // jsoup used to create a <dl>, but that's not to spec
        var h = "<dt>Foo<dd>Bar<dt>Qux<dd>Zug";
        var doc = Jsoup.parse(h);
        Assert.equals(0, doc.select("dl").size); // no auto dl
        Assert.equals(4, doc.select("dt, dd").size);
        var dts = doc.select("dt");
        Assert.equals(2, dts.size);
        Assert.equals("Zug", dts.get(1).nextElementSibling().getText());
    }

    public function testHandlesBlocksInDefinitions() {
        // per the spec, dt and dd are inline, but in practise are block
        var h = "<dl><dt><div id=1>Term</div></dt><dd><div id=2>Def</div></dd></dl>";
        var doc = Jsoup.parse(h);
        Assert.equals("dt", doc.select("#1").first().parent().getTagName());
        Assert.equals("dd", doc.select("#2").first().parent().getTagName());
        Assert.equals("<dl><dt><div id=\"1\">Term</div></dt><dd><div id=\"2\">Def</div></dd></dl>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesFrames() {
        var h = "<html><head><script></script><noscript></noscript></head><frameset><frame src=foo></frame><frame src=foo></frameset></html>";
        var doc = Jsoup.parse(h);
        Assert.equals("<html><head><script></script><noscript></noscript></head><frameset><frame src=\"foo\"><frame src=\"foo\"></frameset></html>",
                TextUtil.stripNewlines(doc.getHtml()));
        // no body auto vivification
    }
    
    public function testIgnoresContentAfterFrameset() {
        var h = "<html><head><title>One</title></head><frameset><frame /><frame /></frameset><table></table></html>";
        var doc = Jsoup.parse(h);
        Assert.equals("<html><head><title>One</title></head><frameset><frame><frame></frameset></html>", TextUtil.stripNewlines(doc.getHtml()));
        // no body, no table. No crash!
    }

    public function testHandlesJavadocFont() {
        var h = "<TD BGCOLOR=\"#EEEEFF\" CLASS=\"NavBarCell1\">    <A HREF=\"deprecated-list.html\"><FONT CLASS=\"NavBarFont1\"><B>Deprecated</B></FONT></A>&nbsp;</TD>";
        var doc = Jsoup.parse(h);
        var a = doc.select("a").first();
        Assert.equals("Deprecated", a.getText());
        Assert.equals("font", a.child(0).getTagName());
        Assert.equals("b", a.child(0).child(0).getTagName());
    }

    public function testHandlesBaseWithoutHref() {
        var h = "<head><base target='_blank'></head><body><a href=/foo>Test</a></body>";
        var doc = Jsoup.parse(h, "http://example.com/");
        var a = doc.select("a").first();
        Assert.equals("/foo", a.getAttr("href"));
        Assert.equals("http://example.com/foo", a.getAttr("abs:href"));
    }

    public function testNormalisesDocument() {
        var h = "<!doctype html>One<html>Two<head>Three<link></head>Four<body>Five </body>Six </html>Seven ";
        var doc = Jsoup.parse(h);
        Assert.equals("<!doctype html><html><head></head><body>OneTwoThree<link>FourFive Six Seven </body></html>",
                TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testNormalisesEmptyDocument() {
        var doc = Jsoup.parse("");
        Assert.equals("<html><head></head><body></body></html>", TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testNormalisesHeadlessBody() {
        var doc = Jsoup.parse("<html><body><span class=\"foo\">bar</span>");
        Assert.equals("<html><head></head><body><span class=\"foo\">bar</span></body></html>",
                TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testNormalisedBodyAfterContent() {
        var doc = Jsoup.parse("<font face=Arial><body class=name><div>One</div></body></font>");
        Assert.equals("<html><head></head><body class=\"name\"><font face=\"Arial\"><div>One</div></font></body></html>",
                TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testFindsCharsetInMalformedMeta() {
        var h = "<meta http-equiv=Content-Type content=text/html; charset=gb2312>";
        // example cited for reason of html5's <meta charset> element
        var doc = Jsoup.parse(h);
        Assert.equals("gb2312", doc.select("meta").getAttr("charset"));
    }

    public function testHgroup() {
        // jsoup used to not allow hroup in h{n}, but that's not in spec, and browsers are OK
        var doc = Jsoup.parse("<h1>Hello <h2>There <hgroup><h1>Another<h2>headline</hgroup> <hgroup><h1>More</h1><p>stuff</p></hgroup>");
        Assert.equals("<h1>Hello </h1><h2>There <hgroup><h1>Another</h1><h2>headline</h2></hgroup> <hgroup><h1>More</h1><p>stuff</p></hgroup></h2>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testRelaxedTags() {
        var doc = Jsoup.parse("<abc_def id=1>Hello</abc_def> <abc-def>There</abc-def>");
        Assert.equals("<abc_def id=\"1\">Hello</abc_def> <abc-def>There</abc-def>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHeaderContents() {
        // h* tags (h1 .. h9) in browsers can handle any internal content other than other h*. which is not per any
        // spec, which defines them as containing phrasing content only. so, reality over theory.
        var doc = Jsoup.parse("<h1>Hello <div>There</div> now</h1> <h2>More <h3>Content</h3></h2>");
        Assert.equals("<h1>Hello <div>There</div> now</h1> <h2>More </h2><h3>Content</h3>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testSpanContents() {
        // like h1 tags, the spec says SPAN is phrasing only, but browsers and publisher treat span as a block tag
        var doc = Jsoup.parse("<span>Hello <div>there</div> <span>now</span></span>");
        Assert.equals("<span>Hello <div>there</div> <span>now</span></span>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testNoImagesInNoScriptInHead() {
        // jsoup used to allow, but against spec if parsing with noscript
        var doc = Jsoup.parse("<html><head><noscript><img src='foo'></noscript></head><body><p>Hello</p></body></html>");
        Assert.equals("<html><head><noscript>&lt;img src=\"foo\"&gt;</noscript></head><body><p>Hello</p></body></html>", TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testAFlowContents() {
        // html5 has <a> as either phrasing or block
        var doc = Jsoup.parse("<a>Hello <div>there</div> <span>now</span></a>");
        Assert.equals("<a>Hello <div>there</div> <span>now</span></a>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testFontFlowContents() {
        // html5 has no definition of <font>; often used as flow
        var doc = Jsoup.parse("<font>Hello <div>there</div> <span>now</span></font>");
        Assert.equals("<font>Hello <div>there</div> <span>now</span></font>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesMisnestedTagsBI() {
        // whatwg: <b><i></b></i>
        var h = "<p>1<b>2<i>3</b>4</i>5</p>";
        var doc = Jsoup.parse(h);
        Assert.equals("<p>1<b>2<i>3</i></b><i>4</i>5</p>", doc.body().getHtml());
        // adoption agency on </b>, reconstruction of formatters on 4.
    }

    public function testHandlesMisnestedTagsBP() {
        //  whatwg: <b><p></b></p>
        var h = "<b>1<p>2</b>3</p>";
        var doc = Jsoup.parse(h);
        Assert.equals("<b>1</b>\n<p><b>2</b>3</p>", doc.body().getHtml());
    }

    public function testHandlesUnexpectedMarkupInTables() {
        // whatwg - tests markers in active formatting (if they didn't work, would get in in table)
        // also tests foster parenting
        var h = "<table><b><tr><td>aaa</td></tr>bbb</table>ccc";
        var doc = Jsoup.parse(h);
        Assert.equals("<b></b><b>bbb</b><table><tbody><tr><td>aaa</td></tr></tbody></table><b>ccc</b>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesUnclosedFormattingElements() {
        // whatwg: formatting var get collected and applied, but excess var are thrown away
        var h = "<!DOCTYPE html>\n" +
                "<p><b class=x><b class=x><b><b class=x><b class=x><b>X\n" +
                "<p>X\n" +
                "<p><b><b class=x><b>X\n" +
                "<p></b></b></b></b></b></b>X";
        var doc = Jsoup.parse(h);
        doc.getOutputSettings().setIndentAmount(0);
        var want = "<!doctype html>\n" +
                "<html>\n" +
                "<head></head>\n" +
                "<body>\n" +
                "<p><b class=\"x\"><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b>X </b></b></b></b></b></b></p>\n" +
                "<p><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b>X </b></b></b></b></b></p>\n" +
                "<p><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b><b><b class=\"x\"><b>X </b></b></b></b></b></b></b></b></p>\n" +
                "<p>X</p>\n" +
                "</body>\n" +
                "</html>";
        Assert.equals(want, doc.getHtml());
    }

    public function testHandlesUnclosedAnchors() {
        var h = "<a href='http://example.com/'>Link<p>Error link</a>";
        var doc = Jsoup.parse(h);
        var want = "<a href=\"http://example.com/\">Link</a>\n<p><a href=\"http://example.com/\">Error link</a></p>";
        Assert.equals(want, doc.body().getHtml());
    }

    public function testReconstructFormattingElements() {
        // tests attributes and multi b
        var h = "<p><b class=one>One <i>Two <b>Three</p><p>Hello</p>";
        var doc = Jsoup.parse(h);
        Assert.equals("<p><b class=\"one\">One <i>Two <b>Three</b></i></b></p>\n<p><b class=\"one\"><i><b>Hello</b></i></b></p>", doc.body().getHtml());
    }

    public function testReconstructFormattingElementsInTable() {
        // tests that tables get formatting markers -- the <b> applies outside the table and does not leak in,
        // and the <i> inside the table and does not leak out.
        var h = "<p><b>One</p> <table><tr><td><p><i>Three<p>Four</i></td></tr></table> <p>Five</p>";
        var doc = Jsoup.parse(h);
        var want = "<p><b>One</b></p>\n" +
                "<b> \n" +
                " <table>\n" +
                "  <tbody>\n" +
                "   <tr>\n" +
                "    <td><p><i>Three</i></p><p><i>Four</i></p></td>\n" +
                "   </tr>\n" +
                "  </tbody>\n" +
                " </table> <p>Five</p></b>";
        Assert.equals(want, doc.body().getHtml());
    }

    public function testCommentBeforeHtml() {
        var h = "<!-- comment --><!-- comment 2 --><p>One</p>";
        var doc = Jsoup.parse(h);
        Assert.equals("<!-- comment --><!-- comment 2 --><html><head></head><body><p>One</p></body></html>", TextUtil.stripNewlines(doc.getHtml()));
    }

    public function testEmptyTdTag() {
        var h = "<table><tr><td>One</td><td id='2' /></tr></table>";
        var doc = Jsoup.parse(h);
        Assert.equals("<td>One</td>\n<td id=\"2\"></td>", doc.select("tr").first().getHtml());
    }

    public function testHandlesSolidusInA() {
        // test for bug #66
        var h = "<a class=lp href=/lib/14160711/>link text</a>";
        var doc = Jsoup.parse(h);
        var a = doc.select("a").first();
        Assert.equals("link text", a.getText());
        Assert.equals("/lib/14160711/", a.getAttr("href"));
    }

    public function testHandlesSpanInTbody() {
        // test for bug 64
        var h = "<table><tbody><span class='1'><tr><td>One</td></tr><tr><td>Two</td></tr></span></tbody></table>";
        var doc = Jsoup.parse(h);
        Assert.equals(doc.select("span").first().children().size, 0); // the span gets closed
        Assert.equals(doc.select("table").size, 1); // only one table
    }

    public function testHandlesUnclosedTitleAtEof() {
        Assert.equals("Data", Jsoup.parse("<title>Data").getTitle());
        Assert.equals("Data<", Jsoup.parse("<title>Data<").getTitle());
        Assert.equals("Data</", Jsoup.parse("<title>Data</").getTitle());
        Assert.equals("Data</t", Jsoup.parse("<title>Data</t").getTitle());
        Assert.equals("Data</ti", Jsoup.parse("<title>Data</ti").getTitle());
        Assert.equals("Data", Jsoup.parse("<title>Data</title>").getTitle());
        Assert.equals("Data", Jsoup.parse("<title>Data</title >").getTitle());
    }

    public function testHandlesUnclosedTitle() {
        var one = Jsoup.parse("<title>One <b>Two <b>Three</TITLE><p>Test</p>"); // has title, so <b> is plain text
        Assert.equals("One <b>Two <b>Three", one.getTitle());
        Assert.equals("Test", one.select("p").first().getText());

        var two = Jsoup.parse("<title>One<b>Two <p>Test</p>"); // no title, so <b> causes </title> breakout
        Assert.equals("One", two.getTitle());
        Assert.equals("<b>Two <p>Test</p></b>", two.body().getHtml());
    }

    public function testHandlesUnclosedScriptAtEof() {
        Assert.equals("Data", Jsoup.parse("<script>Data").select("script").first().data());
        Assert.equals("Data<", Jsoup.parse("<script>Data<").select("script").first().data());
        Assert.equals("Data</sc", Jsoup.parse("<script>Data</sc").select("script").first().data());
        Assert.equals("Data</-sc", Jsoup.parse("<script>Data</-sc").select("script").first().data());
        Assert.equals("Data</sc-", Jsoup.parse("<script>Data</sc-").select("script").first().data());
        Assert.equals("Data</sc--", Jsoup.parse("<script>Data</sc--").select("script").first().data());
        Assert.equals("Data", Jsoup.parse("<script>Data</script>").select("script").first().data());
        Assert.equals("Data</script", Jsoup.parse("<script>Data</script").select("script").first().data());
        Assert.equals("Data", Jsoup.parse("<script>Data</script ").select("script").first().data());
        Assert.equals("Data", Jsoup.parse("<script>Data</script n").select("script").first().data());
        Assert.equals("Data", Jsoup.parse("<script>Data</script n=").select("script").first().data());
        Assert.equals("Data", Jsoup.parse("<script>Data</script n=\"").select("script").first().data());
        Assert.equals("Data", Jsoup.parse("<script>Data</script n=\"p").select("script").first().data());
    }

    public function testHandlesUnclosedRawtextAtEof() {
        Assert.equals("Data", Jsoup.parse("<style>Data").select("style").first().data());
        Assert.equals("Data</st", Jsoup.parse("<style>Data</st").select("style").first().data());
        Assert.equals("Data", Jsoup.parse("<style>Data</style>").select("style").first().data());
        Assert.equals("Data</style", Jsoup.parse("<style>Data</style").select("style").first().data());
        Assert.equals("Data</-style", Jsoup.parse("<style>Data</-style").select("style").first().data());
        Assert.equals("Data</style-", Jsoup.parse("<style>Data</style-").select("style").first().data());
        Assert.equals("Data</style--", Jsoup.parse("<style>Data</style--").select("style").first().data());
    }

    public function testNoImplicitFormForTextAreas() {
        // old jsoup parser would create implicit forms for form children like <textarea>, but no more
        var doc = Jsoup.parse("<textarea>One</textarea>");
        Assert.equals("<textarea>One</textarea>", doc.body().getHtml());
    }

    public function testHandlesEscapedScript() {
        var doc = Jsoup.parse("<script><!-- one <script>Blah</script> --></script>");
        Assert.equals("<!-- one <script>Blah</script> -->", doc.select("script").first().data());
    }

    public function testHandles0CharacterAsText() {
        var doc = Jsoup.parse("0<p>0</p>");
        Assert.equals("0\n<p>0</p>", doc.body().getHtml());
    }

    public function testHandlesNullInData() {
        var doc = Jsoup.parse("<p id=\u0000>Blah \u0000</p>");
        Assert.equals("<p id=\"\uFFFD\">Blah \u0000</p>", doc.body().getHtml()); // replaced in attr, NOT replaced in data
    }

    public function testHandlesNullInComments() {
        var doc = Jsoup.parse("<body><!-- \u0000 \u0000 -->");
        Assert.equals("<!-- \uFFFD \uFFFD -->", doc.body().getHtml());
    }

    public function testHandlesNewlinesAndWhitespaceInTag() {
		var sb = new StringBuilder();
		sb.add("<a \n href=\"one\" \r\n id=\"two\" ");
		sb.addChar(0xC/*\f*/);
		sb.add(" >");
        var doc = Jsoup.parse(sb.toString());
        Assert.equals("<a href=\"one\" id=\"two\"></a>", doc.body().getHtml());
    }

    public function testHandlesWhitespaceInoDocType() {
        var html = "<!DOCTYPE html\r\n" +
                "      PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\r\n" +
                "      \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">";
        var doc = Jsoup.parse(html);
        Assert.equals("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">", doc.childNode(0).outerHtml());
    }
    
    public function testTracksErrorsWhenRequested() {
        var html = "<p>One</p href='no'><!DOCTYPE html>&arrgh;<font /><br /><foo";
        var parser = Parser.htmlParser().setTrackErrors(500);
        var doc = Jsoup.parse(html, "http://example.com", parser);
        
        var errors:List<ParseError> = parser.getErrors();
        Assert.equals(5, errors.size);
        Assert.equals("20: Attributes incorrectly present on end tag", errors.get(0).toString());
		Assert.equals('35: Unexpected token [${new TokenDoctype().tokenType()}] when in state [${HtmlTreeBuilderState.InBody}]', errors.get(1).toString());
        Assert.equals("36: Invalid character reference: invalid named reference 'arrgh'", errors.get(2).toString());
        Assert.equals("50: Self closing flag not acknowledged", errors.get(3).toString());
        Assert.equals("61: Unexpectedly reached end of file (EOF) in input state [TagName]", errors.get(4).toString());
    }

    public function testTracksLimitedErrorsWhenRequested() {
        var html = "<p>One</p href='no'><!DOCTYPE html>&arrgh;<font /><br /><foo";
        var parser = Parser.htmlParser().setTrackErrors(3);
        var doc = parser.parseInput(html, "http://example.com");

        var errors:List<ParseError> = parser.getErrors();
        Assert.equals(3, errors.size);
        Assert.equals("20: Attributes incorrectly present on end tag", errors.get(0).toString());
		Assert.equals('35: Unexpected token [${new TokenDoctype().tokenType()}] when in state [${HtmlTreeBuilderState.InBody}]', errors.get(1).toString());
        Assert.equals("36: Invalid character reference: invalid named reference 'arrgh'", errors.get(2).toString());
    }

    public function testNoErrorsByDefault() {
        var html = "<p>One</p href='no'>&arrgh;<font /><br /><foo";
        var parser = Parser.htmlParser();
        var doc = Jsoup.parse(html, "http://example.com", parser);

        var errors:List<ParseError> = parser.getErrors();
        Assert.equals(0, errors.size);
    }
    
    public function testHandlesCommentsInTable() {
        var html = "<table><tr><td>text</td><!-- Comment --></tr></table>";
        var node = Jsoup.parseBodyFragment(html);
        Assert.equals("<html><head></head><body><table><tbody><tr><td>text</td><!-- Comment --></tr></tbody></table></body></html>", TextUtil.stripNewlines(node.outerHtml()));
    }

    public function testHandlesQuotesInCommentsInScripts() {
        var html = "<script>\n" +
                "  <!--\n" +
                "    document.write('</scr' + 'ipt>');\n" +
                "  // -->\n" +
                "</script>";
        var node = Jsoup.parseBodyFragment(html);
        Assert.equals("<script>\n" +
                "  <!--\n" +
                "    document.write('</scr' + 'ipt>');\n" +
                "  // -->\n" +
                "</script>", node.body().getHtml());
    }

    public function testHandleNullContextInParseFragment() {
        var html = "<ol><li>One</li></ol><p>Two</p>";
        var nodes = Parser.parseFragment(html, null, "http://example.com/");
        Assert.equals(1, nodes.size); // returns <html> node (not document) -- no context means doc gets created
        Assert.equals("html", nodes.get(0).nodeName());
        Assert.equals("<html> <head></head> <body> <ol> <li>One</li> </ol> <p>Two</p> </body> </html>", StringUtil.normaliseWhitespace(nodes.get(0).outerHtml()));
    }

    public function testDoesNotFindShortestMatchingEntity() {
        // previous behaviour was to identify a possible entity, then chomp down the var until a match was found.
        // (as defined in html5.) However in practise that lead to spurious matches against the author's intent.
        var html = "One &clubsuite; &clubsuit;";
        var doc = Jsoup.parse(html);
        Assert.equals(StringUtil.normaliseWhitespace("One &amp;clubsuite; ♣"), doc.body().getHtml());
    }

    public function testRelaxedBaseEntityMatchAndStrictExtendedMatch() {
        // extended entities need a ; at the end to match, base does not
        var html = "&amp &quot &reg &icy &hopf &icy; &hopf;";
        var doc = Jsoup.parse(html);
        doc.getOutputSettings().setEscapeMode(EscapeMode.extended).setCharset("ascii"); // modifies output only to clarify test
        Assert.equals("&amp; \" &reg; &amp;icy &amp;hopf &icy; &hopf;", doc.body().getHtml());
    }

    public function testHandlesXmlDeclarationAsBogusComment() {
        var html = "<?xml encoding='UTF-8' ?><body>One</body>";
        var doc = Jsoup.parse(html);
        Assert.equals("<!--?xml encoding='UTF-8' ?--> <html> <head></head> <body> One </body> </html>", StringUtil.normaliseWhitespace(doc.outerHtml()));
    }

    public function testHandlesTagsInTextarea() {
        var html = "<textarea><p>Jsoup</p></textarea>";
        var doc = Jsoup.parse(html);
        Assert.equals("<textarea>&lt;p&gt;Jsoup&lt;/p&gt;</textarea>", doc.body().getHtml());
    }

    // form tests
    public function testCreatesFormElements() {
        var html = "<body><form><input id=1><input id=2></form></body>";
        var doc = Jsoup.parse(html);
        var el = doc.select("form").first();

        Assert.isTrue(Std.is(el, FormElement), "Is form element");
        var form:FormElement = cast el;
        var controls = form.getElements();
        Assert.equals(2, controls.size);
        Assert.equals("1", controls.get(0).id());
        Assert.equals("2", controls.get(1).id());
    }

    public function testAssociatedFormControlsWithDisjointForms() {
        // form gets closed, isn't parent of controls
        var html = "<table><tr><form><input type=hidden id=1><td><input type=text id=2></td><tr></table>";
        var doc = Jsoup.parse(html);
        var el = doc.select("form").first();

        Assert.isTrue(Std.is(el, FormElement), "Is form element");
        var form:FormElement = cast el;
        var controls = form.getElements();
        Assert.equals(2, controls.size);
        Assert.equals("1", controls.get(0).id());
        Assert.equals("2", controls.get(1).id());

        Assert.equals("<table><tbody><tr><form></form><input type=\"hidden\" id=\"1\"><td><input type=\"text\" id=\"2\"></td></tr><tr></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHandlesInputInTable() {
        var h = "<body>\n" +
                "<input type=\"hidden\" name=\"a\" value=\"\">\n" +
                "<table>\n" +
                "<input type=\"hidden\" name=\"b\" value=\"\" />\n" +
                "</table>\n" +
                "</body>";
        var doc = Jsoup.parse(h);
        Assert.equals(1, doc.select("table input").size);
        Assert.equals(2, doc.select("input").size);
    }

    public function testConvertsImageToImg() {
        // image to img, unless in a svg. old html cruft.
        var h = "<body><image><svg><image /></svg></body>";
        var doc = Jsoup.parse(h);
        Assert.equals("<img>\n<svg>\n <image />\n</svg>", doc.body().getHtml());
    }

    public function testHandlesInvalidDoctypes() {
        // would previously throw invalid name exception on empty doctype
        var doc = Jsoup.parse("<!DOCTYPE>");
        Assert.equals(
                "<!doctype> <html> <head></head> <body></body> </html>",
                StringUtil.normaliseWhitespace(doc.outerHtml()));

        doc = Jsoup.parse("<!DOCTYPE><html><p>Foo</p></html>");
        Assert.equals(
                "<!doctype> <html> <head></head> <body> <p>Foo</p> </body> </html>",
                StringUtil.normaliseWhitespace(doc.outerHtml()));

        doc = Jsoup.parse("<!DOCTYPE \u0000>");
        Assert.equals(
                "<!doctype �> <html> <head></head> <body></body> </html>",
                StringUtil.normaliseWhitespace(doc.outerHtml()));
    }
	
	
    //NOTE(az): azz!... timing
    public function testHandlesManyChildren() {
        // Arrange
        var longBody = new StringBuilder(/*500000*/);
        for (i in 0...25000) {
            longBody.add(i);
			longBody.add("<br>");
        }
        
        // Act
        var start = Timer.stamp();
        var doc = Parser.parseBodyFragment(longBody.toString(), "");
        
        // Assert
        Assert.equals(50000, doc.body().childNodeSize());
        Assert.isTrue(Timer.stamp() - start < 1000);
    }

    public function testInvalidTableContents() {
        var resource = ParseTest.getFile("htmltests/table-invalid-elements.html");
        var doc = Jsoup.parse(resource, "UTF-8");
        doc.getOutputSettings().setPrettyPrint(true);
        var rendered = doc.toString();
        var endOfEmail:Int = rendered.indexOf("Comment");
        var guarantee:Int = rendered.indexOf("Why am I here?");
        Assert.isTrue(endOfEmail > -1, "Comment not found");
        Assert.isTrue(guarantee > -1, "Search text not found");
        Assert.isTrue(guarantee > endOfEmail, "Search text did not come after comment");
    }

    public function testNormalisesIsIndex() {
        var doc = Jsoup.parse("<body><isindex action='/submit'></body>");
        var html = doc.outerHtml();
        Assert.equals("<form action=\"/submit\"> <hr> <label>This is a searchable index. Enter search keywords: <input name=\"isindex\"></label> <hr> </form>",
                StringUtil.normaliseWhitespace(doc.body().getHtml()));
    }

    public function testReinsertionModeForThCelss() {
        var body = "<body> <table> <tr> <th> <table><tr><td></td></tr></table> <div> <table><tr><td></td></tr></table> </div> <div></div> <div></div> <div></div> </th> </tr> </table> </body>";
        var doc = Jsoup.parse(body);
        Assert.equals(1, doc.body().children().size);
    }
}
