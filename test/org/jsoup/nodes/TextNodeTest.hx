package org.jsoup.nodes;

import org.jsoup.Jsoup;
import org.jsoup.TextUtil;
import unifill.CodePoint;

import utest.Assert;

using StringTools;

/*import org.junit.Test;

import static org.junit.Assert.*;
*/

/**
 Test TextNodes

 @author Jonathan Hedley, jonathan@hedley.net */
class TextNodeTest {
	
	public function new() {}
	
    public function testBlank() {
        var one = new TextNode("", "");
        var two = new TextNode("     ", "");
        var three = new TextNode("  \n\n   ", "");
        var four = new TextNode("Hello", "");
        var five = new TextNode("  \nHello ", "");

        Assert.isTrue(one.isBlank());
        Assert.isTrue(two.isBlank());
        Assert.isTrue(three.isBlank());
        Assert.isFalse(four.isBlank());
        Assert.isFalse(five.isBlank());
    }
    
    public function testTextBean() {
        var doc = Jsoup.parse("<p>One <span>two &amp;</span> three &amp;</p>");
        var p = doc.select("p").first();

        var span = doc.select("span").first();
        Assert.equals("two &", span.getText());
        var spanText:TextNode = cast span.childNode(0);
        Assert.equals("two &", spanText.getText());
        
        var tn:TextNode = cast p.childNode(2);
        Assert.equals(" three &", tn.getText());
        
        tn.setText(" POW!");
        Assert.equals("One <span>two &amp;</span> POW!", TextUtil.stripNewlines(p.getHtml()));

        tn.setAttr("text", "kablam &");
        Assert.equals("kablam &", tn.getText());
        Assert.equals("One <span>two &amp;</span>kablam &amp;", TextUtil.stripNewlines(p.getHtml()));
    }

    public function testSplitText() {
        var doc = Jsoup.parse("<div>Hello there</div>");
        var div = doc.select("div").first();
        var tn:TextNode = cast div.childNode(0);
        var tail = tn.splitText(6);
        Assert.equals("Hello ", tn.getWholeText());
        Assert.equals("there", tail.getWholeText());
        tail.setText("there!");
        Assert.equals("Hello there!", div.getText());
        Assert.isTrue(tn.parent() == tail.parent());
    }

    public function testSplitAnEmbolden() {
        var doc = Jsoup.parse("<div>Hello there</div>");
        var div = doc.select("div").first();
        var tn:TextNode = cast div.childNode(0);
        var tail = tn.splitText(6);
        tail.wrap("<b></b>");

        Assert.equals("Hello <b>there</b>", TextUtil.stripNewlines(div.getHtml())); // not great that we get \n<b>there there... must correct
    }

    public function testWithSupplementaryCharacter(){
        var doc = Jsoup.parse(CodePoint.fromInt(135361).toString());
        var t = doc.body().textNodes().get(0);
        Assert.equals(CodePoint.fromInt(135361).toString(), t.outerHtml().trim());
    }
}
