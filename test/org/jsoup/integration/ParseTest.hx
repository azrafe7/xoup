package org.jsoup.integration;

import haxe.io.Bytes;
import org.jsoup.Exceptions.MissingResourceException;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import haxe.Resource;

import utest.Assert;

using StringTools;

/*
import org.junit.Test;

import java.io.*;
import java.net.URISyntaxException;

import static org.junit.Assert.*;
*/

/**
 * Integration test: parses from real-world example HTML.
 *
 * @author Jonathan Hedley, jonathan@hedley.net
 */
class ParseTest {
	
	//NOTE(az): charset not specified in .parse()
	
	public function new() { }

    public function testSmhBizArticle() {
        var resource = getFile("htmltests/smh-biz-article-1.html");
        var doc = Jsoup.parse(resource, /*"UTF-8",*/
                "http://www.smh.com.au/business/the-boards-next-fear-the-female-quota-20100106-lteq.html");
        Assert.equals("The board’s next fear: the female quota",
                doc.getTitle()); // note that the apos in the source is a literal ’ (8217), not escaped or '
        Assert.equals("en", doc.select("html").getAttr("xml:lang"));

        var articleBody = doc.select(".articleBody > *");
        Assert.equals(17, articleBody.size);
        // todo: more tests!

    }

    public function testNewsHomepage() {
        var resource = getFile("htmltests/news-com-au-home.html");
        var doc = Jsoup.parse(resource, /*"UTF-8",*/ "http://www.news.com.au/");
        Assert.equals("News.com.au | News from Australia and around the world online | NewsComAu", doc.getTitle());
        Assert.equals("Brace yourself for Metro meltdown", doc.select(".id1225817868581 h4").text().trim());

        var a = doc.select("a[href=/entertainment/horoscopes]").first();
        Assert.equals("/entertainment/horoscopes", a.getAttr("href"));
        Assert.equals("http://www.news.com.au/entertainment/horoscopes", a.getAttr("abs:href"));

        var hs = doc.select("a[href*=naughty-corners-are-a-bad-idea]").first();
        Assert.equals(
                "http://www.heraldsun.com.au/news/naughty-corners-are-a-bad-idea-for-kids/story-e6frf7jo-1225817899003",
                hs.getAttr("href"));
        Assert.equals(hs.getAttr("href"), hs.getAttr("abs:href"));
    }

    public function testGoogleSearchIpod() {
        //Assert.warn("not terminating");
		var resource = getFile("htmltests/google-ipod.html");
        var doc = Jsoup.parse(resource, /*"UTF-8",*/ "http://www.google.com/search?hl=en&q=ipod&aq=f&oq=&aqi=g10");
        Assert.equals("ipod - Google Search", doc.getTitle());
        var results = doc.select("h3.r > a");
        Assert.equals(12, results.size);
        Assert.equals(
                "http://news.google.com/news?hl=en&q=ipod&um=1&ie=UTF-8&ei=uYlKS4SbBoGg6gPf-5XXCw&sa=X&oi=news_group&ct=title&resnum=1&ved=0CCIQsQQwAA",
                results.get(0).getAttr("href"));
        Assert.equals("http://www.apple.com/itunes/",
                results.get(1).getAttr("href"));
    }

    public function testBinary() {
        var resource = getBytes("htmltests/thumb.jpg");
        var doc = Jsoup.parse(resource.toString()/*, "UTF-8"*/);
        // nothing useful, but did not blow up
		var text = doc.getText();
        Assert.isTrue(doc.getText().indexOf("gd-jpeg") >= 0);
    }

    public function testYahooJp() {
        var resource = getFile("htmltests/yahoo-jp.html");
        var doc = Jsoup.parse(resource, /*"UTF-8",*/ "http://www.yahoo.co.jp/index.html"); // http charset is utf-8.
        Assert.equals("Yahoo! JAPAN", doc.getTitle());
        var a = doc.select("a[href=t/2322m2]").first();
        Assert.equals("http://www.yahoo.co.jp/_ylh=X3oDMTB0NWxnaGxsBF9TAzIwNzcyOTYyNjUEdGlkAzEyBHRtcGwDZ2Ex/t/2322m2",
                a.getAttr("abs:href")); // session put into <base>
        Assert.equals("全国、人気の駅ランキング", a.getText());
    }

