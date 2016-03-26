package org.jsoup.select;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import org.jsoup.helper.StringBuilder;
import org.jsoup.nodes.FormElement;

import org.jsoup.helper.Validate;
import org.jsoup.nodes.Element;
//import org.jsoup.nodes.FormElement;
import org.jsoup.nodes.Node;

//import java.util.*;

/**
 A list of {@link Element}s, with methods that act on every element in the list.
 <p>
 To get an {@code Elements} object, use the {@link Element#select(String)} method.
 </p>

 @author Jonathan Hedley, jonathan@hedley.net */
class Elements extends ArrayList<Element> {
    static public function fromIterable(iterable:Iterable<Element>):Elements {
		var result = new Elements();
		for (el in iterable) result.add(el);
		return result;
	}
	
	public function new(initialCapacity:Int = 1) {
		super(initialCapacity);
    }

    //NOTE(az): removed constructor, added static fromIterable
	/*public Elements(int initialCapacity) {
        super(initialCapacity);
    }

    public Elements(Collection<Element> elements) {
        super(elements);
    }
    
    public Elements(List<Element> elements) {
        super(elements);
    }
    
    public Elements(Element... elements) {
    	super(Arrays.asList(elements));
    }
	*/

    /**
     * Creates a deep copy of these elements.
     * @return a deep copy
     */
    //@Override
	override public function clone(assign:Bool = true, copier:Element->Element = null) {
		var clone = new Elements(size);

        for(e in this)
    		clone.add(e.clone());
    	
    	return clone;
	}

	// attribute methods
    /**
     Get an attribute value from the first matched element that has the attribute.
     @param attributeKey The attribute key.
     @return The attribute value from the first matched element that has the attribute.. If no elements were matched (isEmpty() == true),
     or if the no elements have the attribute, returns empty string.
     @see #hasAttr(String)
     */
	//NOTE(az): renamed to getAttr
    public function getAttr(attributeKey:String):String {
        for (element in this) {
            if (element.hasAttr(attributeKey))
                return element.getAttr(attributeKey);
        }
        return "";
    }

    /**
     Checks if any of the matched elements have this attribute set.
     @param attributeKey attribute key
     @return true if any of the elements have the attribute; false if none do.
     */
    public function hasAttr(attributeKey:String):Bool {
        for (element in this) {
            if (element.hasAttr(attributeKey))
                return true;
        }
        return false;
    }

    /**
     * Set an attribute on all matched elements.
     * @param attributeKey attribute key
     * @param attributeValue attribute value
     * @return this
     */
    //NOTE(az): renamed to setAttr
	public function setAttr(attributeKey:String, attributeValue:String):Elements {
        for (element in this) {
            element.setAttr(attributeKey, attributeValue);
        }
        return this;
    }

    /**
     * Remove an attribute from every matched element.
     * @param attributeKey The attribute to remove.
     * @return this (for chaining)
     */
    public function removeAttr(attributeKey:String):Elements {
        for (element in this) {
            element.removeAttr(attributeKey);
        }
        return this;
    }

    /**
     Add the class name to every matched element's {@code class} attribute.
     @param className class name to add
     @return this
     */
	 public function addClass(className:String):Elements {
        for (element in this) {
            element.addClass(className);
        }
        return this;
    }

    /**
     Remove the class name from every matched element's {@code class} attribute, if present.
     @param className class name to remove
     @return this
     */
    public function removeClass(className:String):Elements {
        for (element in this) {
            element.removeClass(className);
        }
        return this;
    }

    /**
     Toggle the class name on every matched element's {@code class} attribute.
     @param className class name to add if missing, or remove if present, from every element.
     @return this
     */
    public function toggleClass(className:String):Elements {
        for (element in this) {
            element.toggleClass(className);
        }
        return this;
    }

    /**
     Determine if any of the matched elements have this class name set in their {@code class} attribute.
     @param className class name to check for
     @return true if any do, false if none do
     */
    public function hasClass(className:String):Bool {
        for (element in this) {
            if (element.hasClass(className))
                return true;
        }
        return false;
    }
    
    /**
     * Get the form element's value of the first matched element.
     * @return The form element's value, or empty if not set.
     * @see Element#val()
     */
	//NOTE(az): renamed to getVal
    public function getVal():String {
        if (size > 0)
            return first().getVal();
        else
            return "";
    }
    
    /**
     * Set the form element's value in each of the matched elements.
     * @param value The value to set into each matched element
     * @return this (for chaining)
     */
	//NOTE(az): renamed to setVal
    public function setVal(value:String):Elements {
        for (element in this)
            element.setVal(value);
        return this;
    }
    
