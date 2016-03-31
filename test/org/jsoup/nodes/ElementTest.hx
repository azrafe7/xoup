package org.jsoup.nodes;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import org.jsoup.Jsoup;
import org.jsoup.TextUtil;
import org.jsoup.helper.StringUtil;
import org.jsoup.parser.Tag;
import org.jsoup.select.Elements;

import utest.Assert;

/*import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.Map;
*/

/**
 * Tests for Element (DOM stuff mostly).
 *
 * @author Jonathan Hedley
 */
class ElementTest {
    private var reference:String = "<div id=div1><p>Hello</p><p>Another <b>element</b></p><div id=div2><img src=foo.png></div></div>";

	
	public function new() {}
	
    public function testGetElementsByTagName() {
		var doc = Jsoup.parse(reference);
        var divs:List<Element> = doc.getElementsByTag("div");
        Assert.equals(2, divs.size);
        Assert.equals("div1", divs.get(0).id());
        Assert.equals("div2", divs.get(1).id());

        var ps:List<Element> = doc.getElementsByTag("p");
        Assert.equals(2, ps.size);
		var tn:TextNode;
        Assert.equals("Hello", (tn = cast ps.get(0).childNode(0)).getWholeText());
        Assert.equals("Another ", (tn = cast ps.get(1).childNode(0)).getWholeText());
        var ps2:List<Element> = doc.getElementsByTag("P");
        Assert.equals(Std.string(ps), Std.string(ps2)); // compare contents

        var imgs:List<Element> = doc.getElementsByTag("img");
        Assert.equals("foo.png", imgs.get(0).getAttr("src"));

        var empty:List<Element> = doc.getElementsByTag("wtf");
        Assert.equals(0, empty.size);
    }
    
    public function testGetNamespacedElementsByTag() {
        var doc = Jsoup.parse("<div><abc:def id=1>Hello</abc:def></div>");
        var els = doc.getElementsByTag("abc:def");
        Assert.equals(1, els.size);
        Assert.equals("1", els.first().id());
        Assert.equals("abc:def", els.first().getTagName());
    }

    public function testGetElementById() {
        var doc = Jsoup.parse(reference);
        var div:Element = doc.getElementById("div1");
        Assert.equals("div1", div.id());
        Assert.isNull(doc.getElementById("none"));

        var doc2 = Jsoup.parse("<div id=1><div id=2><p>Hello <span id=2>world!</span></p></div></div>");
        var div2 = doc2.getElementById("2");
        Assert.equals("div", div2.getTagName()); // not the span
        var span = div2.child(0).getElementById("2"); // called from <p> context should be span
        Assert.equals("span", span.getTagName());
    }
    
    public function testGetText() {
        var doc = Jsoup.parse(reference);
        Assert.equals("Hello Another element", doc.getText());
        Assert.equals("Another element", doc.getElementsByTag("p").get(1).getText());
    }

    public function testGetChildText() {
        var doc = Jsoup.parse("<p>Hello <b>there</b> now");
        var p = doc.select("p").first();
        Assert.equals("Hello there now", p.getText());
        Assert.equals("Hello now", p.ownText());
    }

    public function testNormalisesText() {
        var h = "<p>Hello<p>There.</p> \n <p>Here <b>is</b> \n s<b>om</b>e text.";
        var doc = Jsoup.parse(h);
        var text = doc.getText();
        Assert.equals("Hello There. Here is some text.", text);
    }

    public function testKeepsPreText() {
        var h = "<p>Hello \n \n there.</p> <div><pre>  What's \n\n  that?</pre>";
        var doc = Jsoup.parse(h);
        Assert.equals("Hello there.   What's \n\n  that?", doc.getText());
    }

    public function testKeepsPreTextInCode() {
        var h = "<pre><code>code\n\ncode</code></pre>";
        var doc = Jsoup.parse(h);
        Assert.equals("code\n\ncode", doc.getText());
        Assert.equals("<pre><code>code\n\ncode</code></pre>", doc.body().getHtml());
    }

    public function testBrHasSpace() {
        var doc = Jsoup.parse("<p>Hello<br>there</p>");
        Assert.equals("Hello there", doc.getText());
        Assert.equals("Hello there", doc.select("p").first().ownText());

        doc = Jsoup.parse("<p>Hello <br> there</p>");
        Assert.equals("Hello there", doc.getText());
    }

