package org.jsoup.parser;

import org.jsoup.Exceptions;
import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Entities.Character;
import unifill.CodePoint;

using StringTools;
using unifill.Unifill;

/**
 * A character queue with parsing helpers.
 *
 * @author Jonathan Hedley
 */
//NOTE(az): should or not use unifill here
class TokenQueue {
    private var queue:String;
    private var pos:Int = 0;
    
    private static inline var ESC = '\\'.code; // escape char for chomp balanced.

    /**
     Create a new TokenQueue.
     @param data string of data to back queue.
     */
    public function new(data:String) {
        Validate.notNull(data);
        queue = data;
    }

    /**
     * Is the queue empty?
     * @return true if no data left in queue.
     */
    public function isEmpty():Bool {
        return remainingLength() == 0;
    }
    
    private function remainingLength():Int {
        return queue.length - pos;
    }

    /**
     * Retrieves but does not remove the first character from the queue.
     * @return First character, or 0 if empty.
     */
    public function peek():Int {
        return isEmpty() ? 0 : queue.uCharCodeAt(pos);
    }

    /**
     Add a character to the start of the queue (will be the next character retrieved).
     @param c character to add
     */
    public function addFirst(c:CodePoint):Void {
        addFirstSeq(c.toString());
    }

    /**
     Add a string to the start of the queue.
     @param seq string to add.
     */
    public function addFirstSeq(seq:String):Void {
        // not very performant, but an edge case
        queue = seq + queue.substring(pos);
        pos = 0;
    }

    /**
     * Tests if the next characters on the queue match the sequence. Case insensitive.
     * @param seq String to check queue for.
     * @return true if the next characters match.
     */
	//NOTE(az): no regionMatches
    public function matches(seq:String):Bool {
        //return queue.regionMatches(true, pos, seq, 0, seq.length);
		var thisRegion = queue.substr(pos, seq.length).toLowerCase();
		var otherRegion = seq.toLowerCase();
        return thisRegion == otherRegion;
    }

    /**
     * Case sensitive match test.
     * @param seq string to case sensitively check for
     * @return true if matched, false if not
     */
	//NOTE(az): using substring
    public function matchesCS(seq:String):Bool {
        return queue.substring(pos).startsWith(seq);
    }
    

    /**
     Tests if the next characters match any of the sequences. Case insensitive.
     @param seq list of strings to case insensitively check for
     @return true of any matched, false if none did
     */
    public function matchesAny(seq:Array<String>):Bool {
        for (s in seq) {
            if (matches(s))
                return true;
        }
        return false;
    }

    public function matchesAnyCP(seq:Array<CodePoint>):Bool {
        if (isEmpty())
            return false;

        for (c in seq) {
            if (queue.uCharCodeAt(pos) == c)
                return true;
        }
        return false;
    }

    public function matchesStartTag():Bool {
        var isLetter = ~/[a-zA-Z]/;
		// micro opt for matching "<x"
        return (remainingLength() >= 2 && queue.uCharCodeAt(pos) == '<'.code && isLetter.match(queue.charAt(pos + 1)));
    }

