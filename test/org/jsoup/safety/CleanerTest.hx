package org.jsoup.safety;

import org.jsoup.Jsoup;
import org.jsoup.TextUtil;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Entities;

import utest.Assert;

/*
import org.junit.Test;
import static org.junit.Assert.*;
*/

/**
 Tests for the cleaner.

 @author Jonathan Hedley, jonathan@hedley.net */
class CleanerTest {
	
	public function new() { }
	
    public function testSimpleBehaviourTest() {
        var h = "<div><p class=foo><a href='http://evil.com'>Hello <b id=bar>there</b>!</a></div>";
        var cleanHtml = Jsoup.clean(h, Whitelist.simpleText());

        Assert.equals("Hello <b>there</b>!", TextUtil.stripNewlines(cleanHtml));
    }
    
    public function testSimpleBehaviourTest2() {
        var h = "Hello <b>there</b>!";
        var cleanHtml = Jsoup.clean(h, Whitelist.simpleText());

        Assert.equals("Hello <b>there</b>!", TextUtil.stripNewlines(cleanHtml));
    }

    public function testBasicBehaviourTest() {
        var h = "<div><p><a href='javascript:sendAllMoney()'>Dodgy</a> <A HREF='HTTP://nice.com'>Nice</a></p><blockquote>Hello</blockquote>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basic());

        Assert.equals("<p><a rel=\"nofollow\">Dodgy</a> <a href=\"http://nice.com\" rel=\"nofollow\">Nice</a></p><blockquote>Hello</blockquote>",
                TextUtil.stripNewlines(cleanHtml));
    }
    
    public function testBasicWithImagesTest() {
        var h = "<div><p><img src='http://example.com/' alt=Image></p><p><img src='ftp://ftp.example.com'></p></div>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basicWithImages());
        Assert.equals("<p><img src=\"http://example.com/\" alt=\"Image\"></p><p><img></p>", TextUtil.stripNewlines(cleanHtml));
    }
    
    public function testRelaxed() {
        var h = "<h1>Head</h1><table><tr><td>One<td>Two</td></tr></table>";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("<h1>Head</h1><table><tbody><tr><td>One</td><td>Two</td></tr></tbody></table>", TextUtil.stripNewlines(cleanHtml));
    }

    public function testRemoveTags() {
        var h = "<div><p><A HREF='HTTP://nice.com'>Nice</a></p><blockquote>Hello</blockquote>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basic().removeTags(["a"]));

        Assert.equals("<p>Nice</p><blockquote>Hello</blockquote>", TextUtil.stripNewlines(cleanHtml));
    }

    public function testRemoveAttributes() {
        var h = "<div><p>Nice</p><blockquote cite='http://example.com/quotations'>Hello</blockquote>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basic().removeAttributes("blockquote", ["cite"]));

        Assert.equals("<p>Nice</p><blockquote>Hello</blockquote>", TextUtil.stripNewlines(cleanHtml));
    }

    public function testRemoveEnforcedAttributes() {
        var h = "<div><p><A HREF='HTTP://nice.com'>Nice</a></p><blockquote>Hello</blockquote>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basic().removeEnforcedAttribute("a", "rel"));

        Assert.equals("<p><a href=\"http://nice.com\">Nice</a></p><blockquote>Hello</blockquote>",
                TextUtil.stripNewlines(cleanHtml));
    }

    public function testRemoveProtocols() {
        var h = "<p>Contact me <a href='mailto:info@example.com'>here</a></p>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basic().removeProtocols("a", "href", ["ftp", "mailto"]));

        Assert.equals("<p>Contact me <a rel=\"nofollow\">here</a></p>",
                TextUtil.stripNewlines(cleanHtml));
    }
    
    public function testDropComments() {
        var h = "<p>Hello<!-- no --></p>";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("<p>Hello</p>", cleanHtml);
    }
    
    public function testDropXmlProc() {
        var h = "<?import namespace=\"xss\"><p>Hello</p>";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("<p>Hello</p>", cleanHtml);
    }
    
    public function testDropScript() {
        var h = "<SCRIPT SRC=//ha.ckers.org/.j><SCRIPT>alert(/XSS/.source)</SCRIPT>";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("", cleanHtml);
    }
    
    public function testDropImageScript() {
        var h = "<IMG SRC=\"javascript:alert('XSS')\">";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("<img>", cleanHtml);
    }
    
    public function testCleanJavascriptHref() {
        var h = "<A HREF=\"javascript:document.location='http://www.google.com/'\">XSS</A>";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("<a>XSS</a>", cleanHtml);
    }

    public function testCleanAnchorProtocol() {
        var validAnchor = "<a href=\"#valid\">Valid anchor</a>";
        var invalidAnchor = "<a href=\"#anchor with spaces\">Invalid anchor</a>";

        // A Whitelist that does not allow anchors will strip them out.
        var cleanHtml = Jsoup.clean(validAnchor, Whitelist.relaxed());
        Assert.equals("<a>Valid anchor</a>", cleanHtml);

        cleanHtml = Jsoup.clean(invalidAnchor, Whitelist.relaxed());
        Assert.equals("<a>Invalid anchor</a>", cleanHtml);

        // A Whitelist that allows them will keep them.
        var relaxedWithAnchor:Whitelist = Whitelist.relaxed().addProtocols("a", "href", ["#"]);

        cleanHtml = Jsoup.clean(validAnchor, relaxedWithAnchor);
        Assert.equals(validAnchor, cleanHtml);

        // An invalid anchor is never valid.
        cleanHtml = Jsoup.clean(invalidAnchor, relaxedWithAnchor);
        Assert.equals("<a>Invalid anchor</a>", cleanHtml);
    }

