package org.jsoup.nodes;

import org.jsoup.Exceptions.MissingResourceException;
import org.jsoup.helper.StringUtil;
import org.jsoup.nodes.Document.CharsetEncoder;
import org.jsoup.parser.Parser;
import unifill.CodePoint;

using StringTools;
using unifill.Unifill;

/*import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.CharsetEncoder;
import java.util.*;
*/

typedef Character = String;

/**
 * HTML entities, and escape routines.
 * Source: <a href="http://www.w3.org/TR/html5/named-character-references.html#named-character-references">W3C HTML
 * named character references</a>.
 */
//NOTE(az): refactored EscapeMode
@:allow(org.jsoup.nodes.EscapeMode)
class Entities {

	public static inline var MIN_SUPPLEMENTARY_CODE_POINT:CodePoint = 0x10000;
	
    private static var full:Map<String, Character>;
    private static var xhtmlByVal:Map<Character, String>;
    private static var base:Map<String, Character>;
    private static var baseByVal:Map<Character, String>;
    private static var fullByVal:Map<Character, String>;
	
	static var maps:Map<EscapeMode, Map<Character, String>>;

    function new() {}

    /**
     * Check if the input is a known named entity
     * @param name the possible entity name (e.g. "lt" or "amp")
     * @return true if a known named entity
     */
    public static function isNamedEntity(name:String):Bool {
        return full.exists(name);
    }

    /**
     * Check if the input is a known named entity in the base entity set.
     * @param name the possible entity name (e.g. "lt" or "amp")
     * @return true if a known named entity in the base set
     * @see #isNamedEntity(String)
     */
    public static function isBaseNamedEntity(name:String):Bool {
        return base.exists(name);
    }

    /**
     * Get the Character value of the named entity
     * @param name named entity (e.g. "lt" or "amp")
     * @return the Character value of the named entity (e.g. '{@literal <}' or '{@literal &}')
     */
    public static function getCharacterByName(name:String):Character {
        return full.get(name);
    }
    
    public static function escape(string:String, out:Document.OutputSettings):String {
        var accum = new StringBuf(/*string.length() * 2*/);
        _escape(accum, string, out, false, false, false);
        return accum.toString();
    }

    // this method is ugly, and does a lot. but other breakups cause rescanning and stringbuilder generations
    public static function _escape(accum:StringBuf, string:String, out:Document.OutputSettings,
                   inAttribute:Bool, normaliseWhite:Bool, stripLeadingWhite:Bool):Void {

        var lastWasWhite:Bool = false;
        var reachedNonWhite:Bool = false;
        var escapeMode:EscapeMode = out.getEscapeMode();
        var encoder:CharsetEncoder = out.encoder();
        var coreCharset:CoreCharset = CoreCharset.byName(encoder.charset.name());
        var map:Map<Character, String> = escapeMode.getMap();
        var length = string.uLength();

        var codePoint:CodePoint = 0;
        //NOTE(az): recheck this loop
		//for (int offset = 0; offset < length; offset += Character.charCount(codePoint)) {
		var offset = 0;
		while (offset < length) {
            codePoint = string.uCodePointAt(offset);

            if (normaliseWhite) {
                if (StringUtil.isWhitespace(codePoint)) {
                    if ((stripLeadingWhite && !reachedNonWhite) || lastWasWhite)
                        continue;
                    accum.add(' ');
                    lastWasWhite = true;
                    continue;
                } else {
                    lastWasWhite = false;
                    reachedNonWhite = true;
                }
            }
            // surrogate pairs, split implementation for efficiency on single char common case (saves creating strings, char[]):
            if (codePoint < MIN_SUPPLEMENTARY_CODE_POINT) {
                var c:Int = codePoint;
				var cpStr = codePoint.toString();
                // html specific and required escapes:
                switch (c) {
                    case '&'.code:
                        accum.add("&amp;");
                    case 0xA0:
                        if (escapeMode != EscapeMode.xhtml)
                            accum.add("&nbsp;");
                        else
                            accum.add("&#xa0;");
                    case '<'.code:
                        // escape when in character data or when in a xml attribue val; not needed in html attr val
                        if (!inAttribute || escapeMode == EscapeMode.xhtml)
                            accum.add("&lt;");
                        else
                            accum.add(codePoint.toString());
                    case '>'.code:
                        if (!inAttribute)
                            accum.add("&gt;");
                        else
                            accum.add(cpStr);
                    case '"'.code:
                        if (inAttribute)
                            accum.add("&quot;");
                        else
                            accum.add(cpStr);
                    default:
                        if (canEncode(coreCharset, c, encoder))
                            accum.add(cpStr);
                        else if (map.exists(cpStr)) {
                            accum.add('&');
							accum.add(map.get(cpStr));
							accum.add(';');
						}
                        else {
                            accum.add("&#x");
							accum.add(StringTools.hex(codePoint));
							accum.add(';');
						}
                }
            } else {
                var c:String = codePoint.toString();
                if (encoder.canEncode(codePoint)) // uses fallback encoder for simplicity
                    accum.add(c);
                else
                    accum.add("&#x");
					accum.add(StringTools.hex(codePoint));
					accum.add(';');
            }
			
			offset += codePoint.toString().uLength();
        }
    }

