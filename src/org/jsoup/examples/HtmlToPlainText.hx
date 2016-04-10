package org.jsoup.examples;

import org.jsoup.helper.StringBuilder;
import org.jsoup.Jsoup;
import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;
import org.jsoup.select.Elements;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;

using StringTools;

/*
import java.io.IOException;
*/

/**
 * HTML to plain-text. This example program demonstrates the use of jsoup to convert HTML input to lightly-formatted
 * plain-text. That is divergent from the general goal of jsoup's .text() methods, which is to get clean data from a
 * scrape.
 * <p>
 * Note that this is a fairly simplistic formatter -- for real world use you'll want to embrace and extend.
 * </p>
 * <p>
 * To invoke from the command line, assuming you've downloaded the jsoup jar to your current directory:</p>
 * <p><code>java -cp jsoup.jar org.jsoup.examples.HtmlToPlainText url [selector]</code></p>
 * where <i>url</i> is the URL to fetch, and <i>selector</i> is an optional CSS selector.
 * 
 * @author Jonathan Hedley, jonathan@hedley.net
 */
//NOTE(az): don't use userAgent and timeout, but just a string
class HtmlToPlainText {
    private static var userAgent:String = "Mozilla/5.0 (jsoup)";
    private static var timeout:Int = 5 * 1000;

	public function new() { }
	
    public static function process(htmlString:String, baseUri:String = "", selector:String = null) {
        var sb = new StringBuilder();
		
		// parse to a HTML DOM
        var doc = Jsoup.parse(htmlString, baseUri);

        var formatter = new HtmlToPlainText();

        if (selector != null) {
            var elements = doc.select(selector); // get each element that matches the CSS selector
            for (element in elements) {
                var plainText = formatter.getPlainText(element); // format that element to plain text
                sb.add(plainText);
            }
        } else { // format the whole doc
            var plainText = formatter.getPlainText(doc);
            sb.add(plainText);
        }
		
		trace(sb.toString());
    }

    /**
     * Format an Element to plain-text
     * @param element the root element to format
     * @return formatted text
     */
    public function getPlainText(element:Element):String {
        var formatter = new FormattingVisitor();
        var traversor = new NodeTraversor(formatter);
        traversor.traverse(element); // walk the DOM, and call .head() and .tail() for each node

        return formatter.toString();
    }
}

// the formatting rules, implemented in a breadth-first DOM traverse
class FormattingVisitor /*implements NodeVisitor*/ {
	private static var maxWidth:Int = 80;
	private var width:Int = 0;
	private var accum:StringBuilder = new StringBuilder(); // holds the accumulated text

	public function new() { }
	
	// hit when the node is first seen
	public function head(node:Node, depth:Int) {
		var name:String = node.nodeName();
		if (Std.is(node, TextNode)) {
			var tn:TextNode = cast node;
			append(tn.getText()); // TextNodes carry all user-readable text in the DOM.
		}
		else if (name == ("li"))
			append("\n * ");
		else if (name == ("dt"))
			append("  ");
		else if (StringUtil.isAnyOf(name, ["p", "h1", "h2", "h3", "h4", "h5", "tr"]))
			append("\n");
	}

	// hit when all of the node's children (if any) have been visited
	public function tail(node:Node, depth:Int) {
		var name = node.nodeName();
		if (StringUtil.isAnyOf(name, ["br", "dd", "dt", "p", "h1", "h2", "h3", "h4", "h5"]))
			append("\n");
		else if (name == ("a"))
			append(' <${node.absUrl("href")}>');
	}

	// appends text to the string builder with a simple word wrap method
	private function append(text:String) {
		if (text.startsWith("\n"))
			width = 0; // reset counter if starts with a newline. only from formats above, not in natural text
		if (text == (" ") &&
				(accum.length == 0 || StringUtil.isAnyOf(accum.toString().substring(accum.length - 1), [" ", "\n"])))
			return; // don't accumulate long runs of empty spaces

		if (text.length + width > maxWidth) { // won't fit, needs to wrap
			var words = ~/\s+/g.split(text);
			for (i in 0...words.length) {
				var word:String = words[i];
				var last = (i == words.length - 1);
				if (!last) // insert a space if not the last word
					word = word + " ";
				if (word.length + width > maxWidth) { // wrap and reset counter
					accum.add("\n");
					accum.add(word);
					width = word.length;
				} else {
					accum.add(word);
					width += word.length;
				}
			}
		} else { // fits as is, without need to wrap text
			accum.add(text);
			width += text.length;
		}
	}

	/*@Override*/
	public function toString():String {
		return accum.toString();
	}
}