    /**
     * Get the combined text of all the matched elements.
     * <p>
     * Note that it is possible to get repeats if the matched elements contain both parent elements and their own
     * children, as the Element.text() method returns the combined text of a parent and all its children.
     * @return string of all text: unescaped and no HTML.
     * @see Element#text()
     */
    public function text():String {
        var sb = new StringBuilder();
        for (element in this) {
            if (sb.length != 0)
                sb.add(" ");
            sb.add(element.getText());
        }
        return sb.toString();
    }

    public function hasText():Bool {
        for (element in this) {
            if (element.hasText())
                return true;
        }
        return false;
    }
    
    /**
     * Get the combined inner HTML of all matched elements.
     * @return string of all element's inner HTML.
     * @see #text()
     * @see #outerHtml()
     */
	//NOTE(az): renamed to getHtml
    public function getHtml():String {
        var sb = new StringBuilder();
        for (element in this) {
            if (sb.length != 0)
                sb.add("\n");
            sb.add(element.getHtml());
        }
        return sb.toString();
    }
    
    /**
     * Get the combined outer HTML of all matched elements.
     * @return string of all element's outer HTML.
     * @see #text()
     * @see #html()
     */
    public function outerHtml():String {
        var sb = new StringBuilder();
        for (element in this) {
            if (sb.length != 0)
                sb.add("\n");
            sb.add(element.outerHtml());
        }
        return sb.toString();
    }

    /**
     * Get the combined outer HTML of all matched elements. Alias of {@link #outerHtml()}.
     * @return string of all element's outer HTML.
     * @see #text()
     * @see #html()
     */
    //@Override
    override public function toString():String {
        return outerHtml();
    }

    /**
     * Update the tag name of each matched element. For example, to change each {@code <i>} to a {@code <em>}, do
     * {@code doc.select("i").tagName("em");}
     * @param tagName the new tag name
     * @return this, for chaining
     * @see Element#tagName(String)
     */
    public function tagName(tagName:String):Elements{
        for (element in this) {
            element.setTagName(tagName);
        }
        return this;
    }
    
    /**
     * Set the inner HTML of each matched element.
     * @param html HTML to parse and set into each matched element.
     * @return this, for chaining
     * @see Element#html(String)
     */
	//NOTE(az): renamed to setHtml
    public function setHtml(html:String):Elements {
        for (element in this) {
            element.setHtml(html);
        }
        return this;
    }
    
    /**
     * Add the supplied HTML to the start of each matched element's inner HTML.
     * @param html HTML to add inside each element, before the existing HTML
     * @return this, for chaining
     * @see Element#prepend(String)
     */
    public function prepend(html:String):Elements {
        for (element in this) {
            element.prepend(html);
        }
        return this;
    }
    
    /**
     * Add the supplied HTML to the end of each matched element's inner HTML.
     * @param html HTML to add inside each element, after the existing HTML
     * @return this, for chaining
     * @see Element#append(String)
     */
    public function append(html:String):Elements {
        for (element in this) {
            element.append(html);
        }
        return this;
    }
    
    /**
     * Insert the supplied HTML before each matched element's outer HTML.
     * @param html HTML to insert before each element
     * @return this, for chaining
     * @see Element#before(String)
     */
    public function before(html:String):Elements {
        for (element in this) {
            element.before(html);
        }
        return this;
    }
    
    /**
     * Insert the supplied HTML after each matched element's outer HTML.
     * @param html HTML to insert after each element
     * @return this, for chaining
     * @see Element#after(String)
     */
    public function after(html:String):Elements {
        for (element in this) {
            element.after(html);
        }
        return this;
    }

    /**
     Wrap the supplied HTML around each matched elements. For example, with HTML
     {@code <p><b>This</b> is <b>Jsoup</b></p>},
     <code>doc.select("b").wrap("&lt;i&gt;&lt;/i&gt;");</code>
     becomes {@code <p><i><b>This</b></i> is <i><b>jsoup</b></i></p>}
     @param html HTML to wrap around each element, e.g. {@code <div class="head"></div>}. Can be arbitrarily deep.
     @return this (for chaining)
     @see Element#wrap
     */
    public function wrap(html:String):Elements {
        Validate.notEmpty(html);
        for (element in this) {
            element.wrap(html);
        }
        return this;
    }

    /**
     * Removes the matched elements from the DOM, and moves their children up into their parents. This has the effect of
     * dropping the elements but keeping their children.
     * <p>
     * This is useful for e.g removing unwanted formatting elements but keeping their contents.
     * </p>
     * 
     * E.g. with HTML: <p>{@code <div><font>One</font> <font><a href="/">Two</a></font></div>}</p>
     * <p>{@code doc.select("font").unwrap();}</p>
     * <p>HTML = {@code <div>One <a href="/">Two</a></div>}</p>
     *
     * @return this (for chaining)
     * @see Node#unwrap
     */
    public function unwrap():Elements {
        for (element in this) {
            element.unwrap();
        }
        return this;
    }

