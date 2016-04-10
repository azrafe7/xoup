package org.jsoup.examples;

import org.jsoup.helper.StringBuilder;
import org.jsoup.Jsoup;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

/**
 * Example program to list links from a URL.
 */
class ListLinks {
	
	public function new() { }
	
    public static function process(htmlString:String, baseUri:String = "") {
        var sb = new StringBuilder();
		
		var doc = Jsoup.parse(htmlString, baseUri);
        var links:Elements = doc.select("a[href]");
        var media:Elements = doc.select("[src]");
        var imports:Elements = doc.select("link[href]");

        sb.add('\nMedia: (${media.size})');
        for (src in media) {
			var tagName = src.getTagName();
			var absUrl = src.getAttr("abs:src");
            if (tagName == ("img")) {
				var w = src.getAttr("width");
				var h = src.getAttr("height");
				var alt = src.getAttr("alt");
                sb.add('\n * $tagName: <$absUrl> ${w}x${h} ($alt)');
            } else
                sb.add('\n * $tagName: <$absUrl>');
        }

        sb.add('\nImports: (${imports.size})');
        for (link in imports) {
			var tagName = link.getTagName();
			var absUrl = link.getAttr("abs:href");
			var rel = link.getAttr("rel");
            sb.add('\n * $tagName <$absUrl> ($rel)');
        }

        sb.add('\nLinks: (${links.size})');
        for (link in links) {
			var absUrl = link.getAttr("abs:href");
			var rel = link.getAttr("rel");
			var text = trim(link.getText(), 35);
            sb.add('\n * a: <$absUrl>  ($text)');
        }
		
		trace(sb.toString());
    }

    private static function trim(s:String, width:Int) {
        if (s.length > width)
            return s.substring(0, width-1) + ".";
        else
            return s;
    }
}
