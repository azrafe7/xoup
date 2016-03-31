package org.jsoup.parser;

import org.jsoup.helper.Validate;

using StringTools;

//NOTE(az): refactor as props

/**
 * HTML Tag capabilities.
 *
 * @author Jonathan Hedley, jonathan@hedley.net
 */
@:allow(org.jsoup.parser.HtmlTreeBuilder)
@:allow(org.jsoup.parser.XmlTreeBuilder)
class Tag {
    private static var tags:Map<String, Tag>; // map of known tags

    private var tagName:String;
    private var _isBlock:Bool = true; // block or inline
    private var _formatAsBlock:Bool = true; // should be formatted as a block
    private var _canContainBlock:Bool = true; // Can this tag hold block level tags?
    private var _canContainInline:Bool = true; // only pcdata if not
    private var _empty:Bool = false; // can hold nothing; e.g. img
    private var _selfClosing:Bool = false; // can self close (<foo />). used for unknown tags that self close, without forcing them as empty.
    private var _preserveWhitespace:Bool = false; // for pre, textarea, script etc
    private var _formList:Bool = false; // a control that appears in forms: input, textarea, output etc
    private var _formSubmit:Bool = false; // a control that can be submitted in a form: input etc

    function new(tagName:String) {
        this.tagName = tagName.toLowerCase();
    }

    /**
     * Get this tag's name.
     *
     * @return the tag's name
     */
    public function getName():String {
        return tagName;
    }

    /**
     * Get a Tag by name. If not previously defined (unknown), returns a new generic tag, that can do anything.
     * <p>
     * Pre-defined tags (P, DIV etc) will be ==, but unknown tags are not registered and will only .equals().
     * </p>
     * 
     * @param tagName Name of tag, e.g. "p". Case insensitive.
     * @return The tag, either defined or new generic.
     */
    public static function valueOf(tagName:String):Tag {
        Validate.notNull(tagName);
        var tag:Tag = tags.get(tagName);

        if (tag == null) {
            tagName = tagName.trim().toLowerCase();
            Validate.notEmpty(tagName);
            tag = tags.get(tagName);

            if (tag == null) {
                // not defined: create default; go anywhere, do anything! (incl be inside a <p>)
                tag = new Tag(tagName);
                tag._isBlock = false;
                tag._canContainBlock = true;
            }
        }
        return tag;
    }

    /**
     * Gets if this is a block tag.
     *
     * @return if block tag
     */
    public function isBlock():Bool {
        return _isBlock;
    }

    /**
     * Gets if this tag should be formatted as a block (or as inline)
     *
     * @return if should be formatted as block or inline
     */
    public function formatAsBlock():Bool {
        return _formatAsBlock;
    }

    /**
     * Gets if this tag can contain block tags.
     *
     * @return if tag can contain block tags
     */
    public function canContainBlock():Bool {
        return _canContainBlock;
    }

    /**
     * Gets if this tag is an inline tag.
     *
     * @return if this tag is an inline tag.
     */
    public function isInline():Bool {
        return !_isBlock;
    }

    /**
     * Gets if this tag is a data only tag.
     *
     * @return if this tag is a data only tag
     */
    public function isData():Bool {
        return !_canContainInline && !isEmpty();
    }

    /**
     * Get if this is an empty tag
     *
     * @return if this is an empty tag
     */
    public function isEmpty():Bool {
        return _empty;
    }

    /**
     * Get if this tag is self closing.
     *
     * @return if this tag should be output as self closing.
     */
    public function isSelfClosing():Bool {
        return _empty || _selfClosing;
    }

    /**
     * Get if this is a pre-defined tag, or was auto created on parsing.
     *
     * @return if a known tag
     */
    public function isKnown():Bool {
        return tags.exists(tagName);
    }

    /**
     * Check if this tagname is a known tag.
     *
     * @param tagName name of tag
     * @return if known HTML tag
     */
	//NOTE(az): renamed
    public static function isKnownTag(tagName:String):Bool {
        return tags.exists(tagName);
    }

    /**
     * Get if this tag should preserve whitespace within child text nodes.
     *
     * @return if preserve whitepace
     */
    public function preserveWhitespace():Bool {
        return _preserveWhitespace;
    }

    /**
     * Get if this tag represents a control associated with a form. E.g. input, textarea, output
     * @return if associated with a form
     */
    public function isFormListed():Bool {
        return _formList;
    }

    /**
     * Get if this tag represents an element that should be submitted with a form. E.g. input, option
     * @return if submittable with a form
     */
    public function isFormSubmittable():Bool {
        return _formSubmit;
    }

    function setSelfClosing():Tag {
        _selfClosing = true;
        return this;
    }

    //@Override
	//NOTE(az): equals
    public function equals(o):Bool {
        if (this == o) return true;
        if (!(Std.is(o, Tag))) return false;

        var tag:Tag = cast o;

        if (!(tagName == tag.tagName)) return false;
        if (_canContainBlock != tag._canContainBlock) return false;
        if (_canContainInline != tag._canContainInline) return false;
        if (_empty != tag._empty) return false;
        if (_formatAsBlock != tag._formatAsBlock) return false;
        if (_isBlock != tag._isBlock) return false;
        if (_preserveWhitespace != tag._preserveWhitespace) return false;
        if (_selfClosing != tag._selfClosing) return false;
        if (_formList != tag._formList) return false;
        return _formSubmit == tag._formSubmit;
    }

