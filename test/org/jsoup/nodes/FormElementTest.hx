package org.jsoup.nodes;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import org.jsoup.Connection;
import org.jsoup.Jsoup;

import utest.Assert;

using StringTools;

/*
import org.junit.Test;
import java.util.List;

import static org.junit.Assert..*;
*/

/**
 * Tests for FormElement
 *
 * @author Jonathan Hedley
 */
class FormElementTest {
    
	public function new() {}
	
	public function testHasAssociatedControls() {
        //"button", "fieldset", "input", "keygen", "object", "output", "select", "textarea"
        var html = "<form id=1><button id=1><fieldset id=2 /><input id=3><keygen id=4><object id=5><output id=6>" +
                "<select id=7><option></select><textarea id=8><p id=9>";
        var doc = Jsoup.parse(html);

        var form:FormElement = cast doc.select("form").first();
        Assert.equals(8, form.getElements().size);
    }

    public function testCreatesFormData() {
        var html = "<form><input name='one' value='two'><select name='three'><option value='not'>" +
                "<option value='four' selected><option value='five' selected><textarea name=six>seven</textarea>" +
                "<input name='seven' type='radio' value='on' checked><input name='seven' type='radio' value='off'>" +
                "<input name='eight' type='checkbox' checked><input name='nine' type='checkbox' value='unset'>" +
                "<input name='ten' value='text' disabled>" +
                "</form>";
        var doc = Jsoup.parse(html);
        var form:FormElement= cast doc.select("form").first();
        var data:List<Connection.KeyVal> = form.formData();

        Assert.equals(6, data.size);
        Assert.equals("one=two", data.get(0).toString());
        Assert.equals("three=four", data.get(1).toString());
        Assert.equals("three=five", data.get(2).toString());
        Assert.equals("six=seven", data.get(3).toString());
        Assert.equals("seven=on", data.get(4).toString()); // set
        Assert.equals("eight=on", data.get(5).toString()); // default
        // nine should not appear, not checked checkbox
        // ten should not appear, disabled
    }

    public function testCreatesSubmitableConnection() {
		Assert.warn("ignored: uses connection");
        /*String html = "<form action='/search'><input name='q'></form>";
        Document doc = Jsoup.parse(html, "http://example.com/");
        doc.select("[name=q]").attr("value", "jsoup");

        FormElement form = ((FormElement) doc.select("form").first());
        Connection con = form.submit();

        Assert.equals(Connection.Method.GET, con.request().method());
        Assert.equals("http://example.com/search", con.request().url().toExternalForm());
        List<Connection.KeyVal> dataList = (List<Connection.KeyVal>) con.request().data();
        Assert.equals("q=jsoup", dataList.get(0).toString());

        doc.select("form").attr("method", "post");
        Connection con2 = form.submit();
        Assert.equals(Connection.Method.POST, con2.request().method());*/
    }

    public function testActionWithNoValue() {
		Assert.warn("ignored: uses connection");
        /*String html = "<form><input name='q'></form>";
        Document doc = Jsoup.parse(html, "http://example.com/");
        FormElement form = ((FormElement) doc.select("form").first());
        Connection con = form.submit();

        Assert.equals("http://example.com/", con.request().url().toExternalForm());*/
    }

    public function testActionWithNoBaseUri() {
		Assert.warn("ignored: uses connection");
		/*var html = "<form><input name='q'></form>";
        Document doc = Jsoup.parse(html);
        FormElement form = ((FormElement) doc.select("form").first());


        boolean threw = false;
        try {
            Connection con = form.submit();
        } catch (IllegalArgumentException e) {
            threw = true;
            Assert.equals("Could not determine a form action URL for submit. Ensure you set a base URI when parsing.",
                    e.getMessage());
        }
        Assert.isTrue(threw);*/
    }

    public function testFormsAddedAfterParseAreFormElements() {
        var doc = Jsoup.parse("<body />");
        doc.body().setHtml("<form action='http://example.com/search'><input name='q' value='search'>");
        var formEl = doc.select("form").first();
        Assert.isTrue(Std.is(formEl, FormElement));

        var form:FormElement = cast formEl;
        Assert.equals(1, form.getElements().size);
    }

    public function testControlsAddedAfterParseAreLinkedWithForms() {
        var doc = Jsoup.parse("<body />");
        doc.body().setHtml("<form />");

        var formEl = doc.select("form").first();
        formEl.append("<input name=foo value=bar>");

        Assert.isTrue(Std.is(formEl, FormElement));
        var form:FormElement = cast formEl;
        Assert.equals(1, form.getElements().size);

        var data:List<Connection.KeyVal> = form.formData();
        Assert.equals("foo=bar", data.get(0).toString());
    }

    public function testUsesOnForCheckboxValueIfNoValueSet() {
        var doc = Jsoup.parse("<form><input type=checkbox checked name=foo></form>");
        var form:FormElement = cast doc.select("form").first();
        var data:List<Connection.KeyVal> = form.formData();
        Assert.equals("on", data.get(0).getValue());
        Assert.equals("foo", data.get(0).getKey());
    }

    public function testAdoptedFormsRetainInputs() {
        // test for https://github.com/jhy/jsoup/issues/249
        var html = "<html>\n" +
                "<body>  \n" +
                "  <table>\n" +
                "      <form action=\"/hello.php\" method=\"post\">\n" +
                "      <tr><td>User:</td><td> <input type=\"text\" name=\"user\" /></td></tr>\n" +
                "      <tr><td>Password:</td><td> <input type=\"password\" name=\"pass\" /></td></tr>\n" +
                "      <tr><td><input type=\"submit\" name=\"login\" value=\"login\" /></td></tr>\n" +
                "   </form>\n" +
                "  </table>\n" +
                "</body>\n" +
                "</html>";
        var doc = Jsoup.parse(html);
        var form:FormElement = cast doc.select("form").first();
        var data:List<Connection.KeyVal> = form.formData();
        Assert.equals(3, data.size);
        Assert.equals("user", data.get(0).getKey());
        Assert.equals("pass", data.get(1).getKey());
        Assert.equals("login", data.get(2).getKey());
    }
}
