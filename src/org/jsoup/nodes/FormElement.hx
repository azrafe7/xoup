package org.jsoup.nodes;

import de.polygonal.ds.ArrayList;
import org.jsoup.Connection;
import org.jsoup.helper.HttpConnection;
import org.jsoup.helper.HttpConnection.KeyVal;
import org.jsoup.helper.Validate;
import org.jsoup.parser.Tag;
import org.jsoup.select.Elements;

//NOTE(az): skipping Connection related stuff


/*import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.helper.HttpConnection;
import org.jsoup.helper.Validate;
import org.jsoup.parser.Tag;
import org.jsoup.select.Elements;

import java.util.ArrayList;
import java.util.List;*/

/**
 * A HTML Form Element provides ready access to the form fields/controls that are associated with it. It also allows a
 * form to easily be submitted.
 */
class FormElement extends Element {
    private var elements:Elements = new Elements();

    /**
     * Create a new, standalone form element.
     *
     * @param tag        tag of this element
     * @param baseUri    the base URI
     * @param attributes initial attributes
     */
    public function new(tag:Tag, baseUri:String, attributes:Attributes) {
        super(tag, baseUri, attributes);
    }

    /**
     * Get the list of form control elements associated with this form.
     * @return form controls associated with this element.
     */
	//NOTE(az): getter
    public function getElements():Elements {
        return elements;
    }

    /**
     * Add a form control element to this form.
     * @param element form control to add
     * @return this form element, for chaining
     */
    public function addElement(element:Element):FormElement {
        elements.add(element);
        return this;
    }

    /**
     * Prepare to submit this form. A Connection object is created with the request set up from the form values. You
     * can then set up other options (like user-agent, timeout, cookies), then execute it.
     * @return a connection prepared from the values of this form.
     * @throws IllegalArgumentException if the form's absolute action URL cannot be determined. Make sure you pass the
     * document's base URI when parsing.
     */
    /*public function submit():Connection {
        var action:String = hasAttr("action") ? absUrl("action") : getBaseUri();
        Validate.notEmpty(action, "Could not determine a form action URL for submit. Ensure you set a base URI when parsing.");
        Connection.Method method = attr("method").toUpperCase().equals("POST") ?
                Connection.Method.POST : Connection.Method.GET;

        return Jsoup.connect(action)
                .data(formData())
                .method(method);
    }*/

    /**
     * Get the data that this form submits. The returned list is a copy of the data, and changes to the contents of the
     * list will not be reflected in the DOM.
     * @return a list of key vals
     */
    public function formData():List<Connection.KeyVal> {
        var data = new ArrayList<Connection.KeyVal>();

        // iterate the form control elements and accumulate their values
        for (el in elements) {
            if (!el.getTag().isFormSubmittable()) continue; // contents are form listable, superset of submitable
            if (el.hasAttr("disabled")) continue; // skip disabled form inputs
            var name:String = el.getAttr("name");
            if (name.length == 0) continue;
            var type:String = el.getAttr("type");

            if ("select" == (el.getTagName())) {
                var options:Elements = el.select("option[selected]");
                var set:Bool = false;
                for (option in options) {
                    data.add(KeyVal.create(name, option.getVal()));
                    set = true;
                }
                if (!set) {
                    var option:Element = el.select("option").first();
                    if (option != null)
                        data.add(KeyVal.create(name, option.getVal()));
                }
            } else if ("checkbox" == type.toLowerCase() || "radio" == type.toLowerCase()) {
                // only add checkbox or radio if they have the checked attribute
                if (el.hasAttr("checked")) {
                    var val:String = el.getVal().length >  0 ? el.getVal() : "on";
                    data.add(KeyVal.create(name, val));
                }
            } else {
                data.add(KeyVal.create(name, el.getVal()));
            }
        }
        return cast data;
    }
}