    /**
     * Unescape the input string.
     * @param string to un-HTML-escape
     * @param strict if "strict" (that is, requires trailing ';' char, otherwise that's optional)
     * @return unescaped string
     */
    public static function unescape(string:String, strict:Bool = false):String {
        return Parser.unescapeEntities(string, strict);
    }

    /*
     * Provides a fast-path for Encoder.canEncode, which drastically improves performance on Android post JellyBean.
     * After KitKat, the implementation of canEncode degrades to the point of being useless. For non ASCII or UTF,
     * performance may be bad. We can add more encoders for common character sets that are impacted by performance
     * issues on Android if required.
     *
     * Benchmarks:     *
     * OLD toHtml() impl v New (fastpath) in millis
     * Wiki: 1895, 16
     * CNN: 6378, 55
     * Alterslash: 3013, 28
     * Jsoup: 167, 2
     */

    private static function canEncode(charset:CoreCharset, c:CodePoint, fallback:CharsetEncoder):Bool {
        // todo add more charset tests if impacted by Android's bad perf in canEncode
        switch (charset) {
            case ascii:
                return c < 0x80;
            case utf:
                return true; // real is:!(Character.isLowSurrogate(c) || Character.isHighSurrogate(c)); - but already check above
            default:
                return fallback.canEncode(c);
        }
    }


    // xhtml has restricted entities
    private static var xhtmlArray:Map<String, CodePoint>;

    static function __init__() {
		xhtmlArray = [
            "quot" => 0x00022,
            "amp" => 0x00026,
            "lt" => 0x0003C,
            "gt" => 0x0003E
		];
        xhtmlByVal = new Map<Character, String>();
        base = loadEntities("entities-base.properties");  // most common / default
        baseByVal = toCharacterKey(base);
        full = loadEntities("entities-full.properties"); // extended and overblown.
        fullByVal = toCharacterKey(full);

        for (key in xhtmlArray.keys()) {
            var c:CodePoint = xhtmlArray[key];
            xhtmlByVal.set(c.toString(), key);
        }
		
		Entities.maps = [
			EscapeMode.base => baseByVal,
			EscapeMode.extended => fullByVal,
			EscapeMode.xhtml => xhtmlByVal
		];
    }

	//NOTE(az): check loading is done correcty (resources, splitting, etc.)
    private static function loadEntities(filename:String):Map<String, Character> {
        var entities = new Map<String, Character>();
        try {
            var resource = haxe.Resource.getString(filename);
            var entries = resource.split("\n");
			for (entry in entries) {
				var pair = entry.split("=");
				if (pair.length == 2) {
					var name = pair[0];
					var val:CodePoint = Std.parseInt("0x" + pair[1]);
					entities.set(name, val.toString());
				}
			}
        } catch (e:Dynamic) {
            throw new MissingResourceException("Error loading entities resource. Entities: " + filename);
        }
		
        return entities;
    }

    private static function toCharacterKey(inMap:Map<String, Character>):Map<Character, String> {
        var outMap = new Map<Character, String>();
        for (key in inMap.keys()) {
            var character:Character = inMap[key];
            var name:String = key;

            if (outMap.exists(character)) {
                // dupe, prefer the lower case version
                if (name.toLowerCase() == name)
                    outMap.set(character, name);
            } else {
                outMap.set(character, name);
            }
        }
        return outMap;
    }
}

@:enum abstract EscapeMode(String) from String to String {
	
	/** Restricted entities suitable for XHTML output: lt, gt, amp, and quot only. */
	var xhtml = "XHTML";
	/** Default HTML output entities. */
	var base = "BASE";
	/** Complete HTML entities. */
	var extended = "EXTENDED";

	public function getMap():Map<Character, String> {
		trace(this);
		trace(Entities.maps.get(this) != null);
		
		return Entities.maps.get(this);
	}
}

@:enum abstract CoreCharset(String) from String to String {
	var ascii = "ASCII";
	var utf = "UTF";
	var fallback = "FALLBACK";

	static public function byName(name:String):String {
		if (name == "US-ASCII")
			return ascii;
		if (name.startsWith("UTF-")) // covers UTF-8, UTF-16, et al
			return utf;
		return fallback;
	}
}

