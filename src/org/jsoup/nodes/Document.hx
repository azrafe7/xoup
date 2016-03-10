package org.jsoup.nodes;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.Cloneable;
import org.jsoup.Exceptions.IllegalArgumentException;
import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Document.OutputSettings;
import org.jsoup.parser.Tag;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import unifill.CodePoint;

using StringTools;

/*import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;
import java.util.ArrayList;
import java.util.List;
*/

/**
 A HTML Document.

 @author Jonathan Hedley, jonathan@hedley.net */
class Document extends Element {
    private var outputSettings:OutputSettings = new OutputSettings();
    private var quirksMode:QuirksMode = QuirksMode.noQuirks;
    private var location:String;
    private var updateMetaCharset:Bool = false;

    /**
     Create a new, empty Document.
     @param baseUri base URI of document
     @see org.jsoup.Jsoup#parse
     @see #createShell
     */
    public function new(baseUri:String) {
        super(Tag.valueOf("#root"), baseUri);
        this.location = baseUri;
    }

    /**
     Create a valid, empty shell of a document, suitable for adding more elements to.
     @param baseUri baseUri of document
     @return document with html, head, and body elements.
     */
    static public function createShell(baseUri:String):Document {
        Validate.notNull(baseUri);

        var doc = new Document(baseUri);
        var html:Element = doc.appendElement("html");
        html.appendElement("head");
        html.appendElement("body");

        return doc;
    }

    /**
     * Get the URL this Document was parsed from. If the starting URL is a redirect,
     * this will return the final URL from which the document was served from.
     * @return location
     */
	//NOTE(az): getter
    public function getLocation():String {
		return location;
    }
    
    /**
     Accessor to the document's {@code head} element.
     @return {@code head}
     */
    public function head():Element {
        return findFirstElementByTagName("head", this);
    }

    /**
     Accessor to the document's {@code body} element.
     @return {@code body}
     */
	public function body():Element {
        return findFirstElementByTagName("body", this);
    }

    /**
     Get the string contents of the document's {@code title} element.
     @return Trimmed title, or empty string if none set.
     */
	//NOTE(az): getTitle
    public function getTitle():String {
        // title is a preserve whitespace tag (for document output), but normalised here
        var titleEl:Element = getElementsByTag("title").first();
        return titleEl != null ? StringUtil.normaliseWhitespace(titleEl.getText()).trim() : "";
    }

    /**
     Set the document's {@code title} element. Updates the existing element, or adds {@code title} to {@code head} if
     not present
     @param title string to set as title
     */
	//NOTE(az): setTitle
    public function setTitle(title:String) {
        Validate.notNull(title);
        var titleEl:Element = getElementsByTag("title").first();
        if (titleEl == null) { // add to head
            head().appendElement("title").setText(title);
        } else {
            titleEl.setText(title);
        }
    }

    /**
     Create a new Element, with this document's base uri. Does not make the new element a child of this document.
     @param tagName element tag name (e.g. {@code a})
     @return new element
     */
    public function createElement(tagName:String):Element {
        return new Element(Tag.valueOf(tagName), this.getBaseUri());
    }

    /**
     Normalise the document. This happens after the parse phase so generally does not need to be called.
     Moves any text content that is not in the body element into the body.
     @return this document after normalisation
     */
    public function normalise():Document {
        var htmlEl:Element = findFirstElementByTagName("html", this);
        if (htmlEl == null)
            htmlEl = appendElement("html");
        if (head() == null)
            htmlEl.prependElement("head");
        if (body() == null)
            htmlEl.appendElement("body");

        // pull text nodes out of root, html, and head els, and push into body. non-text nodes are already taken care
        // of. do in inverse order to maintain text order.
        normaliseTextNodes(head());
        normaliseTextNodes(htmlEl);
        normaliseTextNodes(this);

        normaliseStructure("head", htmlEl);
        normaliseStructure("body", htmlEl);
        
        ensureMetaCharsetElement();
        
        return this;
    }

    // does not recurse.
	//NOTE(az): while
    private function normaliseTextNodes(element:Element):Void {
        var toMove:List<Node> = new ArrayList<Node>();
        for (node in element.childNodes) {
            if (Std.is(node, TextNode)) {
                var tn:TextNode = cast node;
                if (!tn.isBlank())
                    toMove.add(tn);
            }
        }

        //for (int i = toMove.size()-1; i >= 0; i--) {
        var i = toMove.size-1;
		while (i >= 0) {
            var node:Node = toMove.get(i);
            element.removeChild(node);
            body().prependChild(new TextNode(" ", ""));
            body().prependChild(node);
			i--;
        }
    }

