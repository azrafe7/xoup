package org.jsoup.nodes;

import unifill.CodePoint;

import utest.Assert;

/*import org.junit.Test;

import static org.junit.Assert.assertEquals;
*/

class AttributeTest {
    
	public function new() {}
	
	public function testHtml() {
        var attr = new Attribute("key", "value &");
        Assert.equals("key=\"value &amp;\"", attr.html());
        Assert.equals(attr.html(), attr.toString());
    }

    public function testWithSupplementaryCharacterInAttributeKeyAndValue() {
        var s:String = CodePoint.fromInt(135361).toString();
        var attr:Attribute = new Attribute(s, "A" + s + "B");
        Assert.equals(s + "=\"A" + s + "B\"", attr.html());
        Assert.equals(attr.html(), attr.toString());
    }
}
