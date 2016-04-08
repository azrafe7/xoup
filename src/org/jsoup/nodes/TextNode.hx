package org.jsoup.nodes;

import org.jsoup.helper.StringBuilder;
import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;

/**
 A text node.

 @author Jonathan Hedley, jonathan@hedley.net */
class TextNode extends Node {
    /*
    TextNode is a node, and so by default comes with attributes and children. The attributes are seldom used, but use
    memory, and the child nodes are never used. So we don't have them, and override accessors to attributes to create
    them as needed on the fly.
     */
    private static inline var TEXT_KEY:String = "text";
    var text:String;

    /**
     Create a new TextNode representing the supplied (unencoded) text).

     @param text raw text
     @param baseUri base uri
     @see #createFromEncoded(String, String)
     */
    public function new(text:String, baseUri:String) {
		super(null, null);
		
        this.baseUri = baseUri;
        this.text = text;
    }

    override public function nodeName():String {
        return "#text";
    }
    
    /**
     * Get the text content of this text node.
     * @return Unencoded, normalised text.
     * @see TextNode#getWholeText()
     */
	//NOTE(az): getter
    public function getText():String {
        return normaliseWhitespace(getWholeText());
    }
    
    /**
     * Set the text content of this text node.
     * @param text unencoded text
     * @return this, for chaining
     */
	//NOTE(az): setter
    public function setText(text:String):TextNode {
        this.text = text;
        if (attributes != null)
            attributes.put(TEXT_KEY, text);
        return this;
    }

    /**
     Get the (unencoded) text of this text node, including any newlines and spaces present in the original.
     @return text
     */
    public function getWholeText():String {
		var res = attributes == null ? text : attributes.get(TEXT_KEY);
        return res;
    }

    /**
     Test if this text node is blank -- that is, empty or only whitespace (including newlines).
     @return true if this document is empty or only whitespace, false if it contains any text content.
     */
    public function isBlank():Bool {
        return StringUtil.isBlank(getWholeText());
    }

    /**
     * Split this text node into two nodes at the specified string offset. After splitting, this node will contain the
     * original text up to the offset, and will have a new text node sibling containing the text after the offset.
     * @param offset string offset point to split node at.
     * @return the newly created text node containing the text after the offset.
     */
    public function splitText(offset:Int):TextNode {
        Validate.isTrue(offset >= 0, "Split offset must be not be negative");
        Validate.isTrue(offset < text.length, "Split offset must not be greater than current text length");

        var head:String = getWholeText().substring(0, offset);
        var tail:String = getWholeText().substring(offset);
        setText(head);
        var tailNode = new TextNode(tail, this.getBaseUri());
        if (parent() != null)
            parent().addChildrenAt(getSiblingIndex()+1, [tailNode]);

        return tailNode;
    }

	//NOTE(az): check long bool expr and cast
    override function outerHtmlHead(accum:StringBuilder, depth:Int, out:Document.OutputSettings):Void {
		if (out.getPrettyPrint() && (
				(getSiblingIndex() == 0 && Std.is(parentNode, Element) && cast(parentNode, Element).getTag().formatAsBlock() && !isBlank()) 
				|| (out.getOutline() && siblingNodes().size > 0 && !isBlank()) ))
		{
			indent(accum, depth, out);
		}

        var normaliseWhite:Bool = out.getPrettyPrint() && (Std.is(parent(), Element))
                && !Element.preserveWhitespace(parent());
        Entities._escape(accum, getWholeText(), out, false, normaliseWhite, false);
    }

    override function outerHtmlTail(accum:StringBuilder, depth:Int, out:Document.OutputSettings):Void {}

    //@Override
    override public function toString():String {
        return outerHtml();
    }

    /**
     * Create a new TextNode from HTML encoded (aka escaped) data.
     * @param encodedText Text containing encoded HTML (e.g. &amp;lt;)
     * @param baseUri Base uri
     * @return TextNode containing unencoded data (e.g. &lt;)
     */
    public static function createFromEncoded(encodedText:String, baseUri:String):TextNode {
        var text:String = Entities.unescape(encodedText);
        return new TextNode(text, baseUri);
    }

    static function normaliseWhitespace(text:String):String {
        text = StringUtil.normaliseWhitespace(text);
        return text;
    }

	//NOTE(az): recheck
    static function stripLeadingWhitespace(text:String):String {
        return text = ~/^\s+/m.replace(text, "");
    }

    static public function lastCharIsWhitespace(sb:StringBuilder):Bool {
        return sb.length != 0 && sb.toString().charAt(sb.length - 1) == ' ';
    }

    // attribute fiddling. create on first access.
    private function ensureAttributes():Void {
        if (attributes == null) {
            attributes = new Attributes();
            attributes.put(TEXT_KEY, text);
        }
    }

    //@Override
	//NOTE(az): getter
    override public function getAttr(attributeKey:String):String {
        ensureAttributes();
        return super.getAttr(attributeKey);
    }

    //@Override
    //NOTE(az): getter
	override public function getAttributes():Attributes {
        ensureAttributes();
        return super.getAttributes();
    }

    //@Override
    //NOTE(az): setter
    override public function setAttr(attributeKey:String, attributeValue:Dynamic):Node {
        ensureAttributes();
        return super.setAttr(attributeKey, attributeValue);
    }

    //@Override
    override public function hasAttr(attributeKey:String):Bool {
        ensureAttributes();
        return super.hasAttr(attributeKey);
    }

    //@Override
    override public function removeAttr(attributeKey:String):Node {
        ensureAttributes();
        return super.removeAttr(attributeKey);
    }

    //@Override
    override public function absUrl(attributeKey:String):String {
        ensureAttributes();
        return super.absUrl(attributeKey);
    }

    //@Override
	//NOTE(az): equals
    override public function equals(o:Node):Bool {
        if (this == o) return true;
		if (Std.is(o, TextNode) && Std.string(this) == Std.string(o)) return true;
        return false;
		
		/*if (o == null || getClass() != o.getClass()) return false;
        if (!super.equals(o)) return false;

        TextNode textNode = (TextNode) o;

        return !(text != null ? !text.equals(textNode.text) : textNode.text != null);*/
    }

    //@Override
    //NOTE(az): needed?
	/*public int hashCode() {
        int result = super.hashCode();
        result = 31 * result + (text != null ? text.hashCode() : 0);
        return result;
    }*/
    
	//@Override
    override public function clone():TextNode {
        return copyTo(new TextNode(null, baseUri), null);
    }
	
	override function copyTo(to:Node, parent:Node):TextNode {
		var out:TextNode = cast super.copyTo(to, parent);
		out.text = text;
		
		return out;
	}
}