    /**
     * Empty (remove all child nodes from) each matched element. This is similar to setting the inner HTML of each
     * element to nothing.
     * <p>
     * E.g. HTML: {@code <div><p>Hello <b>there</b></p> <p>now</p></div>}<br>
     * <code>doc.select("p").empty();</code><br>
     * HTML = {@code <div><p></p> <p></p></div>}
     * @return this, for chaining
     * @see Element#empty()
     * @see #remove()
     */
	public function empty():Elements {
        for (element in this) {
            element.empty();
        }
        return this;
    }

    /**
     * Remove each matched element from the DOM. This is similar to setting the outer HTML of each element to nothing.
     * <p>
     * E.g. HTML: {@code <div><p>Hello</p> <p>there</p> <img /></div>}<br>
     * <code>doc.select("p").remove();</code><br>
     * HTML = {@code <div> <img /></div>}
     * <p>
     * Note that this method should not be used to clean user-submitted HTML; rather, use {@link org.jsoup.safety.Cleaner} to clean HTML.
     * @return this, for chaining
     * @see Element#empty()
     * @see #empty()
     */
    public function removeMatched():Elements {
        for (element in this) {
            element.remove();
        }
        return this;
    }
    
    // filters
    
    /**
     * Find matching elements within this element list.
     * @param query A {@link Selector} query
     * @return the filtered list of elements, or an empty list if none match.
     */
    public function select(query:String):Elements {
        return Selector.selectIn(query, this);
    }

    /**
     * Remove elements from this list that match the {@link Selector} query.
     * <p>
     * E.g. HTML: {@code <div class=logo>One</div> <div>Two</div>}<br>
     * <code>Elements divs = doc.select("div").not("#logo");</code><br>
     * Result: {@code divs: [<div>Two</div>]}
     * <p>
     * @param query the selector query whose results should be removed from these elements
     * @return a new elements list that contains only the filtered results
     */
	public function not(query:String):Elements {
        var out:Elements = Selector.selectIn(query, this);
        return Selector.filterOut(this, out);
    }
    
    /**
     * Get the <i>nth</i> matched element as an Elements object.
     * <p>
     * See also {@link #get(int)} to retrieve an Element.
     * @param index the (zero-based) index of the element in the list to retain
     * @return Elements containing only the specified element, or, if that element did not exist, an empty list.
     */
    public function eq(index:Int):Elements {
        return size > index ? Elements.fromIterable([get(index)]) : new Elements();
    }
    
    /**
     * Test if any of the matched elements match the supplied query.
     * @param query A selector
     * @return true if at least one element in the list matches the query.
     */
    public function is(query:String):Bool {
        var children:Elements = select(query);
        return !children.isEmpty();
    }

    /**
     * Get all of the parents and ancestor elements of the matched elements.
     * @return all of the parents and ancestor elements of the matched elements
     */
	//NOTE(az): using ListSet from polygonal, check addAll
    public function parents():Elements {
        var combo:Set<Element> = new ListSet<Element>();
        for (e in this) {
            for (p in e.parents()) combo.set(p);
        }
        return Elements.fromIterable(combo);
    }

    // list-like methods
    /**
     Get the first matched element.
     @return The first matched element, or <code>null</code> if contents is empty.
     */
    public function first():Element {
        return isEmpty() ? null : get(0);
    }

    /**
     Get the last matched element.
     @return The last matched element, or <code>null</code> if contents is empty.
     */
    public function last():Element {
        return isEmpty() ? null : get(size - 1);
    }

    /**
     * Perform a depth-first traversal on each of the selected elements.
     * @param nodeVisitor the visitor callbacks to perform on each node
     * @return this, for chaining
     */
    public function traverse(nodeVisitor:NodeVisitor):Elements {
        Validate.notNull(nodeVisitor);
        var traversor:NodeTraversor = new NodeTraversor(nodeVisitor);
        for (el in this) {
            traversor.traverse(el);
        }
        return this;
    }

    /**
     * Get the {@link FormElement} forms from the selected elements, if any.
     * @return a list of {@link FormElement}s pulled from the matched elements. The list will be empty if the elements contain
     * no forms.
     */
    public function forms():List<FormElement> {
        var forms = new ArrayList<FormElement>();
        for (el in this)
            if (Std.is(el, FormElement))
                forms.add(cast el);
        return cast forms;
    }

}
