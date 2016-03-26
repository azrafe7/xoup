package org.jsoup.helper;

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.Itr;
import org.jsoup.Exceptions.IllegalArgumentException;
import org.jsoup.helper.StringBuilder;

import StringTools;

using unifill.Unifill;

/*import java.net.MalformedURLException;
import de.polygonal.ds.Itr;
import java.net.URL;
import java.util.Arrays;
import java.util.Collection;
import java.util.Iterator;*/

/**
 * A minimal String utility class. Designed for internal jsoup use only.
 */
//NOTE(az): missing resolve and unicode support
class StringUtil {
    // memoised padding up to 10
    private static var padding:Array<String> = ["", " ", "  ", "   ", "    ", "     ", "      ", "       ", "        ", "         ", "          "];

    /**
     * Join a collection of strings by a seperator
     * @param strings collection of string objects
     * @param sep string to place between strings
     * @return joined string
     */
    //NOTE(az): commented out
	/*public static function join(Collection strings, String sep) {
        return join(strings.iterator(), sep);
    }*/

    /**
     * Join a collection of strings by a seperator
     * @param strings iterator of string objects
     * @param sep string to place between strings
     * @return joined string
     */
	//NOTE(az): toString with Std.string
    public static function join<T>(strings:Itr<T>, sep:String) {
        if (!strings.hasNext())
            return "";

        var start = Std.string(strings.next());
        if (!strings.hasNext()) // only one, avoid builder
            return start;

        var sb = new StringBuilder(/*64*/);
		sb.add(start);
        while (strings.hasNext()) {
            sb.add(sep);
            sb.add(Std.string(strings.next()));
        }
        return sb.toString();
    }

    /**
     * Returns space padding
     * @param width amount of padding desired
     * @return string of spaces * width
     */
	//NOTE(az): getter
    public static function getPadding(width:Int):String {
        if (width < 0)
            throw new IllegalArgumentException("width must be > 0");

        if (width < padding.length)
            return padding[width];

        var sb = new StringBuilder();
        for (i in 0...width)
            sb.add(' ');
        return sb.toString();
    }

    /**
     * Tests if a string is blank: null, emtpy, or only whitespace (" ", \r\n, \t, etc)
     * @param string string to test
     * @return if string is blank
     */
	//NOTE(az): codepointat
    public static function isBlank(string:String):Bool {
        if (string == null || string.length == 0)
            return true;

        var l = string.length;
        for (i in 0...l) {
            if (!StringUtil.isWhitespace(string.charCodeAt(i)))
                return false;
        }
        return true;
    }

    /**
     * Tests if a string is numeric, i.e. contains only digit characters
     * @param string string to test
     * @return true if only digit chars, false if empty or null or contains non-digit chrs
     */
	//NOTE(az): codepointat
    public static function isNumeric(string:String):Bool {
        if (string == null || string.length == 0)
            return false;

        var l = string.length;
        for (i in 0...l) {
			var code = string.charCodeAt(i);
            if (!(code >= "0".code && code <= "9".code))
                return false;
        }
        return true;
    }

    /**
     * Tests if a code point is "whitespace" as defined in the HTML spec.
     * @param c code point to test
     * @return true if code point is whitespace, false otherwise
     */
    public static function isWhitespace(c:Int):Bool {
        return c == " ".code || c == "\t".code || c == "\n".code || c == 0xC /*"\f".code*/ || c == "\r".code;
    }

    /**
     * Normalise the whitespace within this string; multiple spaces collapse to a single, and all whitespace characters
     * (e.g. newline, tab) convert to a simple space
     * @param string content to normalise
     * @return normalised string
     */
    public static function normaliseWhitespace(string:String):String {
        var sb = new StringBuilder(/*string.length()*/);
        appendNormalisedWhitespace(sb, string, false);
        return sb.toString();
    }

    /**
     * After normalizing the whitespace within a string, appends it to a string builder.
     * @param accum builder to append to
     * @param string string to normalize whitespace within
     * @param stripLeading set to true if you wish to remove any leading whitespace
     */
	//NOTE(az): using uIterator()
    public static function appendNormalisedWhitespace(accum:StringBuilder, string:String, stripLeading:Bool):Void {
        var lastWasWhite = false;
        var reachedNonWhite = false;

        for (c in string.uIterator()) {
            if (isWhitespace(c)) {
                if ((stripLeading && !reachedNonWhite) || lastWasWhite)
                    continue;
                accum.add(' ');
                lastWasWhite = true;
            }
            else {
                accum.uAddChar(c);
                lastWasWhite = false;
                reachedNonWhite = true;
            }
        }
    }

	//NOTE(az): renamed
	public static function isAnyOf(needle:String, haystack:Array<String>):Bool {
        for (hay in haystack) {
            if (hay == needle)
            return true;
        }
        return false;
    }

	//NOTE(az): renamed
    public static function isAnyOfSorted(needle:String, haystack:Array<String>):Bool {
        return ArrayTools.bsearchComparator(haystack, needle, 0, haystack.length - 1, Reflect.compare) >= 0;
    }

    /**
     * Create a new absolute URL, from a provided existing absolute URL and a relative URL component.
     * @param base the existing absolulte base URL
     * @param relUrl the relative URL to resolve. (If it's already absolute, it will be returned)
     * @return the resolved absolute URL
     * @throws MalformedURLException if an error occurred generating the URL
     */
    /*public static URL resolve(URL base, String relUrl) throws MalformedURLException {
        // workaround: java resolves '//path/file + ?foo' to '//path/?foo', not '//path/file?foo' as desired
        if (relUrl.startsWith("?"))
            relUrl = base.getPath() + relUrl;
        // workaround: //example.com + ./foo = //example.com/./foo, not //example.com/foo
        if (relUrl.indexOf('.') == 0 && base.getFile().indexOf('/') != 0) {
            base = new URL(base.getProtocol(), base.getHost(), base.getPort(), "/" + base.getFile());
        }
        return new URL(base, relUrl);
    }*/

    /**
     * Create a new absolute URL, from a provided existing absolute URL and a relative URL component.
     * @param baseUrl the existing absolute base URL
     * @param relUrl the relative URL to resolve. (If it's already absolute, it will be returned)
     * @return an absolute URL if one was able to be generated, or the empty string if not
     */
	//NOTE(az): workaround: it simply joins the urls for now
    public static function resolve(baseUrl:String, relUrl:String):String {
        /*URL base;
        try {
            try {
                base = new URL(baseUrl);
            } catch (MalformedURLException e) {
                // the base is unsuitable, but the attribute/rel may be abs on its own, so try that
                URL abs = new URL(relUrl);
                return abs.toExternalForm();
            }
            return resolve(base, relUrl).toExternalForm();
        } catch (MalformedURLException e) {
            return "";
        }
		*/
		return baseUrl + relUrl;
    }
	
	/**
		Encodes `n` into a hexadecimal representation.

		If `digits` is specified, the resulting String is padded with "0" until
		its length equals `digits`.
	**/
	public static function toHex( n : Int, ?digits : Int ) {
		var s = "";
		var hexChars = "0123456789abcdef";
		do {
			s = hexChars.charAt(n&15) + s;
			n >>>= 4;
		} while( n > 0 );
		#if python
		if (digits != null && s.length < digits) {
			var diff = digits - s.length;
			for (_ in 0...diff) {
				s = "0" + s;
			}
		}
		#else
		if( digits != null )
			while( s.length < digits )
				s = "0"+s;
		#end
		return s;
	}
	
}
