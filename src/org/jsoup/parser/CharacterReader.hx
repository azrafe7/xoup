package org.jsoup.parser;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.ArrayTools;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Entities.Character;
import org.jsoup.parser.tokens.TokeniserState;
import unifill.CodePoint;

using unifill.Unifill;

/*import java.util.Arrays;
import java.util.Locale;
*/

/**
 CharacterReader consumes tokens off a string. To replace the old TokenQueue.
 */
@:allow(org.jsoup.parser)
/*final*/ class CharacterReader {
    public static inline var EOF:Int = -1;
    public static inline var nullchar:Int = 0;
	
    private static inline var maxCacheLen:Int = 12;

	//NOTE(az): this was final char[] input
    private var input:String;
    private var inputCP:Array<CodePoint>;
    private var length:Int;
    private var pos:Int = 0;
    private var _mark:Int = 0;
    private var stringCache:Array<String> = [for (i in 0...512) null]; // holds reused strings in this doc, to lessen garbage

    function new(input:String) {
        Validate.notNull(input);
		this.input = input;
		this.inputCP = [for (u in input.uSplit("")) u.uCodePointAt(0)];
        this.length = this.inputCP.length;
    }

    public function getPos():Int {
        return pos;
    }

    function isEmpty():Bool {
        return pos >= length;
    }

    function current():Int {
        return pos >= length ? EOF : inputCP[pos];
    }

    function consume():Int {
        var val:CodePoint = pos >= length ? EOF : inputCP[pos];
        pos++;
        return val;
    }

    function unconsume():Void {
        pos--;
    }

    function advance():Void {
        pos++;
    }

    function mark():Void {
        _mark = pos;
    }

    function rewindToMark():Void {
        pos = _mark;
    }

	//NOTE(az): mmmhh
    function consumeAsString():String {
        return inputCP[pos++].toString();
    }

    /**
     * Returns the number of characters between the current position and the next instance of the input char
     * @param c scan target
     * @return offset between current position and next instance of target. -1 if not found.
     */
    function nextIndexOf(c:Int):Int {
        // doesn't handle scanning for surrogates
        for (i in pos...length) {
            if (c == inputCP[i])
                return i - pos;
        }
        return -1;
    }

    /**
     * Returns the number of characters between the current position and the next instance of the input sequence
     *
     * @param seq scan target
     * @return offset between current position and next instance of target. -1 if not found.
     */
	//NOTE(az): renamed, and using String
    function nextIndexOfSeq(seq:String):Int {
        // doesn't handle scanning for surrogates
        return input.uIndexOf(seq, pos);
		
		/*char startChar = seq.charAt(0);
        for (int offset = pos; offset < length; offset++) {
            // scan to first instance of startchar:
            if (startChar != input[offset])
                while(++offset < length && startChar != input[offset]) { }
            int i = offset + 1;
            int last = i + seq.length()-1;
            if (offset < length && last <= length) {
                for (int j = 1; i < last && seq.charAt(j) == input[i]; i++, j++) { }
                if (i == last) // found full sequence
                    return offset - pos;
            }
        }
        return -1;*/
    }

    function consumeTo(c:Int):String {
        var offset:Int = nextIndexOf(c);
        if (offset != -1) {
            var consumed:String = cacheString(pos, offset);
            pos += offset;
            return consumed;
        } else {
            return consumeToEnd();
        }
    }

	//NOTE(az): renamed
    function consumeToSeq(seq:String):String {
        var offset:Int = nextIndexOfSeq(seq);
        if (offset != -1) {
            var consumed:String = cacheString(pos, offset);
            pos += offset;
            return consumed;
        } else {
            return consumeToEnd();
        }
    }

	//NOTE(az): check, goto, ugly
    function consumeToAny(chars:Array<CodePoint>):String {
        var start:Int = pos;
        var remaining:Int = length;

		while (true) {
			//OUTER: 
			while (pos < remaining) {
				var gotoOuter = false;
				for (c in chars) {
					if (inputCP[pos] == c) {
						gotoOuter = true;
						break;
					}
				}
				if (gotoOuter) break;
				pos++;
			}
			break;
		}

        return pos > start ? cacheString(start, pos-start) : "";
    }

    function consumeToAnySorted(chars:Array<CodePoint>):String {
        var start = pos;
        var remaining = length;
        var val:Array<CodePoint> = inputCP;

        while (pos < remaining) {
            if (ArrayTools.bsearchInt(cast chars, val[pos], 0, chars.length - 1) >= 0)
                break;
            pos++;
        }

        return pos > start ? cacheString(start, pos-start) : "";
    }

    function consumeData():String {
        // &, <, null
        var start = pos;
        var remaining = length;
        var val:Array<CodePoint> = inputCP;

        while (pos < remaining) {
            var c = val[pos];
            if (c == '&'.code || c == '<'.code || c == TokeniserState.nullChar)
                break;
            pos++;
        }

        return pos > start ? cacheString(start, pos-start) : "";
    }

	//NOTE(az): check \f among other things
    function consumeTagName():String {
        // '\t', '\n', '\r', '\f', ' ', '/', '>', nullChar
        var start = pos;
        var remaining = length;
        var val:Array<CodePoint> = inputCP;

        while (pos < remaining) {
            var c:CodePoint = val[pos];
            if (c == '\t'.code || c == '\n'.code || c == '\r'.code || c == 0xC/*'\f'.code*/ || c == ' '.code || c == '/'.code || c == '>'.code || c == TokeniserState.nullChar)
                break;
            pos++;
        }

        return pos > start ? cacheString(start, pos-start) : "";
    }

    function consumeToEnd():String {
        var data = cacheString(pos, length-pos);
        pos = length;
        return data;
    }

    function consumeLetterSequence():String {
        var start = pos;
        while (pos < length) {
            var c:CodePoint = inputCP[pos];
            if ((c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code))
                pos++;
            else
                break;
        }

        return cacheString(start, pos - start);
    }

    function consumeLetterThenDigitSequence():String {
        var start = pos;
        while (pos < length) {
            var c = inputCP[pos];
            if ((c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code))
                pos++;
            else
                break;
        }
        while (!isEmpty()) {
            var c:CodePoint = inputCP[pos];
            if (c >= '0'.code && c <= '9'.code)
                pos++;
            else
                break;
        }

        return cacheString(start, pos - start);
    }

    function consumeHexSequence():String {
        var start = pos;
        while (pos < length) {
            var c:CodePoint = inputCP[pos];
            if ((c >= '0'.code && c <= '9'.code) || (c >= 'A'.code && c <= 'F'.code) || (c >= 'a'.code && c <= 'f'.code))
                pos++;
            else
                break;
        }
        return cacheString(start, pos - start);
    }

    function consumeDigitSequence():String {
        var start = pos;
        while (pos < length) {
            var c:CodePoint = inputCP[pos];
            if (c >= '0'.code && c <= '9'.code)
                pos++;
            else
                break;
        }
        return cacheString(start, pos - start);
    }

    function matches(c:CodePoint):Bool {
        return !isEmpty() && inputCP[pos] == c;

    }

    function matchesSeq(seq:String):Bool {
        var scanLength = seq.uLength();
        if (scanLength > length - pos)
            return false;

        for (offset in 0...scanLength)
            if (seq.uCharCodeAt(offset) != inputCP[pos+offset])
                return false;
        return true;
    }

	//NOTE(az): uppercase?
    function matchesIgnoreCase(seq:String):Bool {
        var scanLength = seq.uLength();
        if (scanLength > length - pos)
            return false;

        for (offset in 0...scanLength) {
            var upScan:String = seq.uCodePointAt(offset).toString().toUpperCase();
            var upTarget:String = inputCP[pos + offset].toString().toUpperCase();
            if (upScan != upTarget)
                return false;
        }
        return true;
    }

    function matchesAny(seq:Array<CodePoint>):Bool {
        if (isEmpty())
            return false;

        var c:CodePoint = inputCP[pos];
        for (seek in seq) {
            if (seek == c)
                return true;
        }
        return false;
    }

    function matchesAnySorted(seq:Array<CodePoint>):Bool {
        return !isEmpty() && ArrayTools.bsearchInt(cast seq, inputCP[pos], 0, seq.length - 1) >= 0;
    }

    function matchesLetter():Bool {
        if (isEmpty())
            return false;
        var c:CodePoint = inputCP[pos];
        return (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code);
    }

    function matchesDigit():Bool {
        if (isEmpty())
            return false;
        var c:CodePoint = inputCP[pos];
        return (c >= '0'.code && c <= '9'.code);
    }

    function matchConsume(seq:String):Bool {
        if (matchesSeq(seq)) {
            pos += seq.uLength();
            return true;
        } else {
            return false;
        }
    }

    function matchConsumeIgnoreCase(seq:String):Bool {
        if (matchesIgnoreCase(seq)) {
            pos += seq.uLength();
            return true;
        } else {
            return false;
        }
    }

    function containsIgnoreCase(seq:String):Bool {
        // used to check presence of </title>, </style>. only finds consistent case.
        var loScan:String = seq.toLowerCase();
        var hiScan:String = seq.toUpperCase();
        return (nextIndexOfSeq(loScan) > -1) || (nextIndexOfSeq(hiScan) > -1);
    }

    //@Override
    public function toString():String {
        return input.uSubstr(pos, length - pos);
    }

    /**
     * Caches short strings, as a flywheel pattern, to reduce GC load. Just for this doc, to prevent leaks.
     * <p />
     * Simplistic, and on hash collisions just falls back to creating a new string, vs a full HashMap with Entry list.
     * That saves both having to create objects as hash keys, and running through the entry list, at the expense of
     * some more duplicates.
     */
    private function cacheString(start:Int, count:Int):String {
        var val = input;
        var cache = stringCache;

        // limit (no cache):
        if (count > maxCacheLen)
            return val.uSubstr(start, count);

        // calculate hash:
        var hash:Int = 0;
        var offset = start;
        for (i in 0...count) {
            hash = 31 * hash + val.uCharCodeAt(offset++);
        }

        // get from cache
        var index:Int = (hash & cache.length) - 1;
        var cached = cache[index];

        if (cached == null) { // miss, add
            cached = val.uSubstr(start, count);
            cache[index] = cached;
        } else { // hashcode hit, check equality
            if (rangeEquals(start, count, cached)) {
                // hit
                return cached;
            } else { // hashcode conflict
                cached = val.uSubstr(start, count);
            }
        }
        return cached;
    }

    /**
     * Check if the value of the provided range equals the string.
     */
    function rangeEquals(start:Int, count:Int, cached:String):Bool {
        if (count == cached.length) {
            var one:String = input;
            var i:Int = start;
            var j:Int = 0;
            while (count-- != 0) {
                if (one.uCharCodeAt(i++) != cached.uCharCodeAt(j++))
                    return false;
            }
            return true;
        }
        return false;
    }
}
