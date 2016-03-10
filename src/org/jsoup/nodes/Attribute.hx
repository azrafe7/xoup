package org.jsoup.nodes;

import de.polygonal.ds.Cloneable;
import de.polygonal.ds.tools.ArrayTools;
import org.jsoup.helper.Validate;

using StringTools;

/*import java.util.Arrays;
import java.util.Map;
*/

/**
 A single key + value attribute. Keys are trimmed and normalised to lower-case.

 @author Jonathan Hedley, jonathan@hedley.net */
//NOTE(az): Map.Entry, equals, hashcode
class Attribute implements /*Map.Entry<String, String>,*/ Cloneable<Attribute>  {
    private static var booleanAttributes:Array<String> = [
            "allowfullscreen", "async", "autofocus", "checked", "compact", "declare", "default", "defer", "disabled",
            "formnovalidate", "hidden", "inert", "ismap", "itemscope", "multiple", "muted", "nohref", "noresize",
            "noshade", "novalidate", "nowrap", "open", "readonly", "required", "reversed", "seamless", "selected",
            "sortable", "truespeed", "typemustmatch"
    ];

    private var key:String;
    private var value:String;

    /**
     * Create a new attribute from unencoded (raw) key and value.
     * @param key attribute key
     * @param value attribute value
     * @see #createFromEncoded
     */
    public function new(key:String, value:String) {
        Validate.notEmpty(key);
        Validate.notNull(value);
        this.key = key.trim().toLowerCase();
        this.value = value;
    }

    /**
     Get the attribute key.
     @return the attribute key
     */
    public function getKey():String {
        return key;
    }

    /**
     Set the attribute key. Gets normalised as per the constructor method.
     @param key the new key; must not be null
     */
    public function setKey(key:String):Void {
        Validate.notEmpty(key);
        this.key = key.trim().toLowerCase();
    }

    /**
     Get the attribute value.
     @return the attribute value
     */
    public function getValue():String {
        return value;
    }

    /**
     Set the attribute value.
     @param value the new attribute value; must not be null
     */
    public function setValue(value:String):String {
        Validate.notNull(value);
        var old = this.value;
        this.value = value;
        return old;
    }

    /**
     Get the HTML representation of this attribute; e.g. {@code href="index.html"}.
     @return HTML
     */
    public function html():String {
        var accum = new StringBuf();
        _html(accum, (new Document("")).getOutputSettings());
        return accum.toString();
    }
    
    /*protected*/ public function _html(accum:StringBuf, out:Document.OutputSettings):Void {
        accum.add(key);
        if (!shouldCollapseAttribute(out)) {
            accum.add("=\"");
            Entities._escape(accum, value, out, true, false, false);
            accum.add('"');
        }
    }

    /**
     Get the string representation of this attribute, implemented as {@link #html()}.
     @return string
     */
    //@Override
    public function toString():String {
        return html();
    }

    /**
     * Create a new Attribute from an unencoded key and a HTML attribute encoded value.
     * @param unencodedKey assumes the key is not encoded, as can be only run of simple \w chars.
     * @param encodedValue HTML attribute encoded value
     * @return attribute
     */
    public static function createFromEncoded(unencodedKey:String, encodedValue:String):Attribute {
        var value:String = Entities.unescape(encodedValue, true);
        return new Attribute(unencodedKey, value);
    }

    /*protected*/ function isDataAttribute():Bool {
        return key.startsWith(Attributes.dataPrefix) && key.length > Attributes.dataPrefix.length;
    }

    /**
     * Collapsible if it's a boolean attribute and value is empty or same as name
     * 
     * @param out Outputsettings
     * @return  Returns whether collapsible or not
     */
	//NOTE(az): equalsIgnoreCase
    /*protected final*/ function shouldCollapseAttribute(out:Document.OutputSettings):Bool {
        return ("" == value || value.toLowerCase() == key)
                && out.getSyntax() == Document.Syntax.html
                && isBooleanAttribute();
    }

	static function stringComparator(a:String, b:String):Int {
        return a < b ? -1 : a > b ? 1 : 0;
    }
	
    /*protected*/ function isBooleanAttribute():Bool {
        return ArrayTools.bsearchComparator(booleanAttributes, key, 0, booleanAttributes.length-1, stringComparator) >= 0;
    }

    //@Override
	//NOTE(az): equals
    public function equals(o):Bool {
        if (this == o) return true;
		return false;
        /*if (!(o instanceof Attribute)) return false;

        Attribute attribute = (Attribute) o;

        if (key != null ? !key.equals(attribute.key) : attribute.key != null) return false;
        return !(value != null ? !value.equals(attribute.value) : attribute.value != null);
		*/
    }

    //@Override
	//NOTE(az): is this needed?
    /*public int hashCode() {
        int result = key != null ? key.hashCode() : 0;
        result = 31 * result + (value != null ? value.hashCode() : 0);
        return result;
    }*/

    //@Override
	//NOTE(az):
    public function clone():Attribute {
        return new Attribute(key, value);
		/*try {
            return (Attribute) super.clone(); // only fields are immutable strings key and value, so no more deep copy required
        } catch (CloneNotSupportedException e) {
            throw new RuntimeException(e);
        }*/
    }
}
