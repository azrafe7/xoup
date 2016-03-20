package org.jsoup.nodes;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.Dll;
import de.polygonal.ds.List;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import org.jsoup.Exceptions.IllegalArgumentException;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Attributes.Dataset;
import org.jsoup.parser.Parser;
import org.jsoup.select.Collector;
import org.jsoup.select.Elements;
import org.jsoup.select.Evaluator;
import org.jsoup.select.Evaluator.*;
import org.jsoup.parser.Tag;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;
import org.jsoup.helper.StringUtil;
import org.jsoup.select.Selector;

using StringTools;

/*import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.helper.Validate;
import org.jsoup.helper.Validate;
import org.jsoup.helper.Validate;
import org.jsoup.parser.Parser;
import org.jsoup.parser.Tag;
import org.jsoup.select.*;

import java.util.*;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;
*/

/**
 * A HTML element consists of a tag name, attributes, and child nodes (including text nodes and
 * other elements).
 * 
 * From an Element, you can extract data, traverse the node graph, and manipulate the HTML.
 * 
 * @author Jonathan Hedley, jonathan@hedley.net
 */
@:access(org.jsoup.select.Evaluator)
class Element extends Node {
    private var tag:Tag;

    private static var classSplit:EReg = ~/\s+/;

    /**
     * Create a new, standalone Element. (Standalone in that is has no parent.)
     * 
     * @param tag tag of this element
     * @param baseUri the base URI
     * @param attributes initial attributes
     * @see #appendChild(Node)
     * @see #appendElement(String)
     */
	public function new(tag:Tag, baseUri:String, attributes:Attributes) {
        super(baseUri, attributes);
        
        Validate.notNull(tag);    
        this.tag = tag;
    }
    
    //@Override
    override public function nodeName():String {
        return tag.getName();
    }

    /**
     * Get the name of the tag for this element. E.g. {@code div}
     * 
     * @return the tag name
     */
	//NOTE(az): getter
    public function getTagName():String {
        return tag.getName();
    }

    /**
     * Change the tag of this element. For example, convert a {@code <span>} to a {@code <div>} with
     * {@code el.tagName("div");}.
     *
     * @param tagName new tag name for this element
     * @return this element, for chaining
     */
	//NOTE(az): setter
    public function setTagName(tagName:String):Element {
        Validate.notEmpty(tagName, "Tag name must not be empty.");
        tag = Tag.valueOf(tagName);
        return this;
    }

    /**
     * Get the Tag for this element.
     * 
     * @return the tag object
     */
	//NOTE(az): getter
    public function getTag():Tag {
        return tag;
    }
    
    /**
     * Test if this element is a block-level element. (E.g. {@code <div> == true} or an inline element
     * {@code <p> == false}).
     * 
     * @return true if block, false if not (and thus inline)
     */
    public function isBlock():Bool {
        return tag.isBlock();
    }

    /**
     * Get the {@code id} attribute of this element.
     * 
     * @return The id attribute, if present, or an empty string if not.
     */
    public function id():String {
        return attributes.get("id");
    }

    /**
     * Set an attribute value on this element. If this element already has an attribute with the
     * key, its value is updated; otherwise, a new attribute is added.
     * 
     * @return this element
     */
	//NOTE(az): unified with method below, Dynamic?, remember to copy docs
    override public function setAttr(attributeKey:String, attributeValue:Dynamic):Element {
        if (Std.is(attributeValue, String)) super.setAttr(attributeKey, attributeValue);
		else if (Std.is(attributeValue, Bool)) attributes.put(attributeKey, attributeValue);
		else throw "Invalid attributeValue";
        return this;
    }
    
    /**
     * Set a boolean attribute value on this element. Setting to <code>true</code> sets the attribute value to "" and
     * marks the attribute as boolean so no value is written out. Setting to <code>false</code> removes the attribute
     * with the same key if it exists.
     * 
     * @param attributeKey the attribute key
     * @param attributeValue the attribute value
     * 
     * @return this element
     */
    /*public Element attr(String attributeKey, boolean attributeValue) {
        attributes.put(attributeKey, attributeValue);
        return this;
    }*/

    /**
     * Get this element's HTML5 custom data attributes. Each attribute in the element that has a key
     * starting with "data-" is included the dataset.
     * <p>
     * E.g., the element {@code <div data-package="jsoup" data-language="Java" class="group">...} has the dataset
     * {@code package=jsoup, language=java}.
     * <p>
     * This map is a filtered view of the element's attribute map. Changes to one map (add, remove, update) are reflected
     * in the other map.
     * <p>
     * You can find elements that have data attributes using the {@code [^data-]} attribute key prefix selector.
     * @return a map of {@code key=value} custom data attributes.
     */
    public function dataset():Dataset {
        return attributes.dataset();
    }

    //@Override
    override public function parent():Element {
        return cast parentNode;
    }

    /**
     * Get this element's parent and ancestors, up to the document root.
     * @return this element's stack of parents, closest first.
     */
    public function parents():Elements {
        var parents = new Elements();
        accumulateParents(this, parents);
        return parents;
    }