    public function testGetSiblings() {
        var doc = Jsoup.parse("<div><p>Hello<p id=1>there<p>this<p>is<p>an<p id=last>element</div>");
        var p = doc.getElementById("1");
        Assert.equals("there", p.getText());
        Assert.equals("Hello", p.previousElementSibling().getText());
        Assert.equals("this", p.nextElementSibling().getText());
        Assert.equals("Hello", p.firstElementSibling().getText());
        Assert.equals("element", p.lastElementSibling().getText());
    }

    public function testGetSiblingsWithDuplicateContent() {
        var doc = Jsoup.parse("<div><p>Hello<p id=1>there<p>this<p>this<p>is<p>an<p id=last>element</div>");
        var p = doc.getElementById("1");
        Assert.equals("there", p.getText());
        Assert.equals("Hello", p.previousElementSibling().getText());
        Assert.equals("this", p.nextElementSibling().getText());
        Assert.equals("this", p.nextElementSibling().nextElementSibling().getText());
        Assert.equals("is", p.nextElementSibling().nextElementSibling().nextElementSibling().getText());
        Assert.equals("Hello", p.firstElementSibling().getText());
        Assert.equals("element", p.lastElementSibling().getText());
    }

    public function testGetParents() {
        var doc = Jsoup.parse("<div><p>Hello <span>there</span></div>");
        var span = doc.select("span").first();
        var parents = span.parents();

        Assert.equals(4, parents.size);
        Assert.equals("p", parents.get(0).getTagName());
        Assert.equals("div", parents.get(1).getTagName());
        Assert.equals("body", parents.get(2).getTagName());
        Assert.equals("html", parents.get(3).getTagName());
    }
    
    public function testElementSiblingIndex() {
        var doc = Jsoup.parse("<div><p>One</p>...<p>Two</p>...<p>Three</p>");
        var ps = doc.select("p");
        Assert.isTrue(0 == ps.get(0).elementSiblingIndex());
        Assert.isTrue(1 == ps.get(1).elementSiblingIndex());
        Assert.isTrue(2 == ps.get(2).elementSiblingIndex());
    }

    public function testElementSiblingIndexSameContent() {
        var doc = Jsoup.parse("<div><p>One</p>...<p>One</p>...<p>One</p>");
        var ps = doc.select("p");
        Assert.isTrue(0 == ps.get(0).elementSiblingIndex());
        Assert.isTrue(1 == ps.get(1).elementSiblingIndex());
        Assert.isTrue(2 == ps.get(2).elementSiblingIndex());
    }

    public function testGetElementsWithClass() {
        var doc = Jsoup.parse("<div class='mellow yellow'><span class=mellow>Hello <b class='yellow'>Yellow!</b></span><p>Empty</p></div>");

        var els:List<Element> = doc.getElementsByClass("mellow");
        Assert.equals(2, els.size);
        Assert.equals("div", els.get(0).getTagName());
        Assert.equals("span", els.get(1).getTagName());

        var els2:List<Element> = doc.getElementsByClass("yellow");
        Assert.equals(2, els2.size);
        Assert.equals("div", els2.get(0).getTagName());
        Assert.equals("b", els2.get(1).getTagName());

        var none:List<Element> = doc.getElementsByClass("solo");
        Assert.equals(0, none.size);
    }

    public function testGetElementsWithAttribute() {
        var doc = Jsoup.parse("<div style='bold'><p title=qux><p><b style></b></p></div>");
        var els:List<Element> = doc.getElementsByAttribute("style");
        Assert.equals(2, els.size);
        Assert.equals("div", els.get(0).getTagName());
        Assert.equals("b", els.get(1).getTagName());

        var none = doc.getElementsByAttribute("class");
        Assert.equals(0, none.size);
    }

    public function testGetElementsWithAttributeDash() {
        var doc = Jsoup.parse("<meta http-equiv=content-type value=utf8 id=1> <meta name=foo content=bar id=2> <div http-equiv=content-type value=utf8 id=3>");
        var meta = doc.select("meta[http-equiv=content-type], meta[charset]");
        Assert.equals(1, meta.size);
        Assert.equals("1", meta.first().id());
    }

    public function testGetElementsWithAttributeValue() {
        var doc = Jsoup.parse("<div style='bold'><p><p><b style></b></p></div>");
        var els = doc.getElementsByAttributeValue("style", "bold");
        Assert.equals(1, els.size);
        Assert.equals("div", els.get(0).getTagName());

        var none = doc.getElementsByAttributeValue("style", "none");
        Assert.equals(0, none.size);
    }
    
