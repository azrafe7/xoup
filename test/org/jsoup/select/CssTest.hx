package org.jsoup.select;

import org.jsoup.helper.StringBuilder;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.parser.Tag;

import utest.Assert;

/*
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import static org.junit.Assert.*;
*/

class CssTest {

	private var html:Document = null;
	private static var htmlString:String;
	
	/*@BeforeClass*/
	public function new() {
		var sb = new StringBuilder();
		sb.add("<html><head></head><body>");
		
		sb.add("<div id='pseudo'>");
		for (i in 1...11) {
			sb.add('<p>$i</p>');
		}
		sb.add("</div>");

		sb.add("<div id='type'>");
		for (i in 1...11) {
			sb.add('<p>$i</p>');
			sb.add('<span>$i</span>');
			sb.add('<em>$i</em>');
            sb.add('<svg>$i</svg>');
		}
		sb.add("</div>");

		sb.add("<span id='onlySpan'><br /></span>");
		sb.add("<p class='empty'><!-- Comment only is still empty! --></p>");
		
		sb.add("<div id='only'>");
		sb.add("Some text before the <em>only</em> child in this div");
		sb.add("</div>");
		
		sb.add("</body></html>");
		htmlString = sb.toString();
	}

	/*@Before*/
	public function setup() {
		html  = Jsoup.parse(htmlString);
	}
	
	public function testFirstChild() {
		check(html.select("#pseudo :first-child"), ["1"]);
		check(html.select("html:first-child"), []);
	}

	public function testLastChild() {
		check(html.select("#pseudo :last-child"), ["10"]);
		check(html.select("html:last-child"), []);
	}
	
	public function testNthChild_simple() {
		for (i in 1...11) {
			check(html.select('#pseudo :nth-child($i)'), [Std.string(i)]);
		}
	}

    public function testNthOfType_unknownTag() {
		for (i in 1...11) {
            check(html.select('#type svg:nth-of-type($i)'), [Std.string(i)]);
        }
    }

	public function testNthLastChild_simple() {
		for (i in 1...11) {
			check(html.select('#pseudo :nth-last-child($i)'), [Std.string(11-i)]);
		}
	}

	public function testNthOfType_simple() {
		for (i in 1...11) {
			check(html.select('#type p:nth-of-type($i)'), [Std.string(i)]);
		}
	}
	
	public function testNthLastOfType_simple() {
		for (i in 1...11) {
			check(html.select('#type :nth-last-of-type($i)'), [Std.string(11-i),Std.string(11-i),Std.string(11-i),Std.string(11-i)]);
		}
	}

	public function testNthChild_advanced() {
		check(html.select("#pseudo :nth-child(-5)"), []);
		check(html.select("#pseudo :nth-child(odd)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#pseudo :nth-child(2n-1)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#pseudo :nth-child(2n+1)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#pseudo :nth-child(2n+3)"), ["3", "5", "7", "9"]);
		check(html.select("#pseudo :nth-child(even)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#pseudo :nth-child(2n)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#pseudo :nth-child(3n-1)"), ["2", "5", "8"]);
		check(html.select("#pseudo :nth-child(-2n+5)"), ["1", "3", "5"]);
		check(html.select("#pseudo :nth-child(+5)"), ["5"]);
	}

	public function testNthOfType_advanced() {
		check(html.select("#type :nth-of-type(-5)"), []);
		check(html.select("#type p:nth-of-type(odd)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#type em:nth-of-type(2n-1)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#type p:nth-of-type(2n+1)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#type span:nth-of-type(2n+3)"), ["3", "5", "7", "9"]);
		check(html.select("#type p:nth-of-type(even)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#type p:nth-of-type(2n)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#type p:nth-of-type(3n-1)"), ["2", "5", "8"]);
		check(html.select("#type p:nth-of-type(-2n+5)"), ["1", "3", "5"]);
		check(html.select("#type :nth-of-type(+5)"), ["5", "5", "5", "5"]);
	}

	public function testNthLastChild_advanced() {
		check(html.select("#pseudo :nth-last-child(-5)"), []);
		check(html.select("#pseudo :nth-last-child(odd)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#pseudo :nth-last-child(2n-1)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#pseudo :nth-last-child(2n+1)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#pseudo :nth-last-child(2n+3)"), ["2", "4", "6", "8"]);
		check(html.select("#pseudo :nth-last-child(even)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#pseudo :nth-last-child(2n)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#pseudo :nth-last-child(3n-1)"), ["3", "6", "9"]);

		check(html.select("#pseudo :nth-last-child(-2n+5)"), ["6", "8", "10"]);
		check(html.select("#pseudo :nth-last-child(+5)"), ["6"]);
	}

	public function testNthLastOfType_advanced() {
		check(html.select("#type :nth-last-of-type(-5)"), []);
		check(html.select("#type p:nth-last-of-type(odd)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#type em:nth-last-of-type(2n-1)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#type p:nth-last-of-type(2n+1)"), ["2", "4", "6", "8", "10"]);
		check(html.select("#type span:nth-last-of-type(2n+3)"), ["2", "4", "6", "8"]);
		check(html.select("#type p:nth-last-of-type(even)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#type p:nth-last-of-type(2n)"), ["1", "3", "5", "7", "9"]);
		check(html.select("#type p:nth-last-of-type(3n-1)"), ["3", "6", "9"]);

		check(html.select("#type span:nth-last-of-type(-2n+5)"), ["6", "8", "10"]);
		check(html.select("#type :nth-last-of-type(+5)"), ["6", "6", "6", "6"]);
	}
	
	public function testFirstOfType() {
		check(html.select("div:not(#only) :first-of-type"), ["1", "1", "1", "1", "1"]);
	}

	public function testLastOfType() {
		check(html.select("div:not(#only) :last-of-type"), ["10", "10", "10", "10", "10"]);
	}

	public function testEmpty() {
		var sel = html.select(":empty");
		Assert.equals(3, sel.size);
		Assert.equals("head", sel.get(0).getTagName());
		Assert.equals("br", sel.get(1).getTagName());
		Assert.equals("p", sel.get(2).getTagName());
	}
	
	public function testOnlyChild() {
		var sel = html.select("span :only-child");
		Assert.equals(1, sel.size);
		Assert.equals("br", sel.get(0).getTagName());
		
		check(html.select("#only :only-child"), ["only"]);
	}
	
	public function testOnlyOfType() {
		var sel = html.select(":only-of-type");
		Assert.equals(6, sel.size);
		Assert.equals("head", sel.get(0).getTagName());
		Assert.equals("body", sel.get(1).getTagName());
		Assert.equals("span", sel.get(2).getTagName());
		Assert.equals("br", sel.get(3).getTagName());
		Assert.equals("p", sel.get(4).getTagName());
		Assert.isTrue(sel.get(4).hasClass("empty"));
		Assert.equals("em", sel.get(5).getTagName());
	}
	
	function check(result:Elements, expectedContent:Array<String>) {
		Assert.equals(expectedContent.length, result.size, "Number of elements");
		for (i in 0...expectedContent.length) {
			Assert.notNull(result.get(i));
			Assert.equals(expectedContent[i], result.get(i).ownText(), "Expected element");
		}
	}

	public function testRoot() {
		var sel = html.select(":root");
		Assert.equals(1, sel.size);
		Assert.notNull(sel.get(0));
		Assert.equals(Tag.valueOf("html"), sel.get(0).getTag());

		var sel2 = html.select("body").select(":root");
		Assert.equals(1, sel2.size);
		Assert.notNull(sel2.get(0));
		Assert.equals(Tag.valueOf("body"), sel2.get(0).getTag());
	}

}