    private static function accumulateParents(el:Element, parents:Elements):Void {
        var parent:Element = el.parent();
        if (parent != null && !(parent.getTagName() == "#root")) {
            parents.add(parent);
            accumulateParents(parent, parents);
        }
    }

    /**
     * Get a child element of this element, by its 0-based index number.
     * <p>
     * Note that an element can have both mixed Nodes and Elements as children. This method inspects
     * a filtered list of children that are elements, and the index is based on that filtered list.
     * </p>
     * 
     * @param index the index number of the element to retrieve
     * @return the child element, if it exists, otherwise throws an {@code IndexOutOfBoundsException}
     * @see #childNode(int)
     */
    public function child(index:Int):Element {
        return children().get(index);
    }

    /**
     * Get this element's child elements.
     * <p>
     * This is effectively a filter on {@link #childNodes()} to get Element nodes.
     * </p>
     * @return child elements. If this element has no children, returns an
     * empty list.
     * @see #childNodes()
     */
    public function children():Elements {
        // create on the fly rather than maintaining two lists. if gets slow, memoize, and mark dirty on change
        var elements = new ArrayList<Element>(childNodes.size);
        for (node in childNodes) {
            if (Std.is(node, Element))
                elements.add(cast node);
        }
        return Elements.fromIterable(elements);
    }

    /**
     * Get this element's child text nodes. The list is unmodifiable but the text nodes may be manipulated.
     * <p>
     * This is effectively a filter on {@link #childNodes()} to get Text nodes.
     * @return child text nodes. If this element has no text nodes, returns an
     * empty list.
     * </p>
     * For example, with the input HTML: {@code <p>One <span>Two</span> Three <br> Four</p>} with the {@code p} element selected:
     * <ul>
     *     <li>{@code p.text()} = {@code "One Two Three Four"}</li>
     *     <li>{@code p.ownText()} = {@code "One Three Four"}</li>
     *     <li>{@code p.children()} = {@code Elements[<span>, <br>]}</li>
     *     <li>{@code p.childNodes()} = {@code List<Node>["One ", <span>, " Three ", <br>, " Four"]}</li>
     *     <li>{@code p.textNodes()} = {@code List<TextNode>["One ", " Three ", " Four"]}</li>
     * </ul>
     */
	//NOTE(az): unmodifiable
    public function textNodes():List<TextNode> {
        var textNodes = new ArrayList<TextNode>();
        for (node in childNodes) {
            if (Std.is(node, TextNode))
                textNodes.add(cast node);
        }
        //return Collections.unmodifiableList(textNodes);
		return textNodes;
    }

    /**
     * Get this element's child data nodes. The list is unmodifiable but the data nodes may be manipulated.
     * <p>
     * This is effectively a filter on {@link #childNodes()} to get Data nodes.
     * </p>
     * @return child data nodes. If this element has no data nodes, returns an
     * empty list.
     * @see #data()
     */
	//NOTE(az): unmodifiable
    public function dataNodes():List<DataNode> {
        var dataNodes = new ArrayList<DataNode>();
        for (node in childNodes) {
            if (Std.is(node, DataNode))
                dataNodes.add(cast node);
        }
        //return Collections.unmodifiableList(dataNodes);
        return dataNodes;
    }

    /**
     * Find elements that match the {@link Selector} CSS query, with this element as the starting context. Matched elements
     * may include this element, or any of its children.
     * <p>
     * This method is generally more powerful to use than the DOM-type {@code getElementBy*} methods, because
     * multiple filters can be combined, e.g.:
     * </p>
     * <ul>
     * <li>{@code el.select("a[href]")} - finds links ({@code a} tags with {@code href} attributes)
     * <li>{@code el.select("a[href*=example.com]")} - finds links pointing to example.com (loosely)
     * </ul>
     * <p>
     * See the query syntax documentation in {@link org.jsoup.select.Selector}.
     * </p>
     * 
     * @param cssQuery a {@link Selector} CSS-like query
     * @return elements that match the query (empty if none match)
     * @see org.jsoup.select.Selector
     * @throws Selector.SelectorParseException (unchecked) on an invalid CSS query.
     */
    public function select(cssQuery:String):Elements {
        return Selector.select(cssQuery, this);
    }
    
    /**
     * Add a node child node to this element.
     * 
     * @param child node to add.
     * @return this element, so that you can add more child nodes or elements.
     */
    public function appendChild(child:Node):Element {
        Validate.notNull(child);

        // was - Node#addChildren(child). short-circuits an array create and a loop.
        reparentChild(child);
        ensureChildNodes();
        childNodes.add(child);
        child.setSiblingIndex(childNodes.size - 1);
        return this;
    }

    /**
     * Add a node to the start of this element's children.
     * 
     * @param child node to add.
     * @return this element, so that you can add more child nodes or elements.
     */
    public function prependChild(child:Node):Element {
        Validate.notNull(child);
        
        addChildrenAt(0, [child]);
        return this;
    }