    public function testBaidu() {
        // tests <meta http-equiv="Content-Type" content="text/html;charset=gb2312">
        var resource = getFile("htmltests/baidu-cn-home.html");
        var doc = Jsoup.parse(resource, /*null,*/
                "http://www.baidu.com/"); // http charset is gb2312, but NOT specifying it, to test http-equiv parse
        var submit = doc.select("#su").first();
        Assert.equals("百度一下", submit.getAttr("value"));

        // test from attribute match
        submit = doc.select("input[value=百度一下]").first();
        Assert.equals("su", submit.id());
        var newsLink = doc.select("a:contains(新)").first();
        Assert.equals("http://news.baidu.com", newsLink.absUrl("href"));

        // check auto-detect from meta
        Assert.equals("GB2312", doc.getOutputSettings().getCharset().displayName());
        Assert.equals("<title>百度一下，你就知道      </title>", doc.select("title").outerHtml());

        doc.getOutputSettings().setCharset("ascii");
        Assert.equals("<title>&#x767e;&#x5ea6;&#x4e00;&#x4e0b;&#xff0c;&#x4f60;&#x5c31;&#x77e5;&#x9053;      </title>",
                doc.select("title").outerHtml());
    }

    public function testBaiduVariant() {
        // tests <meta charset> when preceded by another <meta>
        var resource = getFile("htmltests/baidu-variant.html");
        var doc = Jsoup.parse(resource, /*null,*/
                "http://www.baidu.com/"); // http charset is gb2312, but NOT specifying it, to test http-equiv parse
        // check auto-detect from meta
        Assert.equals("GB2312", doc.getOutputSettings().getCharset().displayName());
        Assert.equals("<title>百度一下，你就知道</title>", doc.select("title").outerHtml());
    }

    public function testHtml5Charset() {
        // test that <meta charset="gb2312"> works
        var resource = getFile("htmltests/meta-charset-1.html");
        var doc = Jsoup.parse(resource, /*null,*/ "http://example.com/"); //gb2312, has html5 <meta charset>
        Assert.equals("新", doc.getText());
        Assert.equals("GB2312", doc.getOutputSettings().getCharset().displayName());

        // double check, no charset, falls back to utf8 which is incorrect
        resource = getFile("htmltests/meta-charset-2.html"); //
        doc = Jsoup.parse(resource, /*null,*/ "http://example.com"); // gb2312, no charset
        Assert.equals("UTF-8", doc.getOutputSettings().getCharset().displayName());
        Assert.isFalse("新" == (doc.getText()));

        // confirm fallback to utf8
        resource = getFile("htmltests/meta-charset-3.html");
        doc = Jsoup.parse(resource, /*null,*/ "http://example.com/"); // utf8, no charset
        Assert.equals("UTF-8", doc.getOutputSettings().getCharset().displayName());
        Assert.equals("新", doc.getText());
    }

    public function testBrokenHtml5CharsetWithASingleDoubleQuote() {
        var resource = "<html>\n" +
                "<head><meta charset=UTF-8\"></head>\n" +
                "<body></body>\n" +
                "</html>";
        var doc = Jsoup.parse(resource, /*null,*/ "http://example.com/");
        Assert.equals("UTF-8", doc.getOutputSettings().getCharset().displayName());
    }

    public function testNytArticle() {
        // has tags like <nyt_text>
        var resource = getFile("htmltests/nyt-article-1.html");
        var doc = Jsoup.parse(resource, /*null,*/ "http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp");

        var headline = doc.select("nyt_headline[version=1.0]").first();
        Assert.equals("As BP Lays Out Future, It Will Not Include Hayward", headline.getText());
    }

    public function testYahooArticle() {
        var resource = getFile("htmltests/yahoo-article-1.html");
        var doc = Jsoup.parse(resource, /*"UTF-8",*/ "http://news.yahoo.com/s/nm/20100831/bs_nm/us_gm_china");
        var p = doc.select("p:contains(Volt will be sold in the United States").first();
        Assert.equals("In July, GM said its electric Chevrolet Volt will be sold in the United States at $41,000 -- $8,000 more than its nearest competitor, the Nissan Leaf.", p.getText());
    }

    public static function getBytes(resourceName:String):Bytes {
        var res:Bytes = null;
		try {
			res = Resource.getBytes(resourceName);
        } catch (e:Dynamic) { }
            
		if (res == null) throw new MissingResourceException("Error loading resource: " + resourceName);
		
        return res;
	}
	
    public static function getFile(resourceName:String):String {
        var res:String = null;
		try {
			res = Resource.getString(resourceName);
        } catch (e:Dynamic) { }
            
		if (res == null) throw new MissingResourceException("Error loading resource: " + resourceName);
		
        return res;
		/*try {
            File file = new File(ParseTest.class.getResource(resourceName).toURI());
            return file;
        } catch (URISyntaxException e) {
            throw new IllegalStateException(e);
        }*/
    }

    /*
	public static InputStream inputStreamFrom(String s) {
        try {
            return new ByteArrayInputStream(s.getBytes("UTF-8"));
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }*/

}