    public function testClassDomMethods() {
        var doc = Jsoup.parse("<div><span class=' mellow yellow '>Hello <b>Yellow</b></span></div>");
        var els = doc.getElementsByAttribute("class");
        var span = els.get(0);
        Assert.equals("mellow yellow", span.className());
        Assert.isTrue(span.hasClass("mellow"));
        Assert.isTrue(span.hasClass("yellow"));
        var classes = span.getClassNames();
        Assert.equals(2, classes.size);
        Assert.isTrue(classes.contains("mellow"));
        Assert.isTrue(classes.contains("yellow"));

        Assert.equals("", doc.className());
        classes = doc.getClassNames();
        Assert.equals(0, classes.size);
        Assert.isFalse(doc.hasClass("mellow"));
    }

    public function testClassUpdates() {
        var doc = Jsoup.parse("<div class='mellow yellow'></div>");
        var div = doc.select("div").first();

        div.addClass("green");
        Assert.equals("mellow yellow green", div.className());
        div.removeClass("red"); // noop
        div.removeClass("yellow");
        Assert.equals("mellow green", div.className());
        div.toggleClass("green").toggleClass("red");
        Assert.equals("mellow red", div.className());
    }

    public function testOuterHtml() {
        var doc = Jsoup.parse("<div title='Tags &amp;c.'><img src=foo.png><p><!-- comment -->Hello<p>there");
        Assert.equals("<html><head></head><body><div title=\"Tags &amp;c.\"><img src=\"foo.png\"><p><!-- comment -->Hello</p><p>there</p></div></body></html>",
                TextUtil.stripNewlines(doc.outerHtml()));
    }

    public function testInnerHtml() {
        var doc = Jsoup.parse("<div>\n <p>Hello</p> </div>");
        Assert.equals("<p>Hello</p>", doc.getElementsByTag("div").get(0).getHtml());
    }

    public function testFormatHtml() {
        var doc = Jsoup.parse("<title>Format test</title><div><p>Hello <span>jsoup <span>users</span></span></p><p>Good.</p></div>");
        Assert.equals("<html>\n <head>\n  <title>Format test</title>\n </head>\n <body>\n  <div>\n   <p>Hello <span>jsoup <span>users</span></span></p>\n   <p>Good.</p>\n  </div>\n </body>\n</html>", doc.getHtml());
    }
    
    public function testFormatOutline() {
        var doc = Jsoup.parse("<title>Format test</title><div><p>Hello <span>jsoup <span>users</span></span></p><p>Good.</p></div>");
        doc.getOutputSettings().setOutline(true);
        Assert.equals("<html>\n <head>\n  <title>Format test</title>\n </head>\n <body>\n  <div>\n   <p>\n    Hello \n    <span>\n     jsoup \n     <span>users</span>\n    </span>\n   </p>\n   <p>Good.</p>\n  </div>\n </body>\n</html>", doc.getHtml());
    }

    public function testSetIndent() {
        var doc = Jsoup.parse("<div><p>Hello\nthere</p></div>");
        doc.getOutputSettings().setIndentAmount(0);
        Assert.equals("<html>\n<head></head>\n<body>\n<div>\n<p>Hello there</p>\n</div>\n</body>\n</html>", doc.getHtml());
    }

    public function testNotPretty() {
        var doc = Jsoup.parse("<div>   \n<p>Hello\n there\n</p></div>");
        doc.getOutputSettings().setPrettyPrint(false);
        Assert.equals("<html><head></head><body><div>   \n<p>Hello\n there\n</p></div></body></html>", doc.getHtml());

        var div = doc.select("div").first();
        Assert.equals("   \n<p>Hello\n there\n</p>", div.getHtml());
    }
    
    public function testEmptyElementFormatHtml() {
        // don't put newlines into empty blocks
        var doc = Jsoup.parse("<section><div></div></section>");
        Assert.equals("<section>\n <div></div>\n</section>", doc.select("section").first().outerHtml());
    }

    public function testNoIndentOnScriptAndStyle() {
        // don't newline+indent closing </script> and </style> tags
        var doc = Jsoup.parse("<script>one\ntwo</script>\n<style>three\nfour</style>");
        Assert.equals("<script>one\ntwo</script> \n<style>three\nfour</style>", doc.head().getHtml());
    }