    /**
     * Inserts the given child nodes into this element at the specified index. Current nodes will be shifted to the
     * right. The inserted nodes will be moved from their current parent. To prevent moving, copy the nodes first.
     *
     * @param index 0-based index to insert children at. Specify {@code 0} to insert at the start, {@code -1} at the
     * end
     * @param children child nodes to insert
     * @return this element, for chaining.
     */
	//NOTE(az): Collection<? extends Node>, recheck logic
    public function insertChildren(index:Int, children:Iterable<Node>):Element {
        Validate.notNull(children, "Children collection to be inserted must not be null.");
        var currentSize = childNodeSize();
        if (index < 0) index += currentSize +1; // roll around
        Validate.isTrue(index >= 0 && index <= currentSize, "Insert position out of bounds.");

        /*ArrayList<Node> nodes = new ArrayList<Node>();
        Node[] nodeArray = nodes.toArray(new Node[nodes.size()]);
        addChildren(index, nodeArray);*/
        addChildrenAt(index, children);
        return this;
    }
    
    /**
     * Create a new element by tag name, and add it as the last child.
     * 
     * @param tagName the name of the tag (e.g. {@code div}).
     * @return the new element, to allow you to add content to it, e.g.:
     *  {@code parent.appendElement("h1").attr("id", "header").text("Welcome");}
     */
    public function appendElement(tagName:String):Element {
        var child = new Element(Tag.valueOf(tagName), getBaseUri(), new Attributes());
        appendChild(child);
        return child;
    }
    
    /**
     * Create a new element by tag name, and add it as the first child.
     * 
     * @param tagName the name of the tag (e.g. {@code div}).
     * @return the new element, to allow you to add content to it, e.g.:
     *  {@code parent.prependElement("h1").attr("id", "header").text("Welcome");}
     */
    public function prependElement(tagName:String):Element {
        var child:Element = new Element(Tag.valueOf(tagName), getBaseUri(), new Attributes());
        prependChild(child);
        return child;
    }
    
    /**
     * Create and append a new TextNode to this element.
     * 
     * @param text the unencoded text to add
     * @return this element
     */
    public function appendText(text:String):Element {
        var node = new TextNode(text, getBaseUri());
        appendChild(node);
        return this;
    }
    
    /**
     * Create and prepend a new TextNode to this element.
     * 
     * @param text the unencoded text to add
     * @return this element
     */
    public function prependText(text:String):Element {
        var node = new TextNode(text, getBaseUri());
        prependChild(node);
        return this;
    }
    
    /**
     * Add inner HTML to this element. The supplied HTML will be parsed, and each node appended to the end of the children.
     * @param html HTML to add inside this element, after the existing HTML
     * @return this element
     * @see #html(String)
     */
	//NOTE(az): why toArray first?
    public function append(html:String):Element {
        Validate.notNull(html);

        var nodes:List<Node> = Parser.parseFragment(html, this, getBaseUri());
        //addChildren(nodes.toArray(new Node[nodes.size()]));
        addChildren(nodes);
        return this;
    }
    
    /**
     * Add inner HTML into this element. The supplied HTML will be parsed, and each node prepended to the start of the element's children.
     * @param html HTML to add inside this element, before the existing HTML
     * @return this element
     * @see #html(String)
     */
	//NOTE(az): why toArray first?
    public function prepend(html:String):Element {
        Validate.notNull(html);
        
        var nodes:List<Node> = Parser.parseFragment(html, this, getBaseUri());
        //addChildren(0, nodes.toArray(new Node[nodes.size()]));
        addChildrenAt(0, nodes.toArray());
        return this;
    }

    /**
     * Insert the specified HTML into the DOM before this element (as a preceding sibling).
     *
     * @param html HTML to add before this element
     * @return this element, for chaining
     * @see #after(String)
     */
    //@Override
    override public function before(html:String):Element {
        return cast super.before(html);
    }

    /**
     * Insert the specified node into the DOM before this node (as a preceding sibling).
     * @param node to add before this element
     * @return this Element, for chaining
     * @see #after(Node)
     */
    //@Override
    override public function beforeNode(node:Node):Element {
        return cast super.beforeNode(node);
    }

    /**
     * Insert the specified HTML into the DOM after this element (as a following sibling).
     *
     * @param html HTML to add after this element
     * @return this element, for chaining
     * @see #before(String)
     */
    //@Override
    override public function after(html:String):Element {
        return cast super.after(html);
    }

    /**
     * Insert the specified node into the DOM after this node (as a following sibling).
     * @param node to add after this element
     * @return this element, for chaining
     * @see #before(Node)
     */
    //@Override
    override public function afterNode(node:Node):Element {
        return cast super.afterNode(node);
    }

    /**
     * Remove all of the element's child nodes. Any attributes are left as-is.
     * @return this element
     */
    public function empty():Element {
        childNodes.clear();
        return this;
    }

    /**
     * Wrap the supplied HTML around this element.
     *
     * @param html HTML to wrap around this element, e.g. {@code <div class="head"></div>}. Can be arbitrarily deep.
     * @return this element, for chaining.
     */
    //@Override
	override public function wrap(html:String):Element {
        return cast super.wrap(html);
    }

