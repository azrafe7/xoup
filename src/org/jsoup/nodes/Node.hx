package org.jsoup.nodes;

import de.polygonal.ds.Cloneable;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.Dll;
import de.polygonal.ds.Hashable;
import de.polygonal.ds.List;
import org.jsoup.helper.StringUtil;
import org.jsoup.Interfaces.IterableWithLength;
import org.jsoup.parser.Parser;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;

import org.jsoup.helper.Validate;


using StringTools;

/*import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.parser.Parser;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
*/

/**
 The base, abstract Node model. Elements, Documents, Comments etc are all Node instances.

 @author Jonathan Hedley, jonathan@hedley.net */
@:allow(org.jsoup.nodes.OuterHtmlVisitor)
class Node implements Cloneable<Node> implements Hashable {
    private static var EMPTY_NODES:List<Node> = new ArrayList<Node>();
    
	var parentNode:Node = null;
    var childNodes:List<Node> = null;
    var attributes:Attributes = null;
    var baseUri:String = null;
    var siblingIndex:Int = 0;

    /**
     Create a new Node.
     @param baseUri base URI
     @param attributes attributes (not null, but may be empty)
     */
	//NOTE(az): conflated (problem with assumption of null?) !!!this might be VERY important!
    function new(baseUri:String = null, attributes:Attributes = null) {
        //Validate.notNull(baseUri);
        //Validate.notNull(attributes);
        this.baseUri = baseUri != null ? baseUri.trim() : "";
        this.attributes = attributes != null ? attributes : new Attributes();
        
        childNodes = EMPTY_NODES;
    }

    /**
     Get the node name of this node. Use for debugging purposes and not logic switching (for that, use instanceof).
     @return node name
     */
    public function nodeName():String { throw "Not implemented"; };

    /**
     * Get an attribute's value by its key.
     * <p>
     * To get an absolute URL from an attribute that may be a relative URL, prefix the key with <code><b>abs</b></code>,
     * which is a shortcut to the {@link #absUrl} method.
     * </p>
     * E.g.:
     * <blockquote><code>String url = a.attr("abs:href");</code></blockquote>
     * 
     * @param attributeKey The attribute key.
     * @return The attribute, or empty string if not present (to avoid nulls).
     * @see #attributes()
     * @see #hasAttr(String)
     * @see #absUrl(String)
     */
    public function getAttr(attributeKey:String):String {
        Validate.notNull(attributeKey);

        if (attributes.hasKey(attributeKey))
            return attributes.get(attributeKey);
        else if (attributeKey.toLowerCase().startsWith("abs:"))
            return absUrl(attributeKey.substring("abs:".length));
        else return "";
    }

    /**
     * Get all of the element's attributes.
     * @return attributes (which implements iterable, in same order as presented in original HTML).
     */
    public function getAttributes():Attributes {
        return attributes;
    }

    /**
     * Set an attribute (key=value). If the attribute already exists, it is replaced.
     * @param attributeKey The attribute key.
     * @param attributeValue The attribute value.
     * @return this (for chaining)
     */
    public function setAttr(attributeKey:String, attributeValue:String):Node {
        attributes.put(attributeKey, attributeValue);
        return this;
    }

    /**
     * Test if this element has an attribute.
     * @param attributeKey The attribute key to check.
     * @return true if the attribute exists, false if not.
     */
    public function hasAttr(attributeKey:String):Bool {
        Validate.notNull(attributeKey);

        if (attributeKey.startsWith("abs:")) {
            var key = attributeKey.substring("abs:".length);
            if (attributes.hasKey(key) && absUrl(key) != "")
                return true;
        }
        return attributes.hasKey(attributeKey);
    }

    /**
     * Remove an attribute from this element.
     * @param attributeKey The attribute to remove.
     * @return this (for chaining)
     */
    public function removeAttr(attributeKey:String):Node {
        Validate.notNull(attributeKey);
        attributes.remove(attributeKey);
        return this;
    }

    /**
     Get the base URI of this node.
     @return base URI
     */
	//NOTE(az): getter
    public function getBaseUri():String {
        return baseUri;
    }

    /**
     Update the base URI of this node and all of its descendants.
     @param baseUri base URI to set
     */
    public function setBaseUri(baseUri:String):Void {
        Validate.notNull(baseUri);

		var nodeVisitor:NodeVisitor = 
		{
            head: function(node:Node, depth:Int) {
                node.baseUri = baseUri;
            },

            tail: function(node:Node, depth:Int) {
            }
		}
		
        traverse(nodeVisitor);
    }