    // merge multiple <head> or <body> contents into one, delete the remainder, and ensure they are owned by <html>
    private function normaliseStructure(tag:String, htmlEl:Element):Void {
        var elements:Elements = this.getElementsByTag(tag);
        var master:Element = elements.first(); // will always be available as created above if not existent
        if (elements.size > 1) { // dupes, move contents to master
            var toMove:List<Node> = new ArrayList<Node>();
            for (i in 1...elements.size) {
                var dupe:Node = elements.get(i);
                for (node in dupe.childNodes)
                    toMove.add(node);
                dupe.remove();
            }

            for (dupe in toMove)
                master.appendChild(dupe);
        }
        // ensure parented by <html>
        if (!master.parent().equals(htmlEl)) {
            htmlEl.appendChild(master); // includes remove()            
        }
    }

    // fast method to get first by tag name, used for html, head, body finders
    private function findFirstElementByTagName(tag:String, node:Node):Element {
        if (node.nodeName() == tag)
            return cast node;
        else {
            for (child in node.childNodes) {
                var found:Element = findFirstElementByTagName(tag, child);
                if (found != null)
                    return found;
            }
        }
        return null;
    }

    //@Override
    override public function outerHtml():String {
        return super.getHtml(); // no outer wrapper tag
    }

    /**
     Set the text of the {@code body} of this document. Any existing nodes within the body will be cleared.
     @param text unencoded text
     @return this document
     */
    //@Override
    override public function setText(text:String):Element {
        body().setText(text); // overridden to not nuke doc structure
        return this;
    }

    //@Override
    override public function nodeName():String {
        return "#document";
    }
    
    /**
     * Sets the charset used in this document. This method is equivalent
     * to {@link OutputSettings#charset(java.nio.charset.Charset)
     * OutputSettings.charset(Charset)} but in addition it updates the
     * charset / encoding element within the document.
     * 
     * <p>This enables
     * {@link #updateMetaCharsetElement(boolean) meta charset update}.</p>
     * 
     * <p>If there's no element with charset / encoding information yet it will
     * be created. Obsolete charset / encoding definitions are removed!</p>
     * 
     * <p><b>Elements used:</b></p>
     * 
     * <ul>
     * <li><b>Html:</b> <i>&lt;meta charset="CHARSET"&gt;</i></li>
     * <li><b>Xml:</b> <i>&lt;?xml version="1.0" encoding="CHARSET"&gt;</i></li>
     * </ul>
     * 
     * @param charset Charset
     * 
     * @see #updateMetaCharsetElement(boolean) 
     * @see OutputSettings#charset(java.nio.charset.Charset) 
     */
	//NOTE(az): setter
    public function setCharset(charset:Charset):Void {
        setUpdateMetaCharsetElement(true);
        outputSettings.setCharset(charset);
        ensureMetaCharsetElement();
    }
    
    /**
     * Returns the charset used in this document. This method is equivalent
     * to {@link OutputSettings#charset()}.
     * 
     * @return Current Charset
     * 
     * @see OutputSettings#charset() 
     */
	//NOTE(az): getter
    public function charset():Charset {
        return outputSettings.getCharset();
    }
    
    /**
     * Sets whether the element with charset information in this document is
     * updated on changes through {@link #charset(java.nio.charset.Charset)
     * Document.charset(Charset)} or not.
     * 
     * <p>If set to <tt>false</tt> <i>(default)</i> there are no elements
     * modified.</p>
     * 
     * @param update If <tt>true</tt> the element updated on charset
     * changes, <tt>false</tt> if not
     * 
     * @see #charset(java.nio.charset.Charset) 
     */
	//NOTE(az): setter
    public function setUpdateMetaCharsetElement(update:Bool):Void {
        this.updateMetaCharset = update;
    }
    
    /**
     * Returns whether the element with charset information in this document is
     * updated on changes through {@link #charset(java.nio.charset.Charset)
     * Document.charset(Charset)} or not.
     * 
     * @return Returns <tt>true</tt> if the element is updated on charset
     * changes, <tt>false</tt> if not
     */
	//NOTE(az): getter
    public function getUpdateMetaCharsetElement():Bool {
        return updateMetaCharset;
    }

    //@Override
    override public function clone():Document {
        var clone:Document = cast super.clone();
        clone.outputSettings = this.outputSettings.clone();
        return clone;
    }
    