    /**
     * Get a CSS selector that will uniquely select this element.
     * <p>
     * If the element has an ID, returns #id;
     * otherwise returns the parent (if any) CSS selector, followed by {@literal '>'},
     * followed by a unique selector for the element (tag.class.class:nth-child(n)).
     * </p>
     *
     * @return the CSS Path that can be used to retrieve the element in a selector.
     */
	//NOTE(az): recheck
    public function cssSelector():String {
        if (id().length > 0)
            return "#" + id();

        var selector = new StringBuf();
		selector.add(getTagName());
        var classes:String = StringUtil.join(getClassNames().iterator(), ".");
        if (classes.length > 0) {
            selector.add('.');
			selector.add(classes);
		}

        if (parent() == null || Std.is(parent(), Document)) // don't add Document to selector, as will always have a html node
            return selector.toString();

        var newSelector = new StringBuf();
		newSelector.add(" > ");
		newSelector.add(selector);
		
        if (parent().select(newSelector.toString()).size > 1)
            newSelector.add(':nth-child(${elementSiblingIndex() + 1})');

        return parent().cssSelector() + newSelector.toString();
    }

    /**
     * Get sibling elements. If the element has no sibling elements, returns an empty list. An element is not a sibling
     * of itself, so will not be included in the returned list.
     * @return sibling elements
     */
    public function siblingElements():Elements {
        if (parentNode == null)
            return new Elements(0);

        var elements:List<Element> = parent().children();
        var siblings = new Elements(elements.size - 1);
        for (el in elements)
            if (el != this)
                siblings.add(el);
        return siblings;
    }

    /**
     * Gets the next sibling element of this element. E.g., if a {@code div} contains two {@code p}s, 
     * the {@code nextElementSibling} of the first {@code p} is the second {@code p}.
     * <p>
     * This is similar to {@link #nextSibling()}, but specifically finds only Elements
     * </p>
     * @return the next element, or null if there is no next element
     * @see #previousElementSibling()
     */
    public function nextElementSibling():Element {
        if (parentNode == null) return null;
        var siblings:List<Element> = parent().children();
        var index:Null<Int> = indexInList(this, siblings);
        Validate.notNull(index);
        if (siblings.size > index+1)
            return siblings.get(index+1);
        else
            return null;
    }

    /**
     * Gets the previous element sibling of this element.
     * @return the previous element, or null if there is no previous element
     * @see #nextElementSibling()
     */
    public function previousElementSibling():Element {
        if (parentNode == null) return null;
        var siblings:List<Element> = parent().children();
        var index:Null<Int> = indexInList(this, siblings);
        Validate.notNull(index);
        if (index > 0)
            return siblings.get(index-1);
        else
            return null;
    }

    /**
     * Gets the first element sibling of this element.
     * @return the first sibling that is an element (aka the parent's first element child) 
     */
    public function firstElementSibling():Element {
        // todo: should firstSibling() exclude this?
        var siblings:List<Element> = parent().children();
        return siblings.size > 1 ? siblings.get(0) : null;
    }
    
    /**
     * Get the list index of this element in its element sibling list. I.e. if this is the first element
     * sibling, returns 0.
     * @return position in element sibling list
     */
    public function elementSiblingIndex():Null<Int> {
       if (parent() == null) return 0;
       return indexInList(this, parent().children()); 
    }

    /**
     * Gets the last element sibling of this element
     * @return the last sibling that is an element (aka the parent's last element child) 
     */
    public function lastElementSibling():Element {
        var siblings:List<Element> = parent().children();
        return siblings.size > 1 ? siblings.get(siblings.size - 1) : null;
    }
    
    //NOTE(az): type param, and Null<Int>
	private static function indexInList<E>(search:E, elements:List<E>):Null<Int> {
        Validate.notNull(search);
        Validate.notNull(elements);

        for (i in 0...elements.size) {
            var element:E = elements.get(i);
            if (element == search)
                return i;
        }
        return null;
    }

    // DOM type methods

    /**
     * Finds elements, including and recursively under this element, with the specified tag name.
     * @param tagName The tag name to search for (case insensitively).
     * @return a matching unmodifiable list of elements. Will be empty if this element and none of its children match.
     */
    public function getElementsByTag(tagName:String):Elements {
        Validate.notEmpty(tagName);
        tagName = tagName.toLowerCase().trim();

        return Collector.collect(new EvaluatorTag(tagName), this);
    }

    /**
     * Find an element by ID, including or under this element.
     * <p>
     * Note that this finds the first matching ID, starting with this element. If you search down from a different
     * starting point, it is possible to find a different element by ID. For unique element by ID within a Document,
     * use {@link Document#getElementById(String)}
     * @param id The ID to search for.
     * @return The first matching element by ID, starting with this element, or null if none found.
     */
	 public function getElementById(id:String):Element {
        Validate.notEmpty(id);
        
        var elements:Elements = Collector.collect(new EvaluatorId(id), this);
        if (elements.size > 0)
            return elements.get(0);
        else
            return null;
    }

