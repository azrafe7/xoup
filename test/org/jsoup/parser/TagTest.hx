package org.jsoup.parser;

import org.jsoup.Exceptions.IllegalArgumentException;
import utest.Assert;

/*
import org.junit.Test;
import static org.junit.Assert.*;
*/

/**
 var tests.
 @author Jonathan Hedley, jonathan@hedley.net */
class TagTest {

	public function new() { }
    
	public function testIsCaseInsensitive() {
        var p1 = Tag.valueOf("P");
        var p2 = Tag.valueOf("p");
        Assert.equals(p1, p2);
    }

    public function testTrims() {
        var p1 = Tag.valueOf("p");
        var p2 = Tag.valueOf(" p ");
        Assert.equals(p1, p2);
    }

    public function testEquality() {
        var p1 = Tag.valueOf("p");
        var p2 = Tag.valueOf("p");
        Assert.isTrue(p1.equals(p2));
        Assert.isTrue(p1 == p2);
    }

    public function testDivSemantics() {
        var div = Tag.valueOf("div");

        Assert.isTrue(div.isBlock());
        Assert.isTrue(div.formatAsBlock());
    }

    public function testPSemantics() {
        var p = Tag.valueOf("p");

        Assert.isTrue(p.isBlock());
        Assert.isFalse(p.formatAsBlock());
    }

    public function testImgSemantics() {
        var img = Tag.valueOf("img");
        Assert.isTrue(img.isInline());
        Assert.isTrue(img.isSelfClosing());
        Assert.isFalse(img.isBlock());
    }

    public function testDefaultSemantics() {
        var foo = Tag.valueOf("foo"); // not defined
        var foo2 = Tag.valueOf("FOO");

        Assert.isTrue(foo.equals(foo2));
        Assert.isTrue(foo.isInline());
        Assert.isTrue(foo.formatAsBlock());
    }

    public function testValueOfChecksNotNull() {
        Assert.raises(function ():Void {
			Tag.valueOf(null);
		}, IllegalArgumentException);
    }

    public function testValueOfChecksNotEmpty() {
        Assert.raises(function ():Void {
			Tag.valueOf(" ");
		}, IllegalArgumentException);
    }
}
