package org.jsoup.nodes;

import org.jsoup.Exceptions.IllegalArgumentException;
import utest.Assert;

/*import org.junit.Test;

import static org.junit.Assert.*;
*/

/**
 * Tests for the DocumentType node
 *
 * @author Jonathan Hedley, http://jonathanhedley.com/
 */
class DocumentTypeTest {

	public function new() {}
	
    public function testConstructorValidationOkWithBlankName() {
        var ok = new DocumentType("", "", "", "");
		Assert.notNull(ok);
    }

    //@Test(expected = IllegalArgumentException.class)
    public function testConstructorValidationThrowsExceptionOnNulls() {
		Assert.raises(createInvalidDocumentType, IllegalArgumentException);
    }
	
	function createInvalidDocumentType():Void {	
		var fail = new DocumentType("html", null, null, "");
	}
		
    public function testConstructorValidationOkWithBlankPublicAndSystemIds() {
        var ok = new DocumentType("html","", "","");
		Assert.notNull(ok);
    }

    public function testOouterHtmlGeneration() {
        var html5 = new DocumentType("html", "", "", "");
        Assert.equals("<!doctype html>", html5.outerHtml());

        var publicDocType = new DocumentType("html", "-//IETF//DTD HTML//", "", "");
        Assert.equals("<!DOCTYPE html PUBLIC \"-//IETF//DTD HTML//\">", publicDocType.outerHtml());

        var systemDocType = new DocumentType("html", "", "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd", "");
        Assert.equals("<!DOCTYPE html \"http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd\">", systemDocType.outerHtml());

        var combo = new DocumentType("notHtml", "--public", "--system", "");
        Assert.equals("<!DOCTYPE notHtml PUBLIC \"--public\" \"--system\">", combo.outerHtml());
    }
}