    /**
     * Find elements that have this class, including or under this element. Case insensitive.
     * <p>
     * Elements can have multiple classes (e.g. {@code <div class="header round first">}. This method
     * checks each class, so you can find the above with {@code el.getElementsByClass("header");}.
     * 
     * @param className the name of the class to search for.
     * @return elements with the supplied class name, empty if none
     * @see #hasClass(String)
     * @see #classNames()
     */
    public function getElementsByClass(className:String):Elements {
        Validate.notEmpty(className);

        return Collector.collect(new EvaluatorClass(className), this);
    }

    /**
     * Find elements that have a named attribute set. Case insensitive.
     *
     * @param key name of the attribute, e.g. {@code href}
     * @return elements that have this attribute, empty if none
     */
    public function getElementsByAttribute(key:String):Elements {
        Validate.notEmpty(key);
        key = key.trim().toLowerCase();

        return Collector.collect(new EvaluatorAttribute(key), this);
    }

    /**
     * Find elements that have an attribute name starting with the supplied prefix. Use {@code data-} to find elements
     * that have HTML5 datasets.
     * @param keyPrefix name prefix of the attribute e.g. {@code data-}
     * @return elements that have attribute names that start with with the prefix, empty if none.
     */
    public function getElementsByAttributeStarting(keyPrefix:String):Elements {
        Validate.notEmpty(keyPrefix);
        keyPrefix = keyPrefix.trim().toLowerCase();

        return Collector.collect(new EvaluatorAttributeStarting(keyPrefix), this);
    }

    /**
     * Find elements that have an attribute with the specific value. Case insensitive.
     * 
     * @param key name of the attribute
     * @param value value of the attribute
     * @return elements that have this attribute with this value, empty if none
     */
    public function getElementsByAttributeValue(key:String, value:String):Elements {
        return Collector.collect(new EvaluatorAttributeWithValue(key, value), this);
    }

    /**
     * Find elements that either do not have this attribute, or have it with a different value. Case insensitive.
     * 
     * @param key name of the attribute
     * @param value value of the attribute
     * @return elements that do not have a matching attribute
     */
    public function getElementsByAttributeValueNot(key:String, value:String):Elements {
        return Collector.collect(new EvaluatorAttributeWithValueNot(key, value), this);
    }

    /**
     * Find elements that have attributes that start with the value prefix. Case insensitive.
     * 
     * @param key name of the attribute
     * @param valuePrefix start of attribute value
     * @return elements that have attributes that start with the value prefix
     */
    public function getElementsByAttributeValueStarting(key:String, valuePrefix:String):Elements {
        return Collector.collect(new EvaluatorAttributeWithValueStarting(key, valuePrefix), this);
    }

    /**
     * Find elements that have attributes that end with the value suffix. Case insensitive.
     * 
     * @param key name of the attribute
     * @param valueSuffix end of the attribute value
     * @return elements that have attributes that end with the value suffix
     */
    public function getElementsByAttributeValueEnding(key:String, valueSuffix:String):Elements {
        return Collector.collect(new EvaluatorAttributeWithValueEnding(key, valueSuffix), this);
    }

    /**
     * Find elements that have attributes whose value contains the match string. Case insensitive.
     * 
     * @param key name of the attribute
     * @param match substring of value to search for
     * @return elements that have attributes containing this text
     */
    public function getElementsByAttributeValueContaining(key:String, match:String):Elements {
        return Collector.collect(new EvaluatorAttributeWithValueContaining(key, match), this);
    }
    
    /**
     * Find elements that have attributes whose values match the supplied regular expression.
     * @param key name of the attribute
     * @param pattern compiled regular expression to match against attribute values
     * @return elements that have attributes matching this regular expression
     */
    public function getElementsByAttributeValueMatchingPattern(key:String, pattern:EReg):Elements {
        return Collector.collect(new EvaluatorAttributeWithValueMatching(key, pattern), this);
        
    }
    
    /**
     * Find elements that have attributes whose values match the supplied regular expression.
     * @param key name of the attribute
     * @param regex regular expression to match against attribute values. You can use <a href="http://java.sun.com/docs/books/tutorial/essential/regex/pattern.html#embedded">embedded flags</a> (such as (?i) and (?m) to control regex options.
     * @return elements that have attributes matching this regular expression
     */
	//NOTE(az): check regex options
    public function getElementsByAttributeValueMatching(key:String, regex:String):Elements {
        var pattern;
        try {
            pattern = new EReg(regex, "");
        } catch (e:Dynamic) {
            throw new IllegalArgumentException("Pattern syntax error: " + regex + ". " +  e);
        }
        return getElementsByAttributeValueMatchingPattern(key, pattern);
    }
    
    /**
     * Find elements whose sibling index is less than the supplied index.
     * @param index 0-based index
     * @return elements less than index
     */
    public function getElementsByIndexLessThan(index:Int):Elements {
        return Collector.collect(new EvaluatorIndexLessThan(index), this);
    }
    