    public function testContainerOutput() {
        var doc = Jsoup.parse("<title>Hello there</title> <div><p>Hello</p><p>there</p></div> <div>Another</div>");
        Assert.equals("<title>Hello there</title>", doc.select("title").first().outerHtml());
        Assert.equals("<div>\n <p>Hello</p>\n <p>there</p>\n</div>", doc.select("div").first().outerHtml());
        Assert.equals("<div>\n <p>Hello</p>\n <p>there</p>\n</div> \n<div>\n Another\n</div>", doc.select("body").first().getHtml());
    }

    public function testSetText() {
        var h = "<div id=1>Hello <p>there <b>now</b></p></div>";
        var doc = Jsoup.parse(h);
        Assert.equals("Hello there now", doc.getText()); // need to sort out node whitespace
        Assert.equals("there now", doc.select("p").get(0).getText());

        var div = doc.getElementById("1").setText("Gone");
        Assert.equals("Gone", div.getText());
        Assert.equals(0, doc.select("p").size);
    }
    
    public function testAddNewElement() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.appendElement("p").setText("there");
        div.appendElement("P").setAttr("class", "second").setText("now");
        Assert.equals("<html><head></head><body><div id=\"1\"><p>Hello</p><p>there</p><p class=\"second\">now</p></div></body></html>",
                TextUtil.stripNewlines(doc.getHtml()));

