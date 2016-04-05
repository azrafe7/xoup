package org.jsoup.parser.tokens;

import org.jsoup.helper.StringBuilder;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Attribute;
import org.jsoup.nodes.Attributes;
import org.jsoup.nodes.BooleanAttribute;

/**
 * Parse tokens for the Tokeniser.
 */
//NOTE(az): brought internal classes out, move in its own package to avoid conflicts
@:allow(org.jsoup.parser)
/*abstract*/ class Token {
    var type:TokenType;

    private function new() {
    }
    
    function tokenType():String {
        //NOTE(az): using Type here
		//return this.getClass().getSimpleName();
		return Type.getClassName(Type.getClass(this));
    }

    /**
     * Reset the data represent by this token, for reuse. Prevents the need to create transfer objects for every
     * piece of data, which immediately get GCed.
     */
    /*abstract*/ function reset():Token { throw "Abstract"; };

	//NOTE(az): renamed resetBuf
    static function resetBuf(sb:StringBuilder):Void {
        if (sb != null) {
			//NOTE(az): recreate
			//sb.delete(0, sb.length());
            sb.reset();
        }
    }
	
	function isDoctype():Bool {
		return type == TokenType.Doctype;
	}

	function asDoctype():TokenDoctype {
		return cast this;
	}

	function isStartTag():Bool {
		return type == TokenType.StartTag;
	}

	function asStartTag():TokenStartTag {
		return cast this;
	}

	function isEndTag():Bool {
		return type == TokenType.EndTag;
	}

	function asEndTag():TokenEndTag {
		return cast this;
	}

	function isComment():Bool {
		return type == TokenType.Comment;
	}

	function asComment():TokenComment {
		return cast this;
	}

	function isCharacter():Bool {
		return type == TokenType.Character;
	}

	function asCharacter():TokenCharacter {
		return cast this;
	}

	function isEOF():Bool {
		return type == TokenType.EOF;
	}
	
	function toString():String {
		return '<${tokenType()}>';
	}
}


@:allow(org.jsoup.parser)
/*static final*/ class TokenDoctype extends Token {
	var name:StringBuilder = new StringBuilder();
	var publicIdentifier:StringBuilder = new StringBuilder();
	var systemIdentifier:StringBuilder = new StringBuilder();
	var forceQuirks:Bool = false;

	function new() {
		super();
		type = TokenType.Doctype;
	}

	//@Override
	override function reset():Token {
		Token.resetBuf(name);
		Token.resetBuf(publicIdentifier);
		Token.resetBuf(systemIdentifier);
		forceQuirks = false;
		return this;
	}

	function getName():String {
		return name.toString();
	}

	function getPublicIdentifier():String {
		return publicIdentifier.toString();
	}

	public function getSystemIdentifier():String {
		return systemIdentifier.toString();
	}

	public function isForceQuirks():Bool {
		return forceQuirks;
	}
}