    /**
     * Find elements whose sibling index is greater than the supplied index.
     * @param index 0-based index
     * @return elements greater than index
     */
    public function getElementsByIndexGreaterThan(index:Int):Elements {
        return Collector.collect(new EvaluatorIndexGreaterThan(index), this);
    }
    
    /**
     * Find elements whose sibling index is equal to the supplied index.
     * @param index 0-based index
     * @return elements equal to index
     */
    public function getElementsByIndexEquals(index:Int):Elements {
        return Collector.collect(new EvaluatorIndexEquals(index), this);
    }
    
    /**
     * Find elements that contain the specified string. The search is case insensitive. The text may appear directly
     * in the element, or in any of its descendants.
     * @param searchText to look for in the element's text
     * @return elements that contain the string, case insensitive.
     * @see Element#text()
     */
    public function getElementsContainingText(searchText:String):Elements {
        return Collector.collect(new EvaluatorContainsText(searchText), this);
    }
    
    /**
     * Find elements that directly contain the specified string. The search is case insensitive. The text must appear directly
     * in the element, not in any of its descendants.
     * @param searchText to look for in the element's own text
     * @return elements that contain the string, case insensitive.
     * @see Element#ownText()
     */
    public function getElementsContainingOwnText(searchText:String):Elements {
        return Collector.collect(new EvaluatorContainsOwnText(searchText), this);
    }
    
    /**
     * Find elements whose text matches the supplied regular expression.
     * @param pattern regular expression to match text against
     * @return elements matching the supplied regular expression.
     * @see Element#text()
     */
    public function getElementsMatchingTextPattern(pattern:EReg):Elements {
        return Collector.collect(new EvaluatorMatches(pattern), this);
    }
    
    /**
     * Find elements whose text matches the supplied regular expression.
     * @param regex regular expression to match text against. You can use <a href="http://java.sun.com/docs/books/tutorial/essential/regex/pattern.html#embedded">embedded flags</a> (such as (?i) and (?m) to control regex options.
     * @return elements matching the supplied regular expression.
     * @see Element#text()
     */
    public function getElementsMatchingText(regex:String):Elements {
        var pattern;
        try {
            pattern = new EReg(regex, "");
        } catch (e:Dynamic) {
            throw new IllegalArgumentException("Pattern syntax error: " + regex + ". " + e);
        }
        return getElementsMatchingTextPattern(pattern);
    }
    
    /**
     * Find elements whose own text matches the supplied regular expression.
     * @param pattern regular expression to match text against
     * @return elements matching the supplied regular expression.
     * @see Element#ownText()
     */
    public function getElementsMatchingOwnTextPattern(pattern:EReg):Elements {
        return Collector.collect(new EvaluatorMatchesOwn(pattern), this);
    }
    
    /**
     * Find elements whose text matches the supplied regular expression.
     * @param regex regular expression to match text against. You can use <a href="http://java.sun.com/docs/books/tutorial/essential/regex/pattern.html#embedded">embedded flags</a> (such as (?i) and (?m) to control regex options.
     * @return elements matching the supplied regular expression.
     * @see Element#ownText()
     */
    public function getElementsMatchingOwnText(regex:String):Elements {
        var pattern;
        try {
            pattern = new EReg(regex, "");
        } catch (e:Dynamic) {
            throw new IllegalArgumentException("Pattern syntax error: " + regex + ". " + e);
        }
        return getElementsMatchingOwnTextPattern(pattern);
    }
    
    /**
     * Find all elements under this element (including self, and children of children).
     * 
     * @return all elements
     */
    public function getAllElements():Elements {
        return Collector.collect(new EvaluatorAllElements(), this);
    }

    /**
     * Gets the combined text of this element and all its children. Whitespace is normalized and trimmed.
     * <p>
     * For example, given HTML {@code <p>Hello  <b>there</b> now! </p>}, {@code p.text()} returns {@code "Hello there now!"}
     *
     * @return unencoded text, or empty string if none.
     * @see #ownText()
     * @see #textNodes()
     */
	//NOTE(az): renamed to getText
    public function getText():String {
        var accum = new StringBuf();
        
		var nodeVisitor:NodeVisitor = {
            
			head: function (node:Node, depth:Int) {
                if (Std.is(node, TextNode)) {
                    var textNode:TextNode = cast node;
                    appendNormalisedText(accum, textNode);
                } else if (Std.is(node, Element)) {
                    var element:Element = cast node;
                    if (accum.length > 0 &&
                        (element.isBlock() || element.tag.getName() == "br") &&
                        !TextNode.lastCharIsWhitespace(accum))
                        accum.add(" ");
                }
            },

            tail: function (node:Node, depth:Int) {
            }
        }
		
		new NodeTraversor(nodeVisitor).traverse(this);
        return accum.toString().trim();
    }