    /**
     * Get an absolute URL from a URL attribute that may be relative (i.e. an <code>&lt;a href&gt;</code> or
     * <code>&lt;img src&gt;</code>).
     * <p>
     * E.g.: <code>String absUrl = linkEl.absUrl("href");</code>
     * </p>
     * <p>
     * If the attribute value is already absolute (i.e. it starts with a protocol, like
     * <code>http://</code> or <code>https://</code> etc), and it successfully parses as a URL, the attribute is
     * returned directly. Otherwise, it is treated as a URL relative to the element's {@link #baseUri}, and made
     * absolute using that.
     * </p>
     * <p>
     * As an alternate, you can use the {@link #attr} method with the <code>abs:</code> prefix, e.g.:
     * <code>String absUrl = linkEl.attr("abs:href");</code>
     * </p>
     * 
     * @param attributeKey The attribute key
     * @return An absolute URL if one could be made, or an empty string (not null) if the attribute was missing or
     * could not be made successfully into a URL.
     * @see #attr
     * @see java.net.URL#URL(java.net.URL, String)
     */
    public function absUrl(attributeKey:String):String {
        Validate.notEmpty(attributeKey);

        if (!hasAttr(attributeKey)) {
            return ""; // nothing to make absolute with
        } else {
            return StringUtil.resolve(baseUri, getAttr(attributeKey));
        }
    }

    /**
     Get a child node by its 0-based index.
     @param index index of child node
     @return the child node at this index. Throws a {@code IndexOutOfBoundsException} if the index is out of bounds.
     */
    public function childNode(index:Int):Node {
        return childNodes.get(index);
    }

    /**
     Get this node's children. Presented as an unmodifiable list: new children can not be added, but the child nodes
     themselves can be manipulated.
     @return list of children. If no children, returns an empty list.
     */
	//NOTE(az): getter, unmodifiable
    public function getChildNodes():List<Node> {
        //return Collections.unmodifiableList(childNodes);
        return cast childNodes.clone(false);
    }

    /**
     * Returns a deep copy of this node's children. Changes made to these nodes will not be reflected in the original
     * nodes
     * @return a deep copy of this node's children
     */
    public function childNodesCopy():List<Node> {
        //NOTE(az):size 
		var children = new ArrayList<Node>(childNodes.size);
        for (node in childNodes) {
            children.add(node.clone());
        }
        return children;
    }

    /**
     * Get the number of child nodes that this node holds.
     * @return the number of child nodes that this node holds.
     */
    public function childNodeSize():Int {
        return childNodes.size;
    }
    
    public function childNodesAsArray():Array<Node> {
        return childNodes.toArray(/*new Node[childNodeSize()]*/);
    }

    /**
     Gets this node's parent node.
     @return parent node; or null if no parent.
     */
    public function parent():Node {
        return parentNode;
    }

    /**
     Gets this node's parent node. Node overridable by extending classes, so useful if you really just need the Node type.
     @return parent node; or null if no parent.
     */
	//NOTE(az): getter
    public function getParentNode():Node {
        return parentNode;
    }
    
    /**
     * Gets the Document associated with this Node. 
     * @return the Document associated with this Node, or null if there is no such Document.
     */
    public function ownerDocument():Document {
        if (Std.is(this, Document))
            return cast this;
        else if (parentNode == null)
            return null;
        else
            return parentNode.ownerDocument();
    }
    
    /**
     * Remove (delete) this node from the DOM tree. If this node has children, they are also removed.
     */
    public function remove():Void {
        Validate.notNull(parentNode);
        parentNode.removeChild(this);
    }

    /**
     * Insert the specified HTML into the DOM before this node (i.e. as a preceding sibling).
     * @param html HTML to add before this node
     * @return this node, for chaining
     * @see #after(String)
     */
    public function before(html:String):Node {
        addSiblingHtml(siblingIndex, html);
        return this;
    }

    /**
     * Insert the specified node into the DOM before this node (i.e. as a preceding sibling).
     * @param node to add before this node
     * @return this node, for chaining
     * @see #after(Node)
     */
	//NOTE(az): renamed to beforeNode
    public function beforeNode(node:Node):Node {
        Validate.notNull(node);
        Validate.notNull(parentNode);

        parentNode.addChildrenAt(siblingIndex, [node]);
        return this;
    }

