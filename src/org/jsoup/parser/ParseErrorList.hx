package org.jsoup.parser;

import de.polygonal.ds.ArrayList;

//import java.util.ArrayList;

/**
 * A container for ParseErrors.
 * 
 * @author Jonathan Hedley
 */
@:allow(org.jsoup.parser)
class ParseErrorList extends ArrayList<ParseError>{
    private static inline var INITIAL_CAPACITY:Int = 16;
    private var maxSize:Int;
    
    public function new(initialCapacity:Int, maxSize:Int) {
        super(initialCapacity);
        this.maxSize = maxSize;
    }
    
    function canAddError():Bool {
        return size < maxSize;
    }

    function getMaxSize():Int {
        return maxSize;
    }

    static function noTracking():ParseErrorList {
        return new ParseErrorList(0, 0);
    }
    
    static function tracking(maxSize:Int):ParseErrorList {
        return new ParseErrorList(INITIAL_CAPACITY, maxSize);
    }
}