    /**
     * Gets the text owned by this element only; does not get the combined text of all children.
     * <p>
     * For example, given HTML {@code <p>Hello <b>there</b> now!</p>}, {@code p.ownText()} returns {@code "Hello now!"},
     * whereas {@code p.text()} returns {@code "Hello there now!"}.
     * Note that the text within the {@code b} element is not returned, as it is not a direct child of the {@code p} element.
     *
     * @return unencoded text, or empty string if none.
     * @see #text()
     * @see #textNodes()
     */
    public function ownText():String {
        var sb = new StringBuf();
        _ownText(sb);
        return sb.toString().trim();
    }

    private function _ownText(accum:StringBuf):Void {
        for (child in childNodes) {
            if (Std.is(child, TextNode)) {
                var textNode:TextNode = cast child;
                appendNormalisedText(accum, textNode);
            } else if (Std.is(child, Element)) {
				var element:Element = cast child;
                appendWhitespaceIfBr(element, accum);
            }
        }
    }

    private static function appendNormalisedText(accum:StringBuf, textNode:TextNode):Void {
        var text = textNode.getWholeText();

        if (preserveWhitespace(textNode.parentNode))
            accum.add(text);
        else
            StringUtil.appendNormalisedWhitespace(accum, text, TextNode.lastCharIsWhitespace(accum));
    }

    private static function appendWhitespaceIfBr(element:Element, accum:StringBuf):Void {
        if (element.getTag().getName() == "br" && !TextNode.lastCharIsWhitespace(accum))
            accum.add(" ");
    }

    public static function preserveWhitespace(node:Node):Bool {
        // looks only at this element and one level up, to prevent recursion & needless stack searches
        if (node != null && Std.is(node, Element)) {
            var element:Element = cast node;
            return element.tag.preserveWhitespace() ||
                element.parent() != null && element.parent().tag.preserveWhitespace();
        }
        return false;
    }

    /**
     * Set the text of this element. Any existing contents (text or elements) will be cleared
     * @param text unencoded text
     * @return this element
     */
	//NOTE(az): setText
    public function setText(text:String):Element {
        Validate.notNull(text);

        empty();
        var textNode = new TextNode(text, baseUri);
        appendChild(textNode);

        return this;
    }

    /**
     Test if this element has any text content (that is not just whitespace).
     @return true if element has non-blank text content.
     */
    public function hasText():Bool {
        for (child in childNodes) {
            if (Std.is(child, TextNode)) {
                var textNode:TextNode = cast child;
                if (!textNode.isBlank())
                    return true;
            } else if (Std.is(child, Element)) {
                var element:Element = cast child;
                if (element.hasText())
                    return true;
            }
        }
        return false;
    }

    /**
     * Get the combined data of this element. Data is e.g. the inside of a {@code script} tag.
     * @return the data, or empty string if none
     *
     * @see #dataNodes()
     */
    public function data():String {
        var sb = new StringBuf();

        for (childNode in childNodes) {
            if (Std.is(childNode, DataNode)) {
                var data:DataNode = cast childNode;
                sb.add(data.getWholeData());
            } else if (Std.is(childNode, Element)) {
                var element:Element = cast childNode;
                var elementData:String = element.data();
                sb.add(elementData);
            }
        }
        return sb.toString();
    }   

    /**
     * Gets the literal value of this element's "class" attribute, which may include multiple class names, space
     * separated. (E.g. on <code>&lt;div class="header gray"&gt;</code> returns, "<code>header gray</code>")
     * @return The literal class attribute, or <b>empty string</b> if no class attribute set.
     */
    public function className():String {
        return getAttr("class").trim();
    }

    /**
     * Get all of the element's class names. E.g. on element {@code <div class="header gray">},
     * returns a set of two elements {@code "header", "gray"}. Note that modifications to this set are not pushed to
     * the backing {@code class} attribute; use the {@link #classNames(java.util.Set)} method to persist them.
     * @return set of classnames, empty if no class attribute
     */
	//NOTE(az): getter, using polygonal ListSet
    public function getClassNames():Set<String> {
    	var names = classSplit.split(className());
    	var classNames:Set<String> = new ListSet<String>(names.length, names);
    	classNames.remove(""); // if classNames() was empty, would include an empty class

        return classNames;
    }

    /**
     Set the element's {@code class} attribute to the supplied class names.
     @param classNames set of classes
     @return this element, for chaining
     */
	//NOTE(az): setter
    public function setClassNames(classNames:Set<String>):Element {
        Validate.notNull(classNames);
        attributes.put("class", StringUtil.join(classNames.iterator(), " "));
        return this;
    }

    /**
     * Tests if this element has a class. Case insensitive.
     * @param className name of class to check for
     * @return true if it does, false if not
     */
    /*
    Used by common .class selector, so perf tweaked to reduce object creation vs hitting classnames().

    Wiki: 71, 13 (5.4x)
    CNN: 227, 91 (2.5x)
    Alterslash: 59, 4 (14.8x)
    Jsoup: 14, 1 (14x)
    */
	//NOTE(az): toLowerCase (is className passed by value on all targets?)
    public function hasClass(className:String):Bool {
        var classAttr:String = attributes.get("class");
        if (classAttr == "" || classAttr.length < className.length)
            return false;

        var classes:Array<String> = classSplit.split(classAttr);
		className = className.toLowerCase();
        for (name in classes) {
            if (className == name.toLowerCase())
                return true;
        }

        return false;
    }