        // check sibling index (with short circuit on reindexChildren):
        var ps = doc.select("p");
        for (i in 0...ps.size) {
            Assert.equals(i, ps.get(i).getSiblingIndex());
        }
    }
    
    public function testAddBooleanAttribute() {
        var div = new Element(Tag.valueOf("div"), "", new Attributes());
        
        div.setAttr("true", true);
        
        div.setAttr("false", "value");
        div.setAttr("false", false);
        
        Assert.isTrue(div.hasAttr("true"));
        Assert.equals("", div.getAttr("true"));
        
        var attributes = div.getAttributes().asList();
        Assert.equals(1, attributes.size, "There should be one attribute");
		Assert.isTrue(Std.is(attributes.get(0), BooleanAttribute), "Attribute should be boolean");
        
        Assert.isFalse(div.hasAttr("false"));
 
        Assert.equals("<div true></div>", div.outerHtml());
    }    

    public function testAppendRowToTable() {
        var doc = Jsoup.parse("<table><tr><td>1</td></tr></table>");
        var table = doc.select("tbody").first();
        table.append("<tr><td>2</td></tr>");

        Assert.equals("<table><tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

	public function testPrependRowToTable() {
        var doc = Jsoup.parse("<table><tr><td>1</td></tr></table>");
        var table = doc.select("tbody").first();
        table.prepend("<tr><td>2</td></tr>");

        Assert.equals("<table><tbody><tr><td>2</td></tr><tr><td>1</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body().getHtml()));

        // check sibling index (reindexChildren):
        var ps = doc.select("tr");
        for (i in 0...ps.size) {
            Assert.equals(i, ps.get(i).getSiblingIndex());
        }
    }
    
    public function testPrependElement() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.prependElement("p").setText("Before");
        Assert.equals("Before", div.child(0).getText());
        Assert.equals("Hello", div.child(1).getText());
    }
    
    public function testAddNewText() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.appendText(" there & now >");
        Assert.equals("<p>Hello</p> there &amp; now &gt;", TextUtil.stripNewlines(div.getHtml()));
    }
    
    public function testPrependText() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.prependText("there & now > ");
        Assert.equals("there & now > Hello", div.getText());
        Assert.equals("there &amp; now &gt; <p>Hello</p>", TextUtil.stripNewlines(div.getHtml()));
    }
    
    public function testAddNewHtml() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.append("<p>there</p><p>now</p>");
        Assert.equals("<p>Hello</p><p>there</p><p>now</p>", TextUtil.stripNewlines(div.getHtml()));

        // check sibling index (no reindexChildren):
        var ps = doc.select("p");
        for (i in 0...ps.size) {
            Assert.equals(i, ps.get(i).getSiblingIndex());
        }
    }
    
    public function testPrependNewHtml() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.prepend("<p>there</p><p>now</p>");
        Assert.equals("<p>there</p><p>now</p><p>Hello</p>", TextUtil.stripNewlines(div.getHtml()));

        // check sibling index (reindexChildren):
        var ps = doc.select("p");
        for (i in 0...ps.size) {
            Assert.equals(i, ps.get(i).getSiblingIndex());
        }
    }
    
    public function testSetHtml() {
        var doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
        var div = doc.getElementById("1");
        div.setHtml("<p>there</p><p>now</p>");
        Assert.equals("<p>there</p><p>now</p>", TextUtil.stripNewlines(div.getHtml()));
    }

    public function testSetHtmlTitle() {
        var doc = Jsoup.parse("<html><head id=2><title id=1></title></head></html>");

        var title = doc.getElementById("1");
        title.setHtml("good");
        Assert.equals("good", title.getHtml());
        title.setHtml("<i>bad</i>");
        Assert.equals("&lt;i&gt;bad&lt;/i&gt;", title.getHtml());

        var head = doc.getElementById("2");
        head.setHtml("<title><i>bad</i></title>");
        Assert.equals("<title>&lt;i&gt;bad&lt;/i&gt;</title>", head.getHtml());
    }

    public function testWrap() {
        var doc = Jsoup.parse("<div><p>Hello</p><p>There</p></div>");
        var p = doc.select("p").first();
        p.wrap("<div class='head'></div>");
        Assert.equals("<div><div class=\"head\"><p>Hello</p></div><p>There</p></div>", TextUtil.stripNewlines(doc.body().getHtml()));

        var ret = p.wrap("<div><div class=foo></div><p>What?</p></div>");
        Assert.equals("<div><div class=\"head\"><div><div class=\"foo\"><p>Hello</p></div><p>What?</p></div></div><p>There</p></div>",
                TextUtil.stripNewlines(doc.body().getHtml()));

        Assert.equals(ret, p);
    }
    
    public function before() {
        var doc = Jsoup.parse("<div><p>Hello</p><p>There</p></div>");
        var p1 = doc.select("p").first();
        p1.before("<div>one</div><div>two</div>");
        Assert.equals("<div><div>one</div><div>two</div><p>Hello</p><p>There</p></div>", TextUtil.stripNewlines(doc.body().getHtml()));
        
        doc.select("p").last().before("<p>Three</p><!-- four -->");
        Assert.equals("<div><div>one</div><div>two</div><p>Hello</p><p>Three</p><!-- four --><p>There</p></div>", TextUtil.stripNewlines(doc.body().getHtml()));
    }
    
    public function after() {
        var doc = Jsoup.parse("<div><p>Hello</p><p>There</p></div>");
        var p1 = doc.select("p").first();
        p1.after("<div>one</div><div>two</div>");
        Assert.equals("<div><p>Hello</p><div>one</div><div>two</div><p>There</p></div>", TextUtil.stripNewlines(doc.body().getHtml()));
        
        doc.select("p").last().after("<p>Three</p><!-- four -->");
        Assert.equals("<div><p>Hello</p><div>one</div><div>two</div><p>There</p><p>Three</p><!-- four --></div>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testWrapWithRemainder() {
        var doc = Jsoup.parse("<div><p>Hello</p></div>");
        var p = doc.select("p").first();
        p.wrap("<div class='head'></div><p>There!</p>");
        Assert.equals("<div><div class=\"head\"><p>Hello</p><p>There!</p></div></div>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testHasText() {
        var doc = Jsoup.parse("<div><p>Hello</p><p></p></div>");
        var div = doc.select("div").first();
        var ps = doc.select("p");

        Assert.isTrue(div.hasText());
        Assert.isTrue(ps.first().hasText());
        Assert.isFalse(ps.last().hasText());
    }

    public function dataset() {
        var doc = Jsoup.parse("<div id=1 data-name=jsoup class=new data-package=jar>Hello</div><p id=2>Hello</p>");
        var div = doc.select("div").first();
        var dataset = div.dataset();
        var attributes = div.getAttributes();

        // size, get, set, add, remove
        Assert.equals(2, dataset.size);
        Assert.equals("jsoup", dataset.get("name"));
        Assert.equals("jar", dataset.get("package"));

        dataset.put("name", "jsoup updated");
        dataset.put("language", "java");
        dataset.remove("package");

        Assert.equals(2, dataset.size);
        Assert.equals(4, attributes.size);
        Assert.equals("jsoup updated", attributes.get("data-name"));
        Assert.equals("jsoup updated", dataset.get("name"));
        Assert.equals("java", attributes.get("data-language"));
        Assert.equals("java", dataset.get("language"));

        attributes.put("data-food", "bacon");
        Assert.equals(3, dataset.size);
        Assert.equals("bacon", dataset.get("food"));

        attributes.put("data-", "empty");
        Assert.equals(null, dataset.get("")); // data- is not a data attribute

        var p = doc.select("p").first();
        Assert.equals(0, p.dataset().size);

    }

    public function parentlessToString() {
        var doc = Jsoup.parse("<img src='foo'>");
        var img = doc.select("img").first();
        Assert.equals("<img src=\"foo\">", img.toString());

        img.remove(); // lost its parent
        Assert.equals("<img src=\"foo\">", img.toString());
    }

    public function testClone() {
        var doc = Jsoup.parse("<div><p>One<p><span>Two</div>");

        var p = doc.select("p").get(1);
        var clone = p.clone();

        Assert.isNull(clone.parent()); // should be orphaned
        Assert.equals(0, clone.getSiblingIndex());
        Assert.equals(1, p.getSiblingIndex());
        Assert.notNull(p.parent());

        clone.append("<span>Three");
        Assert.equals("<p><span>Two</span><span>Three</span></p>", TextUtil.stripNewlines(clone.outerHtml()));
        Assert.equals("<div><p>One</p><p><span>Two</span></p></div>", TextUtil.stripNewlines(doc.body().getHtml())); // not modified

        doc.body().appendChild(clone); // adopt
        Assert.notNull(clone.parent());
        Assert.equals("<div><p>One</p><p><span>Two</span></p></div><p><span>Two</span><span>Three</span></p>", TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testClonesClassnames() {
        var doc = Jsoup.parse("<div class='one two'></div>");
        var div = doc.select("div").first();
        var classes = div.getClassNames();
        Assert.equals(2, classes.size);
        Assert.isTrue(classes.contains("one"));
        Assert.isTrue(classes.contains("two"));

        var copy = div.clone();
        var copyClasses = copy.getClassNames();
        Assert.equals(2, copyClasses.size);
        Assert.isTrue(copyClasses.contains("one"));
        Assert.isTrue(copyClasses.contains("two"));
        copyClasses.set("three");
        copyClasses.unset("one");

        Assert.isTrue(classes.contains("one"));
        Assert.isFalse(classes.contains("three"));
        Assert.isFalse(copyClasses.contains("one"));
        Assert.isTrue(copyClasses.contains("three"));

        Assert.equals("", div.getHtml());
        Assert.equals("", copy.getHtml());
    }

    public function testTagNameSet() {
        var doc = Jsoup.parse("<div><i>Hello</i>");
        doc.select("i").first().setTagName("em");
        Assert.equals(0, doc.select("i").size);
        Assert.equals(1, doc.select("em").size);
        Assert.equals("<em>Hello</em>", doc.select("div").first().getHtml());
    }

    public function testHtmlContainsOuter() {
        var doc = Jsoup.parse("<title>Check</title> <div>Hello there</div>");
        doc.getOutputSettings().setIndentAmount(0);
        Assert.isTrue(doc.getHtml().indexOf(doc.select("title").outerHtml()) >= 0);
        Assert.isTrue(doc.getHtml().indexOf(doc.select("div").outerHtml()) >= 0);
    }

    public function testGetTextNodes() {
        var doc = Jsoup.parse("<p>One <span>Two</span> Three <br> Four</p>");
        var textNodes = doc.select("p").first().textNodes();

        Assert.equals(3, textNodes.size);
        Assert.equals("One ", textNodes.get(0).getText());
        Assert.equals(" Three ", textNodes.get(1).getText());
        Assert.equals(" Four", textNodes.get(2).getText());

        Assert.equals(0, doc.select("br").first().textNodes().size);
    }

    public function testManipulateTextNodes() {
        var doc = Jsoup.parse("<p>One <span>Two</span> Three <br> Four</p>");
        var p = doc.select("p").first();
        var textNodes = p.textNodes();

        textNodes.get(1).setText(" three-more ");
        textNodes.get(2).splitText(3).setText("-ur");

        Assert.equals("One Two three-more Fo-ur", p.getText());
        Assert.equals("One three-more Fo-ur", p.ownText());
        Assert.equals(4, p.textNodes().size); // grew because of split
    }

    public function testGetDataNodes() {
        var doc = Jsoup.parse("<script>One Two</script> <style>Three Four</style> <p>Fix Six</p>");
        var script = doc.select("script").first();
        var style = doc.select("style").first();
        var p = doc.select("p").first();

        var scriptData = script.dataNodes();
        Assert.equals(1, scriptData.size);
        Assert.equals("One Two", scriptData.get(0).getWholeData());

        var styleData = style.dataNodes();
        Assert.equals(1, styleData.size);
        Assert.equals("Three Four", styleData.get(0).getWholeData());

        var pData = p.dataNodes();
        Assert.equals(0, pData.size);
    }

    public function elementIsNotASiblingOfItself() {
        var doc = Jsoup.parse("<div><p>One<p>Two<p>Three</div>");
        var p2 = doc.select("p").get(1);

        Assert.equals("Two", p2.getText());
        var els = p2.siblingElements();
        Assert.equals(2, els.size);
        Assert.equals("<p>One</p>", els.get(0).outerHtml());
        Assert.equals("<p>Three</p>", els.get(1).outerHtml());
    }

    public function testChildThrowsIndexOutOfBoundsOnMissing() {
        var doc = Jsoup.parse("<div><p>One</p><p>Two</p></div>");
        var div = doc.select("div").first();

        Assert.equals(2, div.children().size);
        Assert.equals("One", div.child(0).getText());

        try {
            div.child(3);
            Assert.fail("Should throw index out of bounds");
        } catch (err:Dynamic) {}
    }

    public function moveByAppend() {
        // test for https://github.com/jhy/jsoup/issues/239
        // can empty an element and append its children to another element
        var doc = Jsoup.parse("<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>");
        var div1 = doc.select("div").get(0);
        var div2 = doc.select("div").get(1);

        Assert.equals(4, div1.childNodeSize());
        var children = div1.getChildNodes();
        Assert.equals(4, children.size);

        div2.insertChildren(0, children);

        Assert.equals(0, children.size); // children is backed by div1.childNodes, moved, so should be 0 now
        Assert.equals(0, div1.childNodeSize());
        Assert.equals(4, div2.childNodeSize());
        Assert.equals("<div id=\"1\"></div>\n<div id=\"2\">\n Text \n <p>One</p> Text \n <p>Two</p>\n</div>",
            doc.body().getHtml());
    }

    public function insertChildrenArgumentValidation() {
        var doc = Jsoup.parse("<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>");
        var div1 = doc.select("div").get(0);
        var div2 = doc.select("div").get(1);
        var children = div1.getChildNodes();

        try {
            div2.insertChildren(6, children);
            Assert.fail();
        } catch (err:Dynamic) {}

        try {
            div2.insertChildren(-5, children);
            Assert.fail();
        } catch (err:Dynamic) {}

        try {
            div2.insertChildren(0, null);
            Assert.fail();
        } catch (err:Dynamic) {}
    }

    public function insertChildrenAtPosition() {
        var doc = Jsoup.parse("<div id=1>Text1 <p>One</p> Text2 <p>Two</p></div><div id=2>Text3 <p>Three</p></div>");
        var div1 = doc.select("div").get(0);
        var p1s = div1.select("p");
        var div2 = doc.select("div").get(1);

        Assert.equals(2, div2.childNodeSize());
        div2.insertChildren(-1, p1s);
        Assert.equals(2, div1.childNodeSize()); // moved two out
        Assert.equals(4, div2.childNodeSize());
        Assert.equals(3, p1s.get(1).getSiblingIndex()); // should be last

        var els = new ArrayList<Node>();
        var el1 = new Element(Tag.valueOf("span"), "", new Attributes()).setText("Span1");
        var el2 = new Element(Tag.valueOf("span"), "", new Attributes()).setText("Span2");
        var tn1 = new TextNode("Text4", "");
        els.add(el1);
        els.add(el2);
        els.add(tn1);

        Assert.isNull(el1.parent());
        div2.insertChildren(-2, els);
        Assert.equals(div2, el1.parent());
        Assert.equals(7, div2.childNodeSize());
        Assert.equals(3, el1.getSiblingIndex());
        Assert.equals(4, el2.getSiblingIndex());
        Assert.equals(5, tn1.getSiblingIndex());
    }

    public function insertChildrenAsCopy() {
        var doc = Jsoup.parse("<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>");
        var div1 = doc.select("div").get(0);
        var div2 = doc.select("div").get(1);
        var ps = doc.select("p").clone();
        ps.first().setText("One cloned");
        div2.insertChildren(-1, ps);

        Assert.equals(4, div1.childNodeSize()); // not moved -- cloned
        Assert.equals(2, div2.childNodeSize());
        Assert.equals("<div id=\"1\">Text <p>One</p> Text <p>Two</p></div><div id=\"2\"><p>One cloned</p><p>Two</p></div>",
            TextUtil.stripNewlines(doc.body().getHtml()));
    }

    public function testCssPath() {
        var doc = Jsoup.parse("<div id=\"id1\">A</div><div>B</div><div class=\"c1 c2\">C</div>");
        var divA = doc.select("div").get(0);
        var divB = doc.select("div").get(1);
        var divC = doc.select("div").get(2);
        Assert.equals(divA.cssSelector(), "#id1");
        Assert.equals(divB.cssSelector(), "html > body > div:nth-child(2)");
        Assert.equals(divC.cssSelector(), "html > body > div.c1.c2");

        Assert.isTrue(divA == doc.select(divA.cssSelector()).first());
        Assert.isTrue(divB == doc.select(divB.cssSelector()).first());
        Assert.isTrue(divC == doc.select(divC.cssSelector()).first());
    }


    public function testClassNames() {
        var doc = Jsoup.parse("<div class=\"c1 c2\">C</div>");
        var div = doc.select("div").get(0);

        Assert.equals("c1 c2", div.className());

        var set1 = div.getClassNames();
        var arr1 = set1.toArray();
        Assert.isTrue(arr1.length==2);
        Assert.equals("c1", arr1[0]);
        Assert.equals("c2", arr1[1]);

        // Changes to the set should not be reflected in the Elements getters
       	set1.set("c3");
        Assert.isTrue(2==div.getClassNames().size);
        Assert.equals("c1 c2", div.className());

        // Update the class names to a fresh set
        var newSet = new ListSet<String>(3);
        newSet.merge(set1, true);
        newSet.set("c3");
        
        div.setClassNames(newSet);

        
        Assert.equals("c1 c2 c3", div.className());

        var set2 = div.getClassNames();
        var arr2 = set2.toArray();
        Assert.isTrue(arr2.length==3);
        Assert.equals("c1", arr2[0]);
        Assert.equals("c2", arr2[1]);
        Assert.equals("c3", arr2[2]);
    }

    public function testHashAndEquals() {
        var doc1 = "<div id=1><p class=one>One</p><p class=one>One</p><p class=one>Two</p><p class=two>One</p></div>" +
                "<div id=2><p class=one>One</p><p class=one>One</p><p class=one>Two</p><p class=two>One</p></div>";

        var doc = Jsoup.parse(doc1);
        var els = doc.select("p");

        /*
        for (Element el : els) {
            System.out.println(el.hashCode() + " - " + el.outerHtml());
        }

        0 1534787905 - <p class="one">One</p>
        1 1534787905 - <p class="one">One</p>
        2 1539683239 - <p class="one">Two</p>
        3 1535455211 - <p class="two">One</p>
        4 1534787905 - <p class="one">One</p>
        5 1534787905 - <p class="one">One</p>
        6 1539683239 - <p class="one">Two</p>
        7 1535455211 - <p class="two">One</p>
        */
        Assert.equals(8, els.size);
        var e0 = els.get(0);
        var e1 = els.get(1);
        var e2 = els.get(2);
        var e3 = els.get(3);
        var e4 = els.get(4);
        var e5 = els.get(5);
        var e6 = els.get(6);
        var e7 = els.get(7);

        Assert.isTrue(e0.equals(e1));
        Assert.isTrue(e0.equals(e4));
        Assert.isTrue(e0.equals(e5));
        Assert.isFalse(e0.equals(e2));
        Assert.isFalse(e0.equals(e3));
        Assert.isFalse(e0.equals(e6));
        Assert.isFalse(e0.equals(e7));

        /*Assert.equals(e0.hashCode(), e1.hashCode());
        Assert.equals(e0.hashCode(), e4.hashCode());
        Assert.equals(e0.hashCode(), e5.hashCode());
        Assert.isFalse(e0.hashCode() == (e2.hashCode()));
        Assert.isFalse(e0.hashCode() == (e3).hashCode());
        Assert.isFalse(e0.hashCode() == (e6).hashCode());
        Assert.isFalse(e0.hashCode() == (e7).hashCode());*/
    }

    public function testRelativeUrls() {
        var html = "<body><a href='./one.html'>One</a> <a href='two.html'>two</a> <a href='../three.html'>Three</a> <a href='//example2.com/four/'>Four</a> <a href='https://example2.com/five/'>Five</a>";
        var doc = Jsoup.parse(html, "http://example.com/bar/");
        var els = doc.select("a");

        Assert.equals("http://example.com/bar/one.html", els.get(0).absUrl("href"));
        Assert.equals("http://example.com/bar/two.html", els.get(1).absUrl("href"));
        Assert.equals("http://example.com/three.html", els.get(2).absUrl("href"));
        Assert.equals("http://example2.com/four/", els.get(3).absUrl("href"));
        Assert.equals("https://example2.com/five/", els.get(4).absUrl("href"));
    }
}
