package org.jsoup.nodes;

/**
 * A boolean attribute that is written out without any value.
 */
class BooleanAttribute extends Attribute {
    /**
     * Create a new boolean attribute from unencoded (raw) key.
     * @param key attribute key
     */
    public function new(key:String) {
        super(key, "");
    }

    //@Override
    /*protected*/ override function isBooleanAttribute():Bool {
        return true;
    }
    
	override public function clone():BooleanAttribute {
        return new BooleanAttribute(key);
	}
}