    public function testDropsUnknownTags() {
        var h = "<p><custom foo=true>Test</custom></p>";
        var cleanHtml = Jsoup.clean(h, Whitelist.relaxed());
        Assert.equals("<p>Test</p>", cleanHtml);
    }
    
    public function testHandlesEmptyAttributes() {
        var h = "<img alt=\"\" src= unknown=''>";
        var cleanHtml = Jsoup.clean(h, Whitelist.basicWithImages());
        Assert.equals("<img alt=\"\">", cleanHtml);
    }

    public function testIsValid() {
        var ok = "<p>Test <b><a href='http://example.com/'>OK</a></b></p>";
        var nok1 = "<p><script></script>Not <b>OK</b></p>";
        var nok2 = "<p align=right>Test Not <b>OK</b></p>";
        var nok3 = "<!-- comment --><p>Not OK</p>"; // comments and the like will be cleaned
        Assert.isTrue(Jsoup.isValid(ok, Whitelist.basic()));
        Assert.isFalse(Jsoup.isValid(nok1, Whitelist.basic()));
        Assert.isFalse(Jsoup.isValid(nok2, Whitelist.basic()));
        Assert.isFalse(Jsoup.isValid(nok3, Whitelist.basic()));
    }
    
    public function testResolvesRelativeLinks() {
        var html = "<a href='/foo'>Link</a><img src='/bar'>";
        var clean = Jsoup.clean(html, Whitelist.basicWithImages(), "http://example.com/");
        Assert.equals("<a href=\"http://example.com/foo\" rel=\"nofollow\">Link</a>\n<img src=\"http://example.com/bar\">", clean);
    }

    public function testPreservesRelativeLinksIfConfigured() {
        var html = "<a href='/foo'>Link</a><img src='/bar'> <img src='javascript:alert()'>";
        var clean = Jsoup.clean(html, Whitelist.basicWithImages().setPreserveRelativeLinks(true), "http://example.com/");
        Assert.equals("<a href=\"/foo\" rel=\"nofollow\">Link</a>\n<img src=\"/bar\"> \n<img>", clean);
    }
    
    public function testDropsUnresolvableRelativeLinks() {
        var html = "<a href='/foo'>Link</a>";
        var clean = Jsoup.clean(html, Whitelist.basic());
        Assert.equals("<a rel=\"nofollow\">Link</a>", clean);
    }

    public function testHandlesCustomProtocols() {
        var html = "<img src='cid:12345' /> <img src='data:gzzt' />";
        var dropped = Jsoup.clean(html, Whitelist.basicWithImages());
        Assert.equals("<img> \n<img>", dropped);

        var preserved = Jsoup.clean(html, Whitelist.basicWithImages().addProtocols("img", "src", ["cid", "data"]));
        Assert.equals("<img src=\"cid:12345\"> \n<img src=\"data:gzzt\">", preserved);
    }

    public function testHandlesAllPseudoTag() {
        var html = "<p class='foo' src='bar'><a class='qux'>link</a></p>";
        var whitelist:Whitelist = new Whitelist()
                .addAttributes(":all", ["class"])
                .addAttributes("p", ["style"])
                .addTags(["p", "a"]);

        var clean = Jsoup.clean(html, whitelist);
        Assert.equals("<p class=\"foo\"><a class=\"qux\">link</a></p>", clean);
    }

    public function testAddsTagOnAttributesIfNotSet() {
        var html = "<p class='foo' src='bar'>One</p>";
        var whitelist:Whitelist = new Whitelist()
            .addAttributes("p", ["class"]);
        // ^^ whitelist does not have explicit tag add for p, inferred from add attributes.
        var clean = Jsoup.clean(html, whitelist);
        Assert.equals("<p class=\"foo\">One</p>", clean);
    }

    public function testSupplyOutputSettings() {
        // test that one can override the default document output settings
        var os = new OutputSettings();
        os.setPrettyPrint(false);
        os.setEscapeMode(EscapeMode.extended);
        os.setCharset("ascii");

        var html = "<div><p>&bernou;</p></div>";
        var customOut = Jsoup.clean(html, Whitelist.relaxed(), "http://foo.com/", os);
        var defaultOut = Jsoup.clean(html, Whitelist.relaxed(), "http://foo.com/");
        Assert.notEquals(defaultOut, customOut);

        Assert.equals("<div><p>&bernou;</p></div>", customOut);
        Assert.equals("<div>\n" +
            " <p>ℬ</p>\n" +
            "</div>", defaultOut);

        os.setCharset("ASCII");
        os.setEscapeMode(EscapeMode.base);
        var customOut2 = Jsoup.clean(html, Whitelist.relaxed(), "http://foo.com/", os);
        Assert.equals("<div><p>&#x212c;</p></div>", customOut2);
    }

    public function testHandlesFramesets() {
        var dirty = "<html><head><script></script><noscript></noscript></head><frameset><frame src=\"foo\" /><frame src=\"foo\" /></frameset></html>";
        var clean = Jsoup.clean(dirty, Whitelist.basic());
        Assert.equals("", clean); // nothing good can come out of that

        var dirtyDoc = Jsoup.parse(dirty);
        var cleanDoc = new Cleaner(Whitelist.basic()).clean(dirtyDoc);
        Assert.isFalse(cleanDoc == null);
        Assert.equals(0, cleanDoc.body().childNodeSize());
    }

    public function testCleansInternationalText() {
        Assert.equals("привет", Jsoup.clean("привет", Whitelist.none()));
    }

    public function testScriptTagInWhiteList() {
        var whitelist:Whitelist = Whitelist.relaxed();
        whitelist.addTags( ["script"] );
        Assert.isTrue( Jsoup.isValid("Hello<script>alert('Doh')</script>World !", whitelist ) );
    }
}
