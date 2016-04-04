package org.jsoup.helper;

import de.polygonal.ds.ArrayList;
import org.jsoup.Jsoup;
import org.jsoup.helper.StringUtil;
import unifill.CodePoint;

import utest.Assert;

using unifill.Unifill;

/*import org.junit.Test;

import java.util.Arrays;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.Assert.isFalse;
import static org.junit.Assert.Assert.isTrue;
*/
class StringUtilTest {

	public function new() { }
	
    public function testJoin() {
        Assert.equals("", StringUtil.join(new ArrayList(1, [""]), " "));
        Assert.equals("one", StringUtil.join(new ArrayList(1, ["one"]), " "));
        Assert.equals("one two three", StringUtil.join(new ArrayList(3, ["one", "two", "three"]), " "));
    }

    public function testPadding() {
        Assert.equals("", StringUtil.getPadding(0));
        Assert.equals(" ", StringUtil.getPadding(1));
        Assert.equals("  ", StringUtil.getPadding(2));
        Assert.equals("               ", StringUtil.getPadding(15));
    }

    public function testIsBlank() {
        Assert.isTrue(StringUtil.isBlank(null));
        Assert.isTrue(StringUtil.isBlank(""));
        Assert.isTrue(StringUtil.isBlank("      "));
        Assert.isTrue(StringUtil.isBlank("   \r\n  "));

        Assert.isFalse(StringUtil.isBlank("hello"));
        Assert.isFalse(StringUtil.isBlank("   hello   "));
    }

    public function testIsNumeric() {
        Assert.isFalse(StringUtil.isNumeric(null));
        Assert.isFalse(StringUtil.isNumeric(" "));
        Assert.isFalse(StringUtil.isNumeric("123 546"));
        Assert.isFalse(StringUtil.isNumeric("hello"));
        Assert.isFalse(StringUtil.isNumeric("123.334"));

        Assert.isTrue(StringUtil.isNumeric("1"));
        Assert.isTrue(StringUtil.isNumeric("1234"));
    }

    public function testIsWhitespace() {
        Assert.isTrue(StringUtil.isWhitespace('\t'.code));
        Assert.isTrue(StringUtil.isWhitespace('\n'.code));
        Assert.isTrue(StringUtil.isWhitespace('\r'.code));
        Assert.isTrue(StringUtil.isWhitespace(0xC/*'\f'*/));
        Assert.isTrue(StringUtil.isWhitespace(' '.code));
        
        Assert.isFalse(StringUtil.isWhitespace(CodePoint.fromInt(0x00a0)));
        Assert.isFalse(StringUtil.isWhitespace(CodePoint.fromInt(0x2000)));
        Assert.isFalse(StringUtil.isWhitespace(CodePoint.fromInt(0x3000)));
    }

    public function testNormaliseWhiteSpace() {
        Assert.equals(" ", StringUtil.normaliseWhitespace("    \r \n \r\n"));
        Assert.equals(" hello there ", StringUtil.normaliseWhitespace("   hello   \r \n  there    \n"));
        Assert.equals("hello", StringUtil.normaliseWhitespace("hello"));
        Assert.equals("hello there", StringUtil.normaliseWhitespace("hello\nthere"));
    }

    public function testNormaliseWhiteSpaceHandlesHighSurrogates() {
        var test71540chars:String = "\ud869\udeb2\u304b\u309a  1";
        var test71540charsExpectedSingleWhitespace:String = "\ud869\udeb2\u304b\u309a 1";

        Assert.equals(test71540charsExpectedSingleWhitespace, StringUtil.normaliseWhitespace(test71540chars));
        var extractedText:String = Jsoup.parse(test71540chars).getText();
        Assert.equals(test71540charsExpectedSingleWhitespace, extractedText);
    }

    public function testResolvesRelativeUrls() {
        Assert.equals("http://example.com/one/two?three", StringUtil.resolve("http://example.com", "./one/two?three"));
        Assert.equals("http://example.com/one/two?three", StringUtil.resolve("http://example.com?one", "./one/two?three"));
        Assert.equals("http://example.com/one/two?three#four", StringUtil.resolve("http://example.com", "./one/two?three#four"));
        Assert.equals("https://example.com/one", StringUtil.resolve("http://example.com/", "https://example.com/one"));
        Assert.equals("http://example.com/one/two.html", StringUtil.resolve("http://example.com/two/", "../one/two.html"));
        Assert.equals("https://example2.com/one", StringUtil.resolve("https://example.com/", "//example2.com/one"));
        Assert.equals("https://example.com:8080/one", StringUtil.resolve("https://example.com:8080", "./one"));
        Assert.equals("https://example2.com/one", StringUtil.resolve("http://example.com/", "https://example2.com/one"));
        Assert.equals("https://example.com/one", StringUtil.resolve("wrong", "https://example.com/one"));
        Assert.equals("https://example.com/one", StringUtil.resolve("https://example.com/one", ""));
        Assert.equals("", StringUtil.resolve("wrong", "also wrong"));
        Assert.equals("ftp://example.com/one", StringUtil.resolve("ftp://example.com/two/", "../one"));
        Assert.equals("ftp://example.com/one/two.c", StringUtil.resolve("ftp://example.com/one/", "./two.c"));
        Assert.equals("ftp://example.com/one/two.c", StringUtil.resolve("ftp://example.com/one/", "two.c"));
    }
}