    /**
     * Insert the specified HTML into the DOM after this node (i.e. as a following sibling).
     * @param html HTML to add after this node
     * @return this node, for chaining
     * @see #before(String)
     */
    public function after(html:String):Node {
        addSiblingHtml(siblingIndex + 1, html);
        return this;
    }

    /**
     * Insert the specified node into the DOM after this node (i.e. as a following sibling).
     * @param node to add after this node
     * @return this node, for chaining
     * @see #before(Node)
     */
	//NOTE(az): renamed to afterNode
    public function afterNode(node:Node):Node {
        Validate.notNull(node);
        Validate.notNull(parentNode);

        parentNode.addChildrenAt(siblingIndex + 1, [node]);
        return this;
    }

	//NOTE(az): cast and size
    private function addSiblingHtml(index:Int, html:String):Void {
        Validate.notNull(html);
        Validate.notNull(parentNode);

        var context:Element = Std.is(parent(), Element) ? cast parent() : null;        
        var nodes:List<Node> = Parser.parseFragment(html, context, getBaseUri());
        parentNode.addChildrenAt(index, nodes.toArray(/*new Node[nodes.size()])*/));
    }

    /**
     Wrap the supplied HTML around this node.
     @param html HTML to wrap around this element, e.g. {@code <div class="head"></div>}. Can be arbitrarily deep.
     @return this node, for chaining.
     */
	//NOTE(az): cast and size
    public function wrap(html:String):Node {
        Validate.notEmpty(html);

        var context = Std.is(parent(), Element) ? cast parent() : null;
        var wrapChildren:List<Node> = Parser.parseFragment(html, context, getBaseUri());
        var wrapNode:Node = wrapChildren.get(0);
        if (wrapNode == null || !(Std.is(wrapNode, Element))) // nothing to wrap with; noop
            return null;

        var wrap:Element = cast wrapNode;
        var deepest:Element = getDeepChild(wrap);
        parentNode.replaceChild(this, wrap);
        deepest.addChildren([this]);

        // remainder (unbalanced wrap, like <div></div><p></p> -- The <p> is remainder
        if (wrapChildren.size > 0) {
            for (i in 0...wrapChildren.size) {
                var remainder:Node = wrapChildren.get(i);
                remainder.parentNode.removeChild(remainder);
                wrap.appendChild(remainder);
            }
        }
        return this;
    }

    /**
     * Removes this node from the DOM, and moves its children up into the node's parent. This has the effect of dropping
     * the node but keeping its children.
     * <p>
     * For example, with the input html:
     * </p>
     * <p>{@code <div>One <span>Two <b>Three</b></span></div>}</p>
     * Calling {@code element.unwrap()} on the {@code span} element will result in the html:
     * <p>{@code <div>One Two <b>Three</b></div>}</p>
     * and the {@code "Two "} {@link TextNode} being returned.
     * 
     * @return the first child of this node, after the node has been unwrapped. Null if the node had no children.
     * @see #remove()
     * @see #wrap(String)
     */
    public function unwrap():Node {
        Validate.notNull(parentNode);

        var firstChild:Node = childNodes.size > 0 ? childNodes.get(0) : null;
        parentNode.addChildrenAt(siblingIndex, this.childNodesAsArray());
        this.remove();

        return firstChild;
    }

    private function getDeepChild(el:Element):Element {
        var children:List<Element> = el.children();
        if (children.size > 0)
            return getDeepChild(children.get(0));
        else
            return el;
    }
    
    /**
     * Replace this node in the DOM with the supplied node.
     * @param in the node that will will replace the existing node.
     */
    public function replaceWith(inNode:Node):Void {
        Validate.notNull(inNode);
        Validate.notNull(parentNode);
        parentNode.replaceChild(this, inNode);
    }

    /*protected*/ function setParentNode(parentNode:Node):Void {
        if (this.parentNode != null)
            this.parentNode.removeChild(this);
        this.parentNode = parentNode;
    }

    /*protected*/ function replaceChild(out:Node, inNode:Node):Void {
        Validate.isTrue(out.parentNode == this);
        Validate.notNull(inNode);
        if (inNode.parentNode != null)
            inNode.parentNode.removeChild(inNode);
        
        var index:Int = out.siblingIndex;
        childNodes.set(index, inNode);
        inNode.parentNode = this;
        inNode.setSiblingIndex(index);
        out.parentNode = null;
    }

