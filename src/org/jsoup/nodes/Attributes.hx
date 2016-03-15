package org.jsoup.nodes;

import de.polygonal.ds.List;
import de.polygonal.ds.ArrayList;
import de.polygonal.ds.Cloneable;
import org.jsoup.Exceptions.IllegalArgumentException;
import org.jsoup.helper.Validate;

//import java.util.*;

/**
 * The attributes of an Element.
 * <p>
 * Attributes are treated as a map: there can be only one value associated with an attribute key.
 * </p>
 * <p>
 * Attribute key and value comparisons are done case insensitively, and keys are normalised to
 * lower-case.
 * </p>
 * 
 * @author Jonathan Hedley, jonathan@hedley.net
 */
//NOTE(az): check Dataset impl.
@:allow(org.jsoup.nodes.Dataset)
class Attributes /*implements Iterable<Attribute>*/ implements Cloneable<Attributes> {
    private static var EMPTY_LIST:List<Attribute> = new ArrayList<Attribute>();
    
    /*protected final*/ public static inline var dataPrefix:String = "data-";
    
    private var attributes:Map<String, Attribute> = null;
    // linked hash map to preserve insertion order.
    // null be default as so many elements have no attributes -- saves a good chunk of memory

	public function new() {}
	
    /**
     Get an attribute value by key.
     @param key the attribute key
     @return the attribute value if set; or empty string if not set.
     @see #hasKey(String)
     */
    public function get(key:String):String {
        Validate.notEmpty(key);

        if (attributes == null)
            return "";

        var attr:Attribute = attributes.get(key.toLowerCase());
        return attr != null ? attr.getValue() : "";
    }

    /**
     Set a new attribute, or replace an existing one by key.
     @param key attribute key
     @param value attribute value
     */
	//NOTE(az): conflated with method below 
    public function put(key:String, value:Dynamic) {
        if (Std.is(value, String)) {
			var attr = new Attribute(key, value);
			putAttr(attr);
		} else if (Std.is(value, Bool)) {
			if (value)
				putAttr(new BooleanAttribute(key));
			else
				remove(key);
		} else throw new IllegalArgumentException("Invalid value. Can only be String or Bool");
    }
    
    /**
    Set a new boolean attribute, remove attribute if value is false.
    @param key attribute key
    @param value attribute value
    */
    /*public void put(String key, boolean value) {
        if (value)
            put(new BooleanAttribute(key));
        else
            remove(key);
    }*/

    /**
     Set a new attribute, or replace an existing one by key.
     @param attribute attribute
     */
	//NOTE(az): renamed to putAttr
    public function putAttr(attribute:Attribute) {
        Validate.notNull(attribute);
        if (attributes == null)
            attributes = new Map<String, Attribute>(/*2*/);
        attributes.set(attribute.getKey(), attribute);
    }

    /**
     Remove an attribute by key.
     @param key attribute key to remove
     */
    public function remove(key:String) {
        Validate.notEmpty(key);
        if (attributes == null)
            return;
        attributes.remove(key.toLowerCase());
    }

    /**
     Tests if these attributes contain an attribute with this key.
     @param key key to check for
     @return true if key exists, false otherwise
     */
    public function hasKey(key:String):Bool {
        return attributes != null && attributes.exists(key.toLowerCase());
    }

    /**
     Get the number of attributes in this set.
     @return size
     */
    //NOTE(az): siz3
	public function size():Int {
        if (attributes == null)
            return 0;
        return [for (k in attributes.keys()) k].length;
    }

    /**
     Add all the attributes from the incoming set to this set.
     @param incoming attributes to add to these attributes.
     */
    public function addAll(incoming:Attributes) {
        if (incoming.size() == 0)
            return;
        if (attributes == null)
            attributes = new Map<String, Attribute>(/*incoming.size()*/);
        for (key in incoming.attributes.keys())
			attributes.set(key, incoming.attributes.get(key));
    }
    
    public function iterator():Iterator<Attribute> {
        return asList().iterator();
    }

    /**
     Get the attributes as a List, for iteration. Do not modify the keys of the attributes via this view, as changes
     to keys will not be recognised in the containing set.
     @return an view of the attributes as a List.
     */
	//NOTE(az): unmodifiable 
    public function asList():List<Attribute> {
        if (attributes == null)
			return EMPTY_LIST;

        var list:List<Attribute> = new ArrayList<Attribute>(/*attributes.size()*/);
		for (value in attributes) {
            list.add(value);
        }
        //return Collections.unmodifiableList(list);
        return list;
    }

    /**
     * Retrieves a filtered view of attributes that are HTML5 custom data attributes; that is, attributes with keys
     * starting with {@code data-}.
     * @return map of custom data attributes.
     */
    public function dataset():Dataset/*Map<String, String>*/ {
        return new Dataset(this);
    }

    /**
     Get the HTML representation of these attributes.
     @return HTML
     */
    public function html():String {
        var accum = new StringBuf();
        _html(accum, (new Document("")).getOutputSettings()); // output settings a bit funky, but this html() seldom used
        return accum.toString();
    }
    
    public function _html(accum:StringBuf, out:Document.OutputSettings):Void {
        if (attributes == null)
            return;
        
        for (attribute in attributes) {
            accum.add(" ");
            attribute._html(accum, out);
        }
    }
    
    public function toString():String {
        return html();
    }

    /**
     * Checks if these attributes are equal to another set of attributes, by comparing the two sets
     * @param o attributes to compare with
     * @return if both sets of attributes have the same content
     */
    //NOTE(az): equals
	public function equals(o):Bool {
        if (this == o) return true;
        return false;
		/*if (!(o instanceof Attributes)) return false;
        
        Attributes that = (Attributes) o;
        
        return !(attributes != null ? !attributes.equals(that.attributes) : that.attributes != null);*/
    }

    /**
     * Calculates the hashcode of these attributes, by iterating all attributes and summing their hashcodes.
     * @return calculated hashcode
     */
    //@Override
	var key:Int;
	
	//NOTE(az): is this needed?
    public function hashCode():Int {
        return key = (attributes != null ? 1 : 0);
    }

    //@Override
    public function clone():Attributes {
        if (attributes == null)
            return new Attributes();

        var clone = new Attributes();
        
        clone.attributes = new Map<String, Attribute>(/*attributes.size()*/);
        for (key in attributes.keys())
            clone.attributes.set(key, attributes.get(key).clone());
        return clone;
    }


    private static function dataKey(key:String):String {
        return dataPrefix + key;
    }
}

//NOTE(az): owner to link with parent. This seems to just forward operation with attributes prefixed with "data-".
@:allow(org.jsoup.nodes.Attributes)
class Dataset /*extends AbstractMap<String, String>*/ {

	var owner:Attributes;
	
	private function new(owner:Attributes) {
		this.owner = owner;
		
		if (owner.attributes == null)
			owner.attributes = new Map<String, Attribute>(/*2*/);
	}

	/*@Override
	//NOTE(az): is this needed?
	public Set<Entry<String, String>> entrySet() {
		return new EntrySet();
	}*/

	//@Override
	//NOTE(az): check
	public function put(key:String, value:String):String {
		var dataKey:String = Attributes.dataPrefix + key;
		var oldValue:String = owner.hasKey(dataKey) ? owner.attributes.get(dataKey).getValue() : null;
		var attr = new Attribute(dataKey, value);
		owner.attributes.set(dataKey, attr);
		return oldValue;
	}

	//NOTE(az): need to get back here at some point!
	/*private class EntrySet extends AbstractSet<Map.Entry<String, String>> {

		@Override
		public Iterator<Map.Entry<String, String>> iterator() {
			return new DatasetIterator();
		}

	   @Override
		public int size() {
			int count = 0;
			Iterator iter = new DatasetIterator();
			while (iter.hasNext())
				count++;
			return count;
		}
	}

	private class DatasetIterator implements Iterator<Map.Entry<String, String>> {
		private Iterator<Attribute> attrIter = attributes.values().iterator();
		private Attribute attr;
		public boolean hasNext() {
			while (attrIter.hasNext()) {
				attr = attrIter.next();
				if (attr.isDataAttribute()) return true;
			}
			return false;
		}

		public Entry<String, String> next() {
			return new Attribute(attr.getKey().substring(dataPrefix.length()), attr.getValue());
		}

		public void remove() {
			attributes.remove(attr.getKey());
		}
	}*/
}