    /**
     Add a class name to this element's {@code class} attribute.
     @param className class name to add
     @return this element
     */
    public function addClass(className:String):Element {
        Validate.notNull(className);

        var classes:Set<String> = getClassNames();
        classes.set(className);
        setClassNames(classes);

        return this;
    }

    /**
     Remove a class name from this element's {@code class} attribute.
     @param className class name to remove
     @return this element
     */
    public function removeClass(className:String):Element {
        Validate.notNull(className);

        var classes:Set<String> = getClassNames();
        classes.remove(className);
        setClassNames(classes);

        return this;
    }

    /**
     Toggle a class name on this element's {@code class} attribute: if present, remove it; otherwise add it.
     @param className class name to toggle
     @return this element
     */
    public function toggleClass(className:String):Element {
        Validate.notNull(className);

        var classes:Set<String> = getClassNames();
        if (classes.contains(className))
            classes.remove(className);
        else
            classes.set(className);
        setClassNames(classes);

        return this;
    }
    
    /**
     * Get the value of a form element (input, textarea, etc).
     * @return the value of the form element, or empty string if not set.
     */
	//NOTE(az): renamed to getVal
    public function getVal():String {
        if (getTagName() == "textarea")
            return getText();
        else
            return getAttr("value");
    }
    
    /**
     * Set the value of a form element (input, textarea, etc).
     * @param value value to set
     * @return this element (for chaining)
     */
	//NOTE(az): renamed to setVal
    public function setVal(value:String):Element {
        if (getTagName() == "textarea")
            setText(value);
        else
            setAttr("value", value);
        return this;
    }

    override function outerHtmlHead(accum:StringBuf, depth:Int, out:Document.OutputSettings) {
        if (accum.length > 0 && out.getPrettyPrint() && (tag.formatAsBlock() || (parent() != null && parent().getTag().formatAsBlock()) || out.getOutline()) )
            indent(accum, depth, out);
        
		accum.add("<");
        accum.add(getTagName());
        attributes._html(accum, out);

        // selfclosing includes unknown tags, isEmpty defines tags that are always empty
        if (childNodes.isEmpty() && tag.isSelfClosing()) {
            if (out.getSyntax() == Document.Syntax.html && tag.isEmpty())
                accum.add('>');
            else
                accum.add(" />"); // <img> in html, <img /> in xml
        }
        else
            accum.add(">");
    }

    override function outerHtmlTail(accum:StringBuf, depth:Int, out:Document.OutputSettings) {
        if (!(childNodes.isEmpty() && tag.isSelfClosing())) {
            if (out.getPrettyPrint() && (!childNodes.isEmpty() && (
                    tag.formatAsBlock() || (out.getOutline() && (childNodes.size>1 || (childNodes.size==1 && !(Std.is(childNodes.get(0), TextNode)))))
            )))
                indent(accum, depth, out);
            
			accum.add("</");
			accum.add(getTagName());
			accum.add(">");
        }
    }

    /**
     * Retrieves the element's inner HTML. E.g. on a {@code <div>} with one empty {@code <p>}, would return
     * {@code <p></p>}. (Whereas {@link #outerHtml()} would return {@code <div><p></p></div>}.)
     * 
     * @return String of HTML.
     * @see #outerHtml()
     */
	//NOTE(az): ren getHtml
    public function getHtml():String {
        var accum = new StringBuf();
        _html(accum);
        return getOutputSettings().getPrettyPrint() ? accum.toString().trim() : accum.toString();
    }

    private function _html(accum:StringBuf):Void {
        for (node in childNodes)
            node.outerHtml(accum);
    }
    
    /**
     * Set this element's inner HTML. Clears the existing HTML first.
     * @param html HTML to parse and set into this element
     * @return this element
     * @see #append(String)
     */
    //NOTE(az): ren setHtml
	public function setHtml(html:String):Element {
        empty();
        append(html);
        return this;
    }

    override public function toString():String {
        return outerHtml();
    }

    //@Override
	//NOTE(az): equals
    override public function equals(o:Node):Bool {
        if (this == o) return true;
		return false;
        /*if (o == null || getClass() != o.getClass()) return false;
        if (!super.equals(o)) return false;

        Element element = (Element) o;

        return tag.equals(element.tag);*/
    }

    //@Override
	//NOTE(az): `hashCode` is `key` in polygonal
	override public function hashCode():Int {
        var result = super.hashCode();
        result = 31 * result + (tag != null ? tag.hashCode() : 0);
        return result;
    }

    //@Override
    override public function clone():Element {
        return copyTo(new Element(tag, baseUri, null), null);
    }
	
	override function copyTo(to:Node, parent:Node):Element {
		Validate.notNull(to);
		
		var out:Element = cast super.copyTo(to, parent);
		out.tag = tag;
		
		return out;
	}
}