    /*protected*/ function removeChild(out:Node):Void {
        Validate.isTrue(out.parentNode == this);
        var index:Int = out.siblingIndex;
        childNodes.removeAt(index);
        reindexChildren(index);
        out.parentNode = null;
    }

	//NOTE(az): varargs with Iterable
    /*protected*/ function addChildren(children:Iterable<Node>):Void {
        //most used. short circuit addChildren(int), which hits reindex children and array copy
        for (child in children) {
            reparentChild(child);
            ensureChildNodes();
            childNodes.add(child);
            child.setSiblingIndex(childNodes.size-1);
        }
    }

	//NOTE(az): renamed addChildrenAt, watch loop, interface
    /*protected*/ function addChildrenAt(index:Int, children:Iterable<Node>):Void {
        Validate.noNullElements(children);
        var childrenArray = [for (n in children) n];
		//for (int i = children.length - 1; i >= 0; i--) {
        var i = childrenArray.length - 1;
		while (i >= 0) {
            var inNode:Node = childrenArray[i];
            reparentChild(inNode);
            ensureChildNodes();
            childNodes.insert(index, inNode);
			i--;
        }
        reindexChildren(index);
    }

	//NOTE(az):arraylist
    /*protected*/ function ensureChildNodes():Void {
        if (childNodes == EMPTY_NODES) {
            childNodes = new ArrayList<Node>(4);
        }
    }

    /*protected*/ function reparentChild(child:Node):Void {
        if (child.parentNode != null)
            child.parentNode.removeChild(child);
        child.setParentNode(this);
    }
    
    private function reindexChildren(start:Int):Void {
        for (i in start...childNodes.size) {
            childNodes.get(i).setSiblingIndex(i);
        }
    }
    
    /**
     Retrieves this node's sibling nodes. Similar to {@link #childNodes()  node.parent.childNodes()}, but does not
     include this node (a node is not a sibling of itself).
     @return node siblings. If the node has no parent, returns an empty list.
     */
    public function siblingNodes():List<Node> {
        if (parentNode == null)
            return EMPTY_NODES;

        var nodes:List<Node> = parentNode.childNodes;
        var siblings:List<Node> = new ArrayList<Node>(nodes.size - 1);
        for (node in nodes)
            if (node != this)
                siblings.add(node);
        return siblings;
    }

    /**
     Get this node's next sibling.
     @return next sibling, or null if this is the last sibling
     */
    public function nextSibling():Node {
        if (parentNode == null)
            return null; // root
        
        var siblings:List<Node> = parentNode.childNodes;
        var index:Int = siblingIndex + 1;
        if (siblings.size > index)
            return siblings.get(index);
        else
            return null;
    }

    /**
     Get this node's previous sibling.
     @return the previous sibling, or null if this is the first sibling
     */
    public function previousSibling():Node {
        if (parentNode == null)
            return null; // root

        if (siblingIndex > 0)
            return parentNode.childNodes.get(siblingIndex-1);
        else
            return null;
    }

    /**
     * Get the list index of this node in its node sibling list. I.e. if this is the first node
     * sibling, returns 0.
     * @return position in node sibling list
     * @see org.jsoup.nodes.Element#elementSiblingIndex()
     */
	//NOTE(az): getter
    public function getSiblingIndex():Int {
        return siblingIndex;
    }
    
    /*protected*/ function setSiblingIndex(siblingIndex:Int):Void {
        this.siblingIndex = siblingIndex;
    }

    /**
     * Perform a depth-first traversal through this node and its descendants.
     * @param nodeVisitor the visitor callbacks to perform on each node
     * @return this node, for chaining
     */
    public function traverse(nodeVisitor:NodeVisitor):Node {
        Validate.notNull(nodeVisitor);
        var traversor:NodeTraversor = new NodeTraversor(nodeVisitor);
        traversor.traverse(this);
        return this;
    }

    /**
     Get the outer HTML of this node.
     @return HTML
     */
    public function outerHtml(accum:StringBuf = null):String {
        if (accum == null) accum = new StringBuf(/*128*/);
        new NodeTraversor(new OuterHtmlVisitor(accum, getOutputSettings())).traverse(this);
        return accum.toString();
    }

	//NOTE(az): needed? ^^^
    /*protected void outerHtml(StringBuilder accum) {
        new NodeTraversor(new OuterHtmlVisitor(accum, getOutputSettings())).traverse(this);
    }*/

