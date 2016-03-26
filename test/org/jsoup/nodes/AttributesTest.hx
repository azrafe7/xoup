package org.jsoup.nodes;


import utest.Assert;

/*import static org.junit.Assert.*;

import org.junit.Test;
*/

/**
 * Tests for Attributes.
 *
 * @author Jonathan Hedley
 */
class AttributesTest {
	
	public function new() {}
	
    public function testHtml() {
        var a = new Attributes();
        a.put("Tot", "a&p");
        a.put("Hello", "There");
        a.put("data-name", "Jsoup");

        Assert.equals(3, a.size());
        Assert.isTrue(a.hasKey("tot"));
        Assert.isTrue(a.hasKey("Hello"));
        Assert.isTrue(a.hasKey("data-name"));
        Assert.equals(1, a.dataset().size());
        Assert.equals("Jsoup", a.dataset().get("name"));
        Assert.equals("a&p", a.get("tot"));

        Assert.equals(" tot=\"a&amp;p\" hello=\"There\" data-name=\"Jsoup\"", a.html());
        Assert.equals(a.html(), a.toString());
    }

}