    /**
     * Ensures a meta charset (html) or xml declaration (xml) with the current
     * encoding used. This only applies with
     * {@link #updateMetaCharsetElement(boolean) updateMetaCharset} set to
     * <tt>true</tt>, otherwise this method does nothing.
     * 
     * <ul>
     * <li>An exsiting element gets updated with the current charset</li>
     * <li>If there's no element yet it will be inserted</li>
     * <li>Obsolete elements are removed</li>
     * </ul>
     * 
     * <p><b>Elements used:</b></p>
     * 
     * <ul>
     * <li><b>Html:</b> <i>&lt;meta charset="CHARSET"&gt;</i></li>
     * <li><b>Xml:</b> <i>&lt;?xml version="1.0" encoding="CHARSET"&gt;</i></li>
     * </ul>
     */
    private function ensureMetaCharsetElement():Void {
        if (updateMetaCharset) {
            var syntax:Syntax = getOutputSettings().getSyntax();

            if (syntax == Syntax.html) {
                var metaCharset:Element = select("meta[charset]").first();

                if (metaCharset != null) {
                    metaCharset.setAttr("charset", charset().displayName());
                } else {
                    var head:Element = head();

                    if (head != null) {
                        head.appendElement("meta").setAttr("charset", charset().displayName());
                    }
                }

                // Remove obsolete elements
                select("meta[name=charset]").remove();
            } else if (syntax == Syntax.xml) {
                var node:Node = getChildNodes().get(0);

                if (Std.is(node, XmlDeclaration)) {
                    var decl:XmlDeclaration = cast node;

                    if (decl.getAttr(XmlDeclaration.DECL_KEY) == "xml") {
                        decl.setAttr("encoding", charset().displayName());

                        var version:String = decl.getAttr("version");

                        if (version != null) {
                            decl.setAttr("version", "1.0");
                        }
                    } else {
                        decl = new XmlDeclaration("xml", baseUri, false);
                        decl.setAttr("version", "1.0");
                        decl.setAttr("encoding", charset().displayName());

                        prependChild(decl);
                    }
                } else {
                    var decl = new XmlDeclaration("xml", baseUri, false);
                    decl.setAttr("version", "1.0");
                    decl.setAttr("encoding", charset().displayName());

                    prependChild(decl);
                }
            } else {
                // Unsupported syntax - nothing to do yet
            }
        }
    }
    


    /**
     * Get the document's current output settings.
     * @return the document's current output settings.
     */
	//NOTE(az): getter
    public function getOutputSettings():OutputSettings {
        return outputSettings;
    }

    /**
     * Set the document's output settings.
     * @param outputSettings new output settings.
     * @return this document, for chaining.
     */
	//NOTE(az): setter
    public function setOutputSettings(outputSettings:OutputSettings):Document {
        Validate.notNull(outputSettings);
        this.outputSettings = outputSettings;
        return this;
    }

	//NOTE(az): getter
    public function getQuirksMode():QuirksMode {
        return quirksMode;
    }

	//NOTE(az): setter
    public function setQuirksMode(quirksMode:QuirksMode):Document {
        this.quirksMode = quirksMode;
        return this;
    }
}


enum QuirksMode {
	noQuirks;
	quirks;
	limitedQuirks;
}

	
/**
 * The output serialization syntax.
 */
enum Syntax {
	html;
	xml;
}


/**
 * A Document's output settings control the form of the text() and html() methods.
 */
//NOTE(az): moved out, refactor as props, dummy Charset and CharsetEncoder
class OutputSettings implements Cloneable<OutputSettings> {

	private var _escapeMode:Entities.EscapeMode = Entities.EscapeMode.base;
	private var _charset:Charset = Charset.forName("UTF-8");
	private var _charsetEncoder:CharsetEncoder = Charset.forName("UTF-8").newEncoder();
	private var _prettyPrint:Bool = true;
	private var _outline:Bool = false;
	private var _indentAmount:Int = 1;
	private var _syntax:Syntax = Syntax.html;

	public function new() {}
	
	/**
	 * Get the document's current HTML escape mode: <code>base</code>, which provides a limited set of named HTML
	 * entities and escapes other characters as numbered entities for maximum compatibility; or <code>extended</code>,
	 * which uses the complete set of HTML named entities.
	 * <p>
	 * The default escape mode is <code>base</code>.
	 * @return the document's current escape mode
	 */
	//NOTE(az): getter
	public function getEscapeMode():Entities.EscapeMode {
		return _escapeMode;
	}

	/**
	 * Set the document's escape mode, which determines how characters are escaped when the output character set
	 * does not support a given character:- using either a named or a numbered escape.
	 * @param escapeMode the new escape mode to use
	 * @return the document's output settings, for chaining
	 */
	//NOTE(az): setter
	public function setEscapeMode(escapeMode:Entities.EscapeMode):OutputSettings {
		this._escapeMode = escapeMode;
		return this;
	}