    /**
     * Tests if the queue matches the sequence (as with match), and if they do, removes the matched string from the
     * queue.
     * @param seq String to search for, and if found, remove from queue.
     * @return true if found and removed, false if not found.
     */
    public function matchChomp(seq:String):Bool {
        if (matches(seq)) {
            pos += seq.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     Tests if queue starts with a whitespace character.
     @return if starts with whitespace
     */
    public function matchesWhitespace():Bool {
        return !isEmpty() && StringUtil.isWhitespace(queue.charCodeAt(pos));
    }

    /**
     Test if the queue matches a word character (letter or digit).
     @return if matches a word character
     */
    public function matchesWord():Bool {
		var letterOrDigit = ~/[a-zA-Z0-9]/;
        return !isEmpty() && letterOrDigit.match(queue.charAt(pos));
    }

    /**
     * Drops the next character off the queue.
     */
    public function advance():Void {
        if (!isEmpty()) pos++;
    }

    /**
     * Consume one character off queue.
     * @return first character on queue.
     */
    public function consume():Int {
        return queue.charCodeAt(pos++);
    }

    /**
     * Consumes the supplied sequence of the queue. If the queue does not start with the supplied sequence, will
     * throw an illegal state exception -- but you should be running match() against that condition.
     <p>
     Case insensitive.
     * @param seq sequence to remove from head of queue.
     */
    public function consumeSeq(seq:String):Void {
        if (!matches(seq))
            throw new IllegalStateException("Queue did not match expected sequence");
        var len:Int = seq.length;
        if (len > remainingLength())
            throw new IllegalStateException("Queue not long enough to consume sequence");
        
        pos += len;
    }

    /**
     * Pulls a string off the queue, up to but exclusive of the match sequence, or to the queue running out.
     * @param seq String to end on (and not include in return, but leave on queue). <b>Case sensitive.</b>
     * @return The matched data consumed from queue.
     */
    public function consumeTo(seq:String):String {
        var offset = queue.indexOf(seq, pos);
        if (offset != -1) {
            var consumed = queue.substring(pos, offset);
            pos += consumed.length;
            return consumed;
        } else {
            return remainder();
        }
    }
    
    public function consumeToIgnoreCase(seq:String):String {
        var start:Int = pos;
        var first:String = seq.substring(0, 1);
        var canScan:Bool = first.toLowerCase() == (first.toUpperCase()); // if first is not cased, use index of
        while (!isEmpty()) {
            if (matches(seq))
                break;
            
            if (canScan) {
                var skip:Int = queue.indexOf(first, pos) - pos;
                if (skip == 0) // this char is the skip char, but not match, so force advance of pos
                    pos++;
                else if (skip < 0) // no chance of finding, grab to end
                    pos = queue.length;
                else
                    pos += skip;
            }
            else
                pos++;
        }

        return queue.substring(start, pos);
    }

    /**
     Consumes to the first sequence provided, or to the end of the queue. Leaves the terminator on the queue.
     @param seq any number of terminators to consume to. <b>Case insensitive.</b>
     @return consumed string   
     */
    // todo: method name. not good that consumeTo cares for case, and consume to any doesn't. And the only use for this
    // is is a case sensitive time...
    public function consumeToAny(seq:Array<String>):String {
        var start:Int = pos;
        while (!isEmpty() && !matchesAny(seq)) {
            pos++;
        }

        return queue.substring(start, pos);
    }

    /**
     * Pulls a string off the queue (like consumeTo), and then pulls off the matched string (but does not return it).
     * <p>
     * If the queue runs out of characters before finding the seq, will return as much as it can (and queue will go
     * isEmpty() == true).
     * @param seq String to match up to, and not include in return, and to pull off queue. <b>Case sensitive.</b>
     * @return Data matched from queue.
     */
    public function chompTo(seq:String):String {
        var data:String = consumeTo(seq);
        matchChomp(seq);
        return data;
    }
    
    public function chompToIgnoreCase(seq:String):String {
        var data:String = consumeToIgnoreCase(seq); // case insensitive scan
        matchChomp(seq);
        return data;
    }

    /**
     * Pulls a balanced string off the queue. E.g. if queue is "(one (two) three) four", (,) will return "one (two) three",
     * and leave " four" on the queue. Unbalanced openers and closers can be escaped (with \). Those escapes will be left
     * in the returned string, which is suitable for regexes (where we need to preserve the escape), but unsuitable for
     * contains text strings; use unescape for that.
     * @param open opener
     * @param close closer
     * @return data matched from the queue
     */
    public function chompBalanced(open:CodePoint, close:CodePoint):String {
        var start = -1;
        var end = -1;
        var depth = 0;
        var last:CodePoint = 0;

        do {
            if (isEmpty()) break;
            var c:CodePoint = consume();
            if (last == 0 || last != ESC) {
                if (c == (open)) {
                    depth++;
                    if (start == -1)
                        start = pos;
                }
                else if (c == (close))
                    depth--;
            }

            if (depth > 0 && last != 0)
                end = pos; // don't include the outer match pair in the return
            last = c;
        } while (depth > 0);
        return (end >= 0) ? queue.substring(start, end) : "";
    }
    
    /**
     * Unescaped a \ escaped string.
     * @param in backslash escaped string
     * @return unescaped string
     */
    public static function unescape(input:String):String {
        var out = new StringBuf();
        var last:CodePoint = 0;
        for (c in input.uIterator()) {
            if (c == ESC) {
                if (last != 0 && last == ESC)
                    out.add(c);
            }
            else 
                out.add(c);
            last = c;
        }
        return out.toString();
    }

    /**
     * Pulls the next run of whitespace characters of the queue.
     * @return Whether consuming whitespace or not
     */
    public function consumeWhitespace():Bool {
        var seen = false;
        while (matchesWhitespace()) {
            pos++;
            seen = true;
        }
        return seen;
    }

    /**
     * Retrieves the next run of word type (letter or digit) off the queue.
     * @return String of word characters from queue, or empty string if none.
     */
    public function consumeWord():String {
        var start:Int = pos;
        while (matchesWord())
            pos++;
        return queue.substring(start, pos);
    }
    
    /**
     * Consume an tag name off the queue (word or :, _, -)
     * 
     * @return tag name
     */
    public function consumeTagName():String {
        var start:Int = pos;
        while (!isEmpty() && (matchesWord() || matchesAny([':', '_', '-'])))
            pos++;
        
        return queue.substring(start, pos);
    }
    
    /**
     * Consume a CSS element selector (tag name, but | instead of : for namespaces, to not conflict with :pseudo selects).
     * 
     * @return tag name
     */
    public function consumeElementSelector():String {
        var start:Int = pos;
        while (!isEmpty() && (matchesWord() || matchesAny(['|', '_', '-'])))
            pos++;
        
        return queue.substring(start, pos);
    }

    /**
     Consume a CSS identifier (ID or class) off the queue (letter, digit, -, _)
     http://www.w3.org/TR/CSS2/syndata.html#value-def-identifier
     @return identifier
     */
	 public function consumeCssIdentifier():String {
        var start:Int = pos;
        while (!isEmpty() && (matchesWord() || matchesAny(['-', '_'])))
            pos++;

        return queue.substring(start, pos);
    }

    /**
     Consume an attribute key off the queue (letter, digit, -, _, :")
     @return attribute key
     */
    public function consumeAttributeKey():String {
        var start:Int = pos;
        while (!isEmpty() && (matchesWord() || matchesAny(['-', '_', ':'])))
            pos++;
        
        return queue.substring(start, pos);
    }

    /**
     Consume and return whatever is left on the queue.
     @return remained of queue.
     */
    public function remainder():String {
        var remainder:String = queue.substring(pos, queue.length);
        pos = queue.length;
        return remainder;
    }
    
    //@Override
    public function toString():String {
        return queue.substring(pos);
    }
}