@:allow(org.jsoup.parser)
/*static abstract*/ class TokenTag extends Token {
	/*protected*/ var tagName:String;
	private var pendingAttributeName:String; // attribute names are generally caught in one hop, not accumulated
	private var pendingAttributeValue:StringBuilder = new StringBuilder(); // but values are accumulated, from e.g. & in hrefs
	private var hasEmptyAttributeValue:Bool = false; // distinguish boolean attribute from empty string value
	private var hasPendingAttributeValue:Bool = false;
	var selfClosing:Bool = false;
	var attributes:Attributes; // start tags get attributes on construction. End tags get attributes on first new attribute (but only for parser convenience, not used).

	//@Override
	override function reset():TokenTag {
		tagName = null;
		pendingAttributeName = null;
		Token.resetBuf(pendingAttributeValue);
		hasEmptyAttributeValue = false;
		hasPendingAttributeValue = false;
		selfClosing = false;
		attributes = null;
		return this;
	}

	function newAttribute():Void {
		if (attributes == null)
			attributes = new Attributes();

		if (pendingAttributeName != null) {
			var attribute:Attribute;
			if (hasPendingAttributeValue)
				attribute = new Attribute(pendingAttributeName, pendingAttributeValue.toString());
			else if (hasEmptyAttributeValue)
				attribute = new Attribute(pendingAttributeName, "");
			else
				attribute = new BooleanAttribute(pendingAttributeName);
			attributes.putAttr(attribute);
		}
		pendingAttributeName = null;
		hasEmptyAttributeValue = false;
		hasPendingAttributeValue = false;
		Token.resetBuf(pendingAttributeValue);
	}

	function finaliseTag():Void {
		// finalises for emit
		if (pendingAttributeName != null) {
			// todo: check if attribute name exists; if so, drop and error
			newAttribute();
		}
	}

	//NOTE(az): renamed
	function getName():String {
		Validate.isFalse(tagName == null || tagName.length == 0);
		return tagName;
	}

	//NOTE(az): setter
	function setName(name:String):TokenTag {
		tagName = name;
		return this;
	}

	function isSelfClosing():Bool {
		return selfClosing;
	}

	//@SuppressWarnings({"TypeMayBeWeakened"})
	function getAttributes():Attributes {
		return attributes;
	}

	// these appenders are rarely hit in not null state-- caused by null chars.
	function appendTagName(append:String):Void {
		tagName = tagName == null ? append : tagName + append;
	}

	//NOTE(az): removed
	/*final void appendTagName(char append) {
		appendTagName(String.valueOf(append));
	}*/

	function appendAttributeName(append:String):Void {
		pendingAttributeName = pendingAttributeName == null ? append : pendingAttributeName + append;
	}

	//NOTE(az): removed
	/*final void appendAttributeName(char append) {
		appendAttributeName(String.valueOf(append));
	}*/

	function appendAttributeValue(append:String):Void {
		ensureAttributeValue();
		pendingAttributeValue.add(append);
	}

	//NOTE(az): removed
	/*final void appendAttributeValue(char append) {
		ensureAttributeValue();
		pendingAttributeValue.append(append);
	}*/

	//NOTE(az): removed
	/*final void appendAttributeValue(char[] append) {
		ensureAttributeValue();
		pendingAttributeValue.append(append);
	}*/
	
	function setEmptyAttributeValue():Void {
		hasEmptyAttributeValue = true;
	}

	private function ensureAttributeValue():Void {
		hasPendingAttributeValue = true;
	}
}


@:allow(org.jsoup.parser)
/*final static*/ class TokenStartTag extends TokenTag {
	function new() {
		super();
		attributes = new Attributes();
		type = TokenType.StartTag;
	}

	//@Override
	override function reset():TokenTag {
		super.reset();
		attributes = new Attributes();
		// todo - would prefer these to be null, but need to check Element assertions
		return this;
	}

	function nameAttr(name:String, attributes:Attributes):TokenStartTag {
		this.tagName = name;
		this.attributes = attributes;
		return this;
	}

	//@Override
	override public function toString():String {
		if (attributes != null && attributes.size > 0)
			return "<" + getName() + " " + attributes.toString() + ">";
		else
			return "<" + getName() + ">";
	}
}

/*final static*/ class TokenEndTag extends TokenTag {
	function new() {
		super();
		type = TokenType.EndTag;
	}

	//@Override
	override public function toString() {
		return "</" + getName() + ">";
	}
}

@:allow(org.jsoup.parser)
/*final static*/ class TokenComment extends Token {
	public var data:StringBuilder = new StringBuilder();
	public var bogus:Bool = false;

	//@Override
	override function reset():Token {
		Token.resetBuf(data);
		bogus = false;
		return this;
	}

	function new() {
		super();
		type = TokenType.Comment;
	}

	function getData():String {
		return data.toString();
	}

	//@Override
	override public function toString():String {
		return "<!--" + getData() + "-->";
	}
}

@:allow(org.jsoup.parser)
/*final static*/ class TokenCharacter extends Token {
	private var data:String;

	function new() {
		super();
		type = TokenType.Character;
	}

	//@Override
	override function reset():Token {
		data = null;
		return this;
	}

	//NOTE(az): setter
	function setData(data:String):TokenCharacter {
		this.data = data;
		return this;
	}

	//NOTE(az): getter
	function getData():String {
		return data;
	}

	//@Override
	override public function toString():String {
		return getData();
	}
}

/*final static*/ class TokenEOF extends Token {
	function new() {
		super();
		type = Token.TokenType.EOF;
	}

	//@Override
	override function reset():Token {
		return this;
	}
}


enum TokenType {
	Doctype;
	StartTag;
	EndTag;
	Comment;
	Character;
	EOF;
}