    // if this node has no document (or parent), retrieve the default output settings
    function getOutputSettings():Document.OutputSettings {
        return ownerDocument() != null ? ownerDocument().getOutputSettings() : (new Document("")).getOutputSettings();
    }

    /**
     Get the outer HTML of this node.
     @param accum accumulator to place HTML into
     */
    /*abstract*/ function outerHtmlHead(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void { throw "Not implemented"; }

	/*abstract*/ function outerHtmlTail(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void { throw "Not implemented"; }

    //@Override
    public function toString():String {
        return outerHtml();
    }

    /*protected*/ function indent(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void {
        accum.add("\n".rpad(" ", depth * out.indentAmount()));
    }

    /**
     * Check if this node is equal to another node. A node is considered equal if its attributes and content equal the
     * other node; particularly its position in the tree does not influence its equality.
     * @param o other object to compare to
     * @return true if the content of this node is the same as the other
     */
    //@Override
	//NOTE(az): this needs to be watched closely (there's an issue on github)
    public function equals(o):Bool {
        if (this == o) return true;
		return false;
        /*if (o == null || getClass() != o.getClass()) return false;

        Node node = (Node) o;

        if (childNodes != null ? !childNodes.equals(node.childNodes) : node.childNodes != null) return false;
        return !(attributes != null ? !attributes.equals(node.attributes) : node.attributes != null);*/
    }

    /**
     * Calculates a hash code for this node, which includes iterating all its attributes, and recursing into any child
     * nodes. This means that a node's hashcode is based on it and its child content, and not its parent or place in the
     * tree. So two nodes with the same content, regardless of their position in the tree, will have the same hashcode.
     * @return the calculated hashcode
     * @see Node#equals(Object)
     */
    //@Override
	//NOTE(az): `hashCode` is `key` in polygonal
    public var key:Int;
	
	public function hashCode():Int {
        var result = childNodes != null ? childNodes.key : 0;
        result = 31 * result + (attributes != null ? attributes.hashCode() : 0);
        return key = result;
    }

    /**
     * Create a stand-alone, deep copy of this node, and all of its children. The cloned node will have no siblings or
     * parent node. As a stand-alone object, any changes made to the clone or any of its children will not impact the
     * original node.
     * <p>
     * The cloned node may be adopted into another Document or node structure using {@link Element#appendChild(Node)}.
     * @return stand-alone cloned node
     */
    //@Override
	//NOTE(az): using DLL as LinkedList
    public function clone():Node {
        var thisClone:Node = doClone(null); // splits for orphan

        // Queue up nodes that need their children cloned (BFS).
        var nodesToProcess = new Dll<Node>();
        nodesToProcess.add(thisClone);

        while (!nodesToProcess.isEmpty()) {
            var currParent:Node = nodesToProcess.removeHead();

            for (i in 0...currParent.childNodes.size) {
                var childClone:Node = currParent.childNodes.get(i).doClone(currParent);
                currParent.childNodes.set(i, childClone);
                nodesToProcess.add(childClone);
            }
        }

        return thisClone;
    }

    /*
     * Return a clone of the node using the given parent (which can be null).
     * Not a deep copy of children.
     */
	 //NOTE(az): mmmhh try/catch
	 /*protected*/ function doClone(parent:Node):Node {
        var clone:Node = new Node();

        clone.parentNode = parent; // can be null, to create an orphan split
        clone.siblingIndex = parent == null ? 0 : siblingIndex;
        clone.attributes = attributes != null ? attributes.clone() : null;
        clone.baseUri = baseUri;
        clone.childNodes = new ArrayList<Node>(childNodes.size);

        for (child in childNodes)
            clone.childNodes.add(child);

        return clone;
    }

}

//NOTE(az): moved out, no implement (relying on structural subtyping)
/*private static*/ class OuterHtmlVisitor /*implements NodeVisitor*/ {
	var accum:StringBuf;
	var out:Document.OutputSettings;

	public function new(accum:StringBuf, out:Document.OutputSettings) {
		this.accum = accum;
		this.out = out;
	}

	public function head(node:Node, depth:Int):Void {
		node.outerHtmlHead(accum, depth, out);
	}

	public function tail(node:Node, depth:Int):Void {
		if (node.nodeName() != "#text") // saves a void hit.
			node.outerHtmlTail(accum, depth, out);
	}
}