	/**
	 * Get the document's current output charset, which is used to control which characters are escaped when
	 * generating HTML (via the <code>html()</code> methods), and which are kept intact.
	 * <p>
	 * Where possible (when parsing from a URL or File), the document's output charset is automatically set to the
	 * input charset. Otherwise, it defaults to UTF-8.
	 * @return the document's current charset.
	 */
	//NOTE(az): getter
	public function getCharset():Charset {
		return _charset;
	}

	/**
	 * Update the document's output charset.
	 * @param charset the new charset to use.
	 * @return the document's output settings, for chaining
	 */
	//NOTE(az): setter, see method below
	public function setCharset(charset:Dynamic):OutputSettings {
		if (Std.is(charset, String)) charset = Charset.forName(charset);
		else if (Std.is(charset, Charset)) { }
		else throw "Invalid charset";

		this._charset = charset;
		_charsetEncoder = charset.newEncoder();
		return this;
	}

	/**
	 * Update the document's output charset.
	 * @param charset the new charset (by name) to use.
	 * @return the document's output settings, for chaining
	 */
	/*public OutputSettings charset(String charset) {
		charset(Charset.forName(charset));
		return this;
	}*/

	public function encoder():CharsetEncoder {
		return _charsetEncoder;
	}

	/**
	 * Get the document's current output syntax.
	 * @return current syntax
	 */
	//NOTE(az): getter
	public function getSyntax():Syntax {
		return _syntax;
	}

	/**
	 * Set the document's output syntax. Either {@code html}, with empty tags and boolean attributes (etc), or
	 * {@code xml}, with self-closing tags.
	 * @param syntax serialization syntax
	 * @return the document's output settings, for chaining
	 */
	//NOTE(az): setter
	public function setSyntax(syntax:Syntax):OutputSettings {
		this._syntax = syntax;
		return this;
	}

	/**
	 * Get if pretty printing is enabled. Default is true. If disabled, the HTML output methods will not re-format
	 * the output, and the output will generally look like the input.
	 * @return if pretty printing is enabled.
	 */
	//NOTE(az): getter
	public function getPrettyPrint():Bool {
		return _prettyPrint;
	}

	/**
	 * Enable or disable pretty printing.
	 * @param pretty new pretty print setting
	 * @return this, for chaining
	 */
	//NOTE(az): setter
	public function setPrettyPrint(pretty:Bool):OutputSettings {
		_prettyPrint = pretty;
		return this;
	}
	
	/**
	 * Get if outline mode is enabled. Default is false. If enabled, the HTML output methods will consider
	 * all tags as block.
	 * @return if outline mode is enabled.
	 */
	//NOTE(az): getter
	public function getOutline():Bool {
		return _outline;
	}
	
	/**
	 * Enable or disable HTML outline mode.
	 * @param outlineMode new outline setting
	 * @return this, for chaining
	 */
	//NOTE(az): setter
	public function setOutline(outlineMode:Bool):OutputSettings {
		_outline = outlineMode;
		return this;
	}

	/**
	 * Get the current tag indent amount, used when pretty printing.
	 * @return the current indent amount
	 */
	//NOTE(az): getter
	public function indentAmount():Int {
		return _indentAmount;
	}

	/**
	 * Set the indent amount for pretty printing
	 * @param indentAmount number of spaces to use for indenting each level. Must be {@literal >=} 0.
	 * @return this, for chaining
	 */
	//NOTE(az): setter
	public function setIndentAmount(indentAmount:Int):OutputSettings {
		Validate.isTrue(indentAmount >= 0);
		this._indentAmount = indentAmount;
		return this;
	}

	//@Override
	//NOTE(az): add missing props
	public function clone():OutputSettings {
		var clone:OutputSettings = new OutputSettings();
		
		clone.setCharset(getCharset().name()); // new charset and charset encoder
		clone.setEscapeMode(getEscapeMode());
		// indentAmount, prettyPrint are primitives so object.clone() will handle
		return clone;
	}
}

//NOTE(az): dummy
@:enum abstract Charset(String) from String to String {
	var ascii = "ASCII";
	var utf8 = "UTF-8";
	
	static public function forName(name:String) {
		name = name.toUpperCase();
		if (name == ascii) return Charset.ascii;
		else if (name == utf8) return Charset.utf8;
		else throw new IllegalArgumentException("Invalid charset name");
	}

	public function displayName():String {
		return this;
	}
	
	public function name():String {
		return this;
	}
	
	public function newEncoder():CharsetEncoder {
		return new CharsetEncoder(this);
	}
}

//NOTE(az): dummy
@:allow(org.jsoup.nodes.Charset)
class CharsetEncoder {
	
	public var charset:Charset;
	
	function new(charset:Charset) { 
		this.charset = charset;
	}
	
	public function canEncode(c:CodePoint):Bool {
		trace('$charset + canEncode + $c');
		return true;
	}
}