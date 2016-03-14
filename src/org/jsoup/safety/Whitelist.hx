package org.jsoup.safety;

/*
    Thank you to Ryan Grove (wonko.com) for the Ruby HTML cleaner http://github.com/rgrove/sanitize/, which inspired
    this whitelist configuration, and the initial defaults.
 */

import de.polygonal.ds.Set;
import de.polygonal.ds.ListSet;
import org.jsoup.safety.Whitelist.AttributeKey;
import org.jsoup.safety.Whitelist.AttributeValue;
import org.jsoup.safety.Whitelist.Protocol;
import org.jsoup.safety.Whitelist.TagName;
 
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Attribute;
import org.jsoup.nodes.Attributes;
import org.jsoup.nodes.Element;

using StringTools;

/*import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
*/


/**
 Whitelists define what HTML (elements and attributes) to allow through the cleaner. Everything else is removed.
 <p>
 Start with one of the defaults:
 </p>
 <ul>
 <li>{@link #none}
 <li>{@link #simpleText}
 <li>{@link #basic}
 <li>{@link #basicWithImages}
 <li>{@link #relaxed}
 </ul>
 <p>
 If you need to allow more through (please be careful!), tweak a base whitelist with:
 </p>
 <ul>
 <li>{@link #addTags}
 <li>{@link #addAttributes}
 <li>{@link #addEnforcedAttribute}
 <li>{@link #addProtocols}
 </ul>
 <p>
 You can remove any setting from an existing whitelist with:
 </p>
 <ul>
 <li>{@link #removeTags}
 <li>{@link #removeAttributes}
 <li>{@link #removeEnforcedAttribute}
 <li>{@link #removeProtocols}
 </ul>
 
 <p>
 The cleaner and these whitelists assume that you want to clean a <code>body</code> fragment of HTML (to add user
 supplied HTML into a templated page), and not to clean a full HTML document. If the latter is the case, either wrap the
 document HTML around the cleaned body HTML, or create a whitelist that allows <code>html</code> and <code>head</code>
 elements as appropriate.
 </p>
 <p>
 If you are going to extend a whitelist, please be very careful. Make sure you understand what attributes may lead to
 XSS attack vectors. URL attributes are particularly vulnerable and require careful validation. See 
 http://ha.ckers.org/xss.html for some XSS attack examples.
 </p>

 @author Jonathan Hedley
 */
@:allow(org.jsoup.safety.Cleaner)
@:allow(org.jsoup.safety.CleaningVisitor)
class Whitelist {
    private var tagNames:Set<TagName>; // tags allowed, lower case. e.g. [p, br, span]
    private var attributes:Map<TagName, Set<AttributeKey>>; // tag -> attribute[]. allowed attributes [href] for a tag.
    private var enforcedAttributes:Map<TagName, Map<AttributeKey, AttributeValue>>; // always set these attribute values
    private var protocols:Map<TagName, Map<AttributeKey, Set<Protocol>>>; // allowed URL protocols for attributes
    private var preserveRelativeLinks:Bool; // option to preserve relative links

    /**
     This whitelist allows only text nodes: all HTML will be stripped.

     @return whitelist
     */
    public static function none():Whitelist {
        return new Whitelist();
    }

    /**
     This whitelist allows only simple text formatting: <code>b, em, i, strong, u</code>. All other HTML (tags and
     attributes) will be removed.

     @return whitelist
     */
    public static function simpleText():Whitelist {
        return new Whitelist()
                .addTags(["b", "em", "i", "strong", "u"])
                ;
    }

    /**
     <p>
     This whitelist allows a fuller range of text nodes: <code>a, b, blockquote, br, cite, code, dd, dl, dt, em, i, li,
     ol, p, pre, q, small, span, strike, strong, sub, sup, u, ul</code>, and appropriate attributes.
     </p>
     <p>
     Links (<code>a</code> elements) can point to <code>http, https, ftp, mailto</code>, and have an enforced
     <code>rel=nofollow</code> attribute.
     </p>
     <p>
     Does not allow images.
     </p>

     @return whitelist
     */
    public static function basic():Whitelist {
        return new Whitelist()
                .addTags(
                        ["a", "b", "blockquote", "br", "cite", "code", "dd", "dl", "dt", "em",
                        "i", "li", "ol", "p", "pre", "q", "small", "span", "strike", "strong", "sub",
                        "sup", "u", "ul"])

                .addAttributes("a", ["href"])
                .addAttributes("blockquote", ["cite"])
                .addAttributes("q", ["cite"])

                .addProtocols("a", "href", ["ftp", "http", "https", "mailto"])
                .addProtocols("blockquote", "cite", ["http", "https"])
                .addProtocols("cite", "cite", ["http", "https"])

                .addEnforcedAttribute("a", "rel", "nofollow")
                ;

    }

    /**
     This whitelist allows the same text tags as {@link #basic}, and also allows <code>img</code> tags, with appropriate
     attributes, with <code>src</code> pointing to <code>http</code> or <code>https</code>.

     @return whitelist
     */
    public static function basicWithImages():Whitelist {
        return basic()
                .addTags(["img"])
                .addAttributes("img", ["align", "alt", "height", "src", "title", "width"])
                .addProtocols("img", "src", ["http", "https"])
                ;
    }

    /**
     This whitelist allows a full range of text and structural body HTML: <code>a, b, blockquote, br, caption, cite,
     code, col, colgroup, dd, div, dl, dt, em, h1, h2, h3, h4, h5, h6, i, img, li, ol, p, pre, q, small, span, strike, strong, sub,
     sup, table, tbody, td, tfoot, th, thead, tr, u, ul</code>
     <p>
     Links do not have an enforced <code>rel=nofollow</code> attribute, but you can add that if desired.
     </p>

     @return whitelist
     */
    public static function relaxed():Whitelist {
        return new Whitelist()
                .addTags(
                        ["a", "b", "blockquote", "br", "caption", "cite", "code", "col",
                        "colgroup", "dd", "div", "dl", "dt", "em", "h1", "h2", "h3", "h4", "h5", "h6",
                        "i", "img", "li", "ol", "p", "pre", "q", "small", "span", "strike", "strong",
                        "sub", "sup", "table", "tbody", "td", "tfoot", "th", "thead", "tr", "u",
                        "ul"])

                .addAttributes("a", ["href", "title"])
                .addAttributes("blockquote", ["cite"])
                .addAttributes("col", ["span", "width"])
                .addAttributes("colgroup", ["span", "width"])
                .addAttributes("img", ["align", "alt", "height", "src", "title", "width"])
                .addAttributes("ol", ["start", "type"])
                .addAttributes("q", ["cite"])
                .addAttributes("table", ["summary", "width"])
                .addAttributes("td", ["abbr", "axis", "colspan", "rowspan", "width"])
                .addAttributes(
                        "th", ["abbr", "axis", "colspan", "rowspan", "scope",
                        "width"])
                .addAttributes("ul", ["type"])

                .addProtocols("a", "href", ["ftp", "http", "https", "mailto"])
                .addProtocols("blockquote", "cite", ["http", "https"])
                .addProtocols("cite", "cite", ["http", "https"])
                .addProtocols("img", "src", ["http", "https"])
                .addProtocols("q", "cite", ["http", "https"])
                ;
    }

    /**
     Create a new, empty whitelist. Generally it will be better to start with a default prepared whitelist instead.

     @see #basic()
     @see #basicWithImages()
     @see #simpleText()
     @see #relaxed()
     */
    public function new() {
        tagNames = new ListSet<TagName>();
        attributes = new Map<TagName, Set<AttributeKey>>();
        enforcedAttributes = new Map<TagName, Map<AttributeKey, AttributeValue>>();
        protocols = new Map<TagName, Map<AttributeKey, Set<Protocol>>>();
        preserveRelativeLinks = false;
    }

    /**
     Add a list of allowed elements to a whitelist. (If a tag is not allowed, it will be removed from the HTML.)

     @param tags tag names to allow
     @return this (for chaining)
     */
    public function addTags(tags:Array<String>):Whitelist {
        Validate.notNull(tags);

        for (tagName in tags) {
            Validate.notEmpty(tagName);
            tagNames.set(TagName.valueOf(tagName));
        }
        return this;
    }

    /**
     Remove a list of allowed elements from a whitelist. (If a tag is not allowed, it will be removed from the HTML.)

     @param tags tag names to disallow
     @return this (for chaining)
     */
    public function removeTags(tags:Array<String>):Whitelist {
        Validate.notNull(tags);

        for (tag in tags) {
            Validate.notEmpty(tag);
            var tagName:TagName = TagName.valueOf(tag);

            if (tagNames.remove(tagName)) { // Only look in sub-maps if tag was allowed
                attributes.remove(tagName);
                enforcedAttributes.remove(tagName);
                protocols.remove(tagName);
            }
        }
        return this;
    }

    /**
     Add a list of allowed attributes to a tag. (If an attribute is not allowed on an element, it will be removed.)
     <p>
     E.g.: <code>addAttributes("a", "href", "class")</code> allows <code>href</code> and <code>class</code> attributes
     on <code>a</code> tags.
     </p>
     <p>
     To make an attribute valid for <b>all tags</b>, use the pseudo tag <code>:all</code>, e.g.
     <code>addAttributes(":all", "class")</code>.
     </p>

     @param tag  The tag the attributes are for. The tag will be added to the allowed tag list if necessary.
     @param keys List of valid attributes for the tag
     @return this (for chaining)
     */
    public function addAttributes(tag:String, keys:Array<String>):Whitelist {
        Validate.notEmpty(tag);
        Validate.notNull(keys);
        Validate.isTrue(keys.length > 0, "No attributes supplied.");

        var tagName:TagName = TagName.valueOf(tag);
        if (!tagNames.contains(tagName))
            tagNames.set(tagName);
        var attributeSet = new ListSet<AttributeKey>();
        for (key in keys) {
            Validate.notEmpty(key);
            attributeSet.set(AttributeKey.valueOf(key));
        }
        if (attributes.exists(tagName)) {
            var currentSet:Set<AttributeKey> = attributes.get(tagName);
            for (attr in attributeSet) currentSet.set(attr);
        } else {
            attributes.set(tagName, attributeSet);
        }
        return this;
    }

    /**
     Remove a list of allowed attributes from a tag. (If an attribute is not allowed on an element, it will be removed.)
     <p>
     E.g.: <code>removeAttributes("a", "href", "class")</code> disallows <code>href</code> and <code>class</code>
     attributes on <code>a</code> tags.
     </p>
     <p>
     To make an attribute invalid for <b>all tags</b>, use the pseudo tag <code>:all</code>, e.g.
     <code>removeAttributes(":all", "class")</code>.
     </p>

     @param tag  The tag the attributes are for.
     @param keys List of invalid attributes for the tag
     @return this (for chaining)
     */
    public function removeAttributes(tag:String, keys:Array<String>):Whitelist {
        Validate.notEmpty(tag);
        Validate.notNull(keys);
        Validate.isTrue(keys.length > 0, "No attributes supplied.");

        var tagName:TagName = TagName.valueOf(tag);
        var attributeSet = new ListSet<AttributeKey>();
        for (key in keys) {
            Validate.notEmpty(key);
            attributeSet.set(AttributeKey.valueOf(key));
        }
        if(tagNames.contains(tagName) && attributes.exists(tagName)) { // Only look in sub-maps if tag was allowed
            var currentSet:Set<AttributeKey> = attributes.get(tagName);
            for (attrKey in attributeSet) currentSet.remove(attrKey);

            if(currentSet.isEmpty()) // Remove tag from attribute map if no attributes are allowed for tag
                attributes.remove(tagName);
        }
        if(tag == (":all")) // Attribute needs to be removed from all individually set tags
            for (name in attributes.keys()) {
                var currentSet:Set<AttributeKey> = attributes.get(name);
                for (attrKey in attributeSet) currentSet.remove(attrKey);

                if(currentSet.isEmpty()) // Remove tag from attribute map if no attributes are allowed for tag
                    attributes.remove(name);
            }
        return this;
    }

    /**
     Add an enforced attribute to a tag. An enforced attribute will always be added to the element. If the element
     already has the attribute set, it will be overridden.
     <p>
     E.g.: <code>addEnforcedAttribute("a", "rel", "nofollow")</code> will make all <code>a</code> tags output as
     <code>&lt;a href="..." rel="nofollow"&gt;</code>
     </p>

     @param tag   The tag the enforced attribute is for. The tag will be added to the allowed tag list if necessary.
     @param key   The attribute key
     @param value The enforced attribute value
     @return this (for chaining)
     */
    public function addEnforcedAttribute(tag:String, key:String, value:String):Whitelist {
        Validate.notEmpty(tag);
        Validate.notEmpty(key);
        Validate.notEmpty(value);

        var tagName:TagName = TagName.valueOf(tag);
        if (!tagNames.contains(tagName))
            tagNames.set(tagName);
        var attrKey:AttributeKey = AttributeKey.valueOf(key);
        var attrVal:AttributeValue = AttributeValue.valueOf(value);

        if (enforcedAttributes.exists(tagName)) {
            enforcedAttributes.get(tagName).set(attrKey, attrVal);
        } else {
            var attrMap = new Map<AttributeKey, AttributeValue>();
            attrMap.set(attrKey, attrVal);
            enforcedAttributes.set(tagName, attrMap);
        }
        return this;
    }

    /**
     Remove a previously configured enforced attribute from a tag.

     @param tag   The tag the enforced attribute is for.
     @param key   The attribute key
     @return this (for chaining)
     */
    public function removeEnforcedAttribute(tag:String, key:String):Whitelist {
        Validate.notEmpty(tag);
        Validate.notEmpty(key);

        var tagName:TagName = TagName.valueOf(tag);
        if (tagNames.contains(tagName) && enforcedAttributes.exists(tagName)) {
            var attrKey:AttributeKey = AttributeKey.valueOf(key);
            var attrMap:Map<AttributeKey, AttributeValue> = enforcedAttributes.get(tagName);
            attrMap.remove(attrKey);

            if ([for (k in attrMap.keys()) k].length == 0) // Remove tag from enforced attribute map if no enforced attributes are present
                enforcedAttributes.remove(tagName);
        }
        return this;
    }

    /**
     * Configure this Whitelist to preserve relative links in an element's URL attribute, or convert them to absolute
     * links. By default, this is <b>false</b>: URLs will be  made absolute (e.g. start with an allowed protocol, like
     * e.g. {@code http://}.
     * <p>
     * Note that when handling relative links, the input document must have an appropriate {@code base URI} set when
     * parsing, so that the link's protocol can be confirmed. Regardless of the setting of the {@code preserve relative
     * links} option, the link must be resolvable against the base URI to an allowed protocol; otherwise the attribute
     * will be removed.
     * </p>
     *
     * @param preserve {@code true} to allow relative links, {@code false} (default) to deny
     * @return this Whitelist, for chaining.
     * @see #addProtocols
     */
	//NOTE(az): setter
    public function setPreserveRelativeLinks(preserve:Bool):Whitelist {
        preserveRelativeLinks = preserve;
        return this;
    }

    /**
     Add allowed URL protocols for an element's URL attribute. This restricts the possible values of the attribute to
     URLs with the defined protocol.
     <p>
     E.g.: <code>addProtocols("a", "href", "ftp", "http", "https")</code>
     </p>
     <p>
     To allow a link to an in-page URL anchor (i.e. <code>&lt;a href="#anchor"&gt;</code>, add a <code>#</code>:<br>
     E.g.: <code>addProtocols("a", "href", "#")</code>
     </p>

     @param tag       Tag the URL protocol is for
     @param key       Attribute key
     @param protocols List of valid protocols
     @return this, for chaining
     */
    public function addProtocols(tag:String, key:String, protocols:Array<String>):Whitelist {
        Validate.notEmpty(tag);
        Validate.notEmpty(key);
        Validate.notNull(protocols);

        var tagName:TagName = TagName.valueOf(tag);
        var attrKey:AttributeKey = AttributeKey.valueOf(key);
        var attrMap:Map<AttributeKey, Set<Protocol>>;
        var protSet:Set<Protocol>;

        if (this.protocols.exists(tagName)) {
            attrMap = this.protocols.get(tagName);
        } else {
            attrMap = new Map<AttributeKey, Set<Protocol>>();
            this.protocols.set(tagName, attrMap);
        }
        if (attrMap.exists(attrKey)) {
            protSet = attrMap.get(attrKey);
        } else {
            protSet = new ListSet<Protocol>();
            attrMap.set(attrKey, protSet);
        }
        for (protocol in protocols) {
            Validate.notEmpty(protocol);
            var prot:Protocol = Protocol.valueOf(protocol);
            protSet.set(prot);
        }
        return this;
    }

    /**
     Remove allowed URL protocols for an element's URL attribute.
     <p>
     E.g.: <code>removeProtocols("a", "href", "ftp")</code>
     </p>

     @param tag       Tag the URL protocol is for
     @param key       Attribute key
     @param protocols List of invalid protocols
     @return this, for chaining
     */
    public function removeProtocols(tag:String, key:String, protocols:Array<String>):Whitelist {
        Validate.notEmpty(tag);
        Validate.notEmpty(key);
        Validate.notNull(protocols);

        var tagName:TagName = TagName.valueOf(tag);
        var attrKey:AttributeKey = AttributeKey.valueOf(key);

        if(this.protocols.exists(tagName)) {
            var attrMap:Map<AttributeKey, Set<Protocol>> = this.protocols.get(tagName);
            if(attrMap.exists(attrKey)) {
                var protSet:Set<Protocol> = attrMap.get(attrKey);
                for (protocol in protocols) {
                    Validate.notEmpty(protocol);
                    var prot:Protocol = Protocol.valueOf(protocol);
                    protSet.remove(prot);
                }

                if(protSet.isEmpty()) { // Remove protocol set if empty
                    attrMap.remove(attrKey);
                    if([for (k in attrMap.keys()) k].length == 0) // Remove entry for tag if empty
                        this.protocols.remove(tagName);
                }
            }
        }
        return this;
    }

    /**
     * Test if the supplied tag is allowed by this whitelist
     * @param tag test tag
     * @return true if allowed
     */
    /*protected*/ function isSafeTag(tag:String):Bool {
        return tagNames.contains(TagName.valueOf(tag));
    }

    /**
     * Test if the supplied attribute is allowed by this whitelist for this tag
     * @param tagName tag to consider allowing the attribute in
     * @param el element under test, to confirm protocol
     * @param attr attribute under test
     * @return true if allowed
     */
    /*protected*/ function isSafeAttribute(tagName:String, el:Element, attr:Attribute):Bool {
        var tag:TagName = TagName.valueOf(tagName);
        var key:AttributeKey = AttributeKey.valueOf(attr.getKey());

        if (attributes.exists(tag)) {
            if (attributes.get(tag).contains(key)) {
                if (protocols.exists(tag)) {
                    var attrProts:Map<AttributeKey, Set<Protocol>> = protocols.get(tag);
                    // ok if not defined protocol; otherwise test
                    return !attrProts.exists(key) || testValidProtocol(el, attr, attrProts.get(key));
                } else { // attribute found, no protocols defined, so OK
                    return true;
                }
            }
        }
        // no attributes defined for tag, try :all tag
        return !(tagName == (":all")) && isSafeAttribute(":all", el, attr);
    }

    private function testValidProtocol(el:Element, attr:Attribute, protocols:Set<Protocol>):Bool {
        // try to resolve relative urls to abs, and optionally update the attribute so output html has abs.
        // rels without a baseuri get removed
        var value:String = el.absUrl(attr.getKey());
        if (value.length == 0)
            value = attr.getValue(); // if it could not be made abs, run as-is to allow custom unknown protocols
        if (!preserveRelativeLinks)
            attr.setValue(value);
        
        for (protocol in protocols) {
            var prot:String = protocol.toString();

            if (prot == ("#")) { // allows anchor links
                if (isValidAnchor(value)) {
                    return true;
                } else {
                    continue;
                }
            }

            prot += ":";

            if (value.toLowerCase().startsWith(prot)) {
                return true;
            }
        }
        return false;
    }

    private function isValidAnchor(value:String):Bool {
        return value.startsWith("#") && !(~/.*\\s.*/.match(value));
    }

    function getEnforcedAttributes(tagName:String):Attributes {
        var attrs = new Attributes();
        var tag:TagName = TagName.valueOf(tagName);
        if (enforcedAttributes.exists(tag)) {
            var keyVals:Map<AttributeKey, AttributeValue> = enforcedAttributes.get(tag);
            for (key in keyVals.keys()) {
                attrs.put(key.toString(), keyVals[key].toString());
            }
        }
        return attrs;
    }
    
}


// named types for config. All just hold strings, but here for my sanity.

@:allow(org.jsoup.safety.Whitelist)
/*static*/ class TagName extends TypedValue {
	function new(value:String) {
		super(value);
	}

	static function valueOf(value:String):TagName {
		return new TagName(value);
	}
}

@:allow(org.jsoup.safety.Whitelist)
/*static*/ class AttributeKey extends TypedValue {
	function new(value:String) {
		super(value);
	}

	static function valueOf(value:String):AttributeKey {
		return new AttributeKey(value);
	}
}

@:allow(org.jsoup.safety.Whitelist)
/*static*/ class AttributeValue extends TypedValue {
	function new(value:String) {
		super(value);
	}

	static function valueOf(value:String):AttributeValue {
		return new AttributeValue(value);
	}
}

@:allow(org.jsoup.safety.Whitelist)
/*static*/ class Protocol extends TypedValue {
	function new(value:String) {
		super(value);
	}

	static function valueOf(value:String):Protocol {
		return new Protocol(value);
	}
}

@:allow(org.jsoup.safety.Whitelist)
/*abstract static*/ class TypedValue {
	private var value:String;

	function new(value:String) {
		Validate.notNull(value);
		this.value = value;
	}

	//@Override
	//NOTE(az): needed?
	/*public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((value == null) ? 0 : value.hashCode());
		return result;
	}*/

	//@Override
	//NOTE(az): needed?
	/*public boolean equals(Object obj) {
		if (this == obj) return true;
		if (obj == null) return false;
		if (getClass() != obj.getClass()) return false;
		TypedValue other = (TypedValue) obj;
		if (value == null) {
			if (other.value != null) return false;
		} else if (!value.equals(other.value)) return false;
		return true;
	}*/

	//@Override
	public function toString():String {
		return value;
	}
}