    //@Override
	//NOTE(az): `hashCode` is `key` in polygonal, check how to hash string
    /*var key:Int;
	
	public function hashCode():Int {
        //var result = tagName.hashCode();
        var result = 1;
        result = 31 * result + (_isBlock ? 1 : 0);
        result = 31 * result + (_formatAsBlock ? 1 : 0);
        result = 31 * result + (_canContainBlock ? 1 : 0);
        result = 31 * result + (_canContainInline ? 1 : 0);
        result = 31 * result + (_empty ? 1 : 0);
        result = 31 * result + (_selfClosing ? 1 : 0);
        result = 31 * result + (_preserveWhitespace ? 1 : 0);
        result = 31 * result + (_formList ? 1 : 0);
        result = 31 * result + (_formSubmit ? 1 : 0);
        return key = result;
    }*/

    //@Override
    public function toString():String {
        return tagName;
    }

    // internal static initialisers:
    // prepped from http://www.w3.org/TR/REC-html40/sgml/dtd.html and other sources
    private static var blockTags:Array<String>;
	
	private static var inlineTags:Array<String>;
	
	private static var emptyTags:Array<String>;
	
    private static var formatAsInlineTags:Array<String>;
	
    private static var preserveWhitespaceTags:Array<String>;
	
    // todo: I think we just need submit tags, and can scrub listed
    private static var formListedTags:Array<String>;
	
    private static var formSubmitTags:Array<String>;
	

    static function __init__() {
		//NOTE(az): init vars used in here
		
		tags = new Map<String, Tag>();
		
		blockTags = [
            "html", "head", "body", "frameset", "script", "noscript", "style", "meta", "link", "title", "frame",
            "noframes", "section", "nav", "aside", "hgroup", "header", "footer", "p", "h1", "h2", "h3", "h4", "h5", "h6",
            "ul", "ol", "pre", "div", "blockquote", "hr", "address", "figure", "figcaption", "form", "fieldset", "ins",
            "del", "s", "dl", "dt", "dd", "li", "table", "caption", "thead", "tfoot", "tbody", "colgroup", "col", "tr", "th",
            "td", "video", "audio", "canvas", "details", "menu", "plaintext", "template", "article", "main",
            "svg", "math"
		];
		
		inlineTags = [
            "object", "base", "font", "tt", "i", "b", "u", "big", "small", "em", "strong", "dfn", "code", "samp", "kbd",
            "var", "cite", "abbr", "time", "acronym", "mark", "ruby", "rt", "rp", "a", "img", "br", "wbr", "map", "q",
            "sub", "sup", "bdo", "iframe", "embed", "span", "input", "select", "textarea", "label", "button", "optgroup",
            "option", "legend", "datalist", "keygen", "output", "progress", "meter", "area", "param", "source", "track",
            "summary", "command", "device", "area", "basefont", "bgsound", "menuitem", "param", "source", "track",
            "data", "bdi"
		];
		
		emptyTags = [
            "meta", "link", "base", "frame", "img", "br", "wbr", "embed", "hr", "input", "keygen", "col", "command",
            "device", "area", "basefont", "bgsound", "menuitem", "param", "source", "track"
		];
		
		formatAsInlineTags = [
            "title", "a", "p", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "address", "li", "th", "td", "script", "style",
            "ins", "del", "s"
		];
		
		preserveWhitespaceTags = [
            "pre", "plaintext", "title", "textarea"
            // script is not here as it is a data node, which always preserve whitespace
		];
		
		formListedTags = [
            "button", "fieldset", "input", "keygen", "object", "output", "select", "textarea"
		];
		
		formSubmitTags = [
            "input", "keygen", "object", "select", "textarea"
		];
		
		
        // creates
        for (tagName in blockTags) {
            var tag = new Tag(tagName);
            register(tag);
        }
        for (tagName in inlineTags) {
            var tag = new Tag(tagName);
            tag._isBlock = false;
            tag._canContainBlock = false;
            tag._formatAsBlock = false;
            register(tag);
        }

        // mods:
        for (tagName in emptyTags) {
            var tag = tags.get(tagName);
            Validate.notNull(tag);
            tag._canContainBlock = false;
            tag._canContainInline = false;
            tag._empty = true;
        }

        for (tagName in formatAsInlineTags) {
            var tag = tags.get(tagName);
            Validate.notNull(tag);
            tag._formatAsBlock = false;
        }

        for (tagName in preserveWhitespaceTags) {
            var tag = tags.get(tagName);
            Validate.notNull(tag);
            tag._preserveWhitespace = true;
        }

        for (tagName in formListedTags) {
            var tag = tags.get(tagName);
            Validate.notNull(tag);
            tag._formList = true;
        }

        for (tagName in formSubmitTags) {
            var tag = tags.get(tagName);
            Validate.notNull(tag);
            tag._formSubmit = true;
        }
    }

    private static function register(tag:Tag):Void {
        tags.set(tag.tagName, tag);
    }
}
