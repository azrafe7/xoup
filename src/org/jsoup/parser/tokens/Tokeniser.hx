package org.jsoup.parser.tokens;

import org.jsoup.helper.StringBuilder;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Entities;
import org.jsoup.parser.tokens.Token;
import unifill.CodePoint;
import unifill.Unifill;

using StringTools;

//import java.util.Arrays;

/**
 * Readers the input stream into tokens.
 */
@:allow(org.jsoup.parser)
class Tokeniser {
    static var replacementChar = CodePoint.fromInt(0xFFFD); // replaces null character
    
	//NOTE(az)
	private static var notCharRefCharsSorted:Array<CodePoint>;

    static function __init__() {
		notCharRefCharsSorted = ['\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code, '<'.code, '&'.code];
        notCharRefCharsSorted.sort(Reflect.compare);
    }

    private var reader:CharacterReader; // html input
    private var errors:ParseErrorList; // errors found while tokenising

    private var state:TokeniserState = TokeniserState.Data; // current tokenisation state
    private var emitPending:Token; // the token we are about to emit on next read
    private var isEmitPending:Bool = false;
    private var charsString:String = null; // characters pending an emit. Will fall to charsBuilder if more than one
    private var charsBuilder:StringBuilder = new StringBuilder(/*1024*/); // buffers characters to output as one token, if more than one emit per read
    var dataBuffer:StringBuilder = new StringBuilder(/*1024*/); // buffers data looking for </script>

    var tagPending:TokenTag; // tag we are building up
    var startPending:TokenStartTag = new TokenStartTag();
    var endPending:TokenEndTag = new TokenEndTag();
    var charPending:TokenCharacter = new TokenCharacter();
    var doctypePending:TokenDoctype = new TokenDoctype(); // doctype building up
    var commentPending:TokenComment = new TokenComment(); // comment building up
    private var lastStartTag:String; // the last start tag emitted, to test appropriate end tag
    private var selfClosingFlagAcknowledged:Bool = true;

    function new(reader:CharacterReader, errors:ParseErrorList) {
        this.reader = reader;
        this.errors = errors;
    }

    function read():Token {
        if (!selfClosingFlagAcknowledged) {
            error("Self closing flag not acknowledged");
            selfClosingFlagAcknowledged = true;
        }

        while (!isEmitPending) {
            state.read(this, reader);
		}
		
        // if emit is pending, a non-character token was found: return any chars in buffer, and leave token for next read:
        if (charsBuilder.length > 0) {
            var str = charsBuilder.toString();
            //NOTE(az): recreate it
			//charsBuilder.delete(0, charsBuilder.length());
			charsBuilder = new StringBuilder();
            charsString = null;
            return charPending.setData(str);
        } else if (charsString != null) {
            var token:Token = charPending.setData(charsString);
            charsString = null;
            return token;
        } else {
            isEmitPending = false;
            return emitPending;
        }
    }

    function emit(token:Token):Void {
        Validate.isFalse(isEmitPending, "There is an unread token pending!");

        emitPending = token;
        isEmitPending = true;

        if (token.type == TokenType.StartTag) {
            var startTag:TokenStartTag = cast token;
            lastStartTag = startTag.tagName;
            if (startTag.isSelfClosing())
                selfClosingFlagAcknowledged = false;
        } else if (token.type == TokenType.EndTag) {
            var endTag:TokenEndTag = cast token;
            if (endTag.attributes != null)
                error("Attributes incorrectly present on end tag");
        }
    }

	//NOTE(az): renamed to emitString and removed other overloads below
    function emitString(str:String):Void {
        // buffer strings up until last string token found, to emit only one token for a run of character refs etc.
        // does not set isEmitPending; read checks that
        if (charsString == null) {
            charsString = str;
        }
        else {
            if (charsBuilder.length == 0) { // switching to string builder as more than one emit before read
                charsBuilder.add(charsString);
            }
            charsBuilder.add(str);
        }
    }

	//NOTE(az): removed for now, see above ^^
    /*void emit(char[] chars) {
        emit(String.valueOf(chars));
    }*/

    function emitCodePoint(c:CodePoint):Void {
        emitString(c.toString());
    }

    function getState():TokeniserState {
        return state;
    }

    function transition(state:TokeniserState):Void {
        this.state = state;
    }

    function advanceTransition(state:TokeniserState):Void {
        reader.advance();
        this.state = state;
    }

    function acknowledgeSelfClosingFlag():Void {
        selfClosingFlagAcknowledged = true;
    }

	//NOTE(az): was char[]; , see method below
    private var charRefHolder:Array<CodePoint> = [0];// new char[1]; // holder to not have to keep creating arrays
    function consumeCharacterReference(additionalAllowedCharacter:Null<CodePoint>, inAttribute:Bool):Array<CodePoint> {
        if (reader.isEmpty())
            return null;
        if (additionalAllowedCharacter != null && additionalAllowedCharacter == reader.current())
            return null;
        if (reader.matchesAnySorted(notCharRefCharsSorted))
            return null;

        var charRef:Array<CodePoint> = charRefHolder;
        reader.mark();
        if (reader.matchConsume("#")) { // numbered
            var isHexMode:Bool = reader.matchConsumeIgnoreCase("X");
            var numRef:String = isHexMode ? reader.consumeHexSequence() : reader.consumeDigitSequence();
            if (numRef.length == 0) { // didn't match anything
                characterReferenceError("numeric reference with no numerals");
                reader.rewindToMark();
                return null;
            }
            if (!reader.matchConsume(";"))
                characterReferenceError("missing semicolon"); // missing semi
            //NOTE(az): check try/catch, subst for a null check (which is what Std.parse returns in case of error)
            var charval:Int = -1;
			var parsedVal:Null<Int> = null;
			//try {
                var base:Int = isHexMode ? 16 : 10;
				parsedVal = Std.parseInt(isHexMode ? "0x" + numRef : numRef);
				if (parsedVal != null) charval = parsedVal;
            //} catch (NumberFormatException e) { } // skip
            
			if (charval == -1 || (charval >= 0xD800 && charval <= 0xDFFF) || charval > 0x10FFFF) {
                characterReferenceError("character outside of valid range");
                charRef[0] = replacementChar;
                return charRef;
            } else {
                // todo: implement number replacement table
                // todo: check for extra illegal unicode points as parse errors
                if (charval < Entities.MIN_SUPPLEMENTARY_CODE_POINT) {
                    charRef[0] = /*(char)*/ charval;
                    return charRef;
                } else
                return [CodePoint.fromInt(charval)]; //NOTE(az): mmhhh... toChars()
            }
        } else { // named
            // get as many letters as possible, and look for matching entities.
            var nameRef:String = reader.consumeLetterThenDigitSequence();
            var looksLegit:Bool = reader.matches(';'.code);
            // found if a base named entity without a ;, or an extended entity with the ;.
            var found:Bool = (Entities.isBaseNamedEntity(nameRef) || (Entities.isNamedEntity(nameRef) && looksLegit));

            if (!found) {
                reader.rewindToMark();
                if (looksLegit) // named with semicolon
                    characterReferenceError("invalid named reference '" + nameRef + "'");
                return null;
            }
            if (inAttribute && (reader.matchesLetter() || reader.matchesDigit() || reader.matchesAny(['='.code, '-'.code, '_'.code]))) {
                // don't want that to match
                reader.rewindToMark();
                return null;
            }
            if (!reader.matchConsume(";"))
                characterReferenceError("missing semicolon"); // missing semi
            charRef[0] = Unifill.uCharCodeAt(Entities.getCharacterByName(nameRef), 0);
            return charRef;
        }
    }

    function createTagPending(start:Bool):TokenTag {
        tagPending = start ? startPending.reset() : endPending.reset();
        return tagPending;
    }

    function emitTagPending():Void {
        tagPending.finaliseTag();
        emit(tagPending);
    }

    function createCommentPending():Void {
        commentPending.reset();
    }

    function emitCommentPending():Void {
        emit(commentPending);
    }

    function createDoctypePending():Void {
        doctypePending.reset();
    }

    function emitDoctypePending():Void {
        emit(doctypePending);
    }

    function createTempBuffer():Void {
        Token.resetBuf(dataBuffer);
    }

    function isAppropriateEndTagToken():Bool {
        return lastStartTag != null && tagPending.tagName == lastStartTag;
    }

    function appropriateEndTagName():String {
        if (lastStartTag == null)
            return null;
        return lastStartTag;
    }

	//NOE(az): renamed
    function errorState(state:TokeniserState):Void {
        if (errors.canAddError())
            errors.add(new ParseError(reader.getPos(), 'Unexpected character "${reader.current()}" in input state [${state}]'));
    }

    function eofError(state:TokeniserState):Void {
        if (errors.canAddError())
            errors.add(new ParseError(reader.getPos(), 'Unexpectedly reached end of file (EOF) in input state [${state}]'));
    }

    private function characterReferenceError(message:String):Void {
        if (errors.canAddError())
            errors.add(new ParseError(reader.getPos(), 'Invalid character reference: ${message}'));
    }

    private function error(errorMsg:String):Void {
        if (errors.canAddError())
            errors.add(new ParseError(reader.getPos(), errorMsg));
    }

    function currentNodeInHtmlNS():Bool {
        // todo: implement namespaces correctly
        return true;
        // Element currentNode = currentNode();
        // return currentNode != null && currentNode.namespace().equals("HTML");
    }

    /**
     * Utility method to consume reader and unescape entities found within.
     * @param inAttribute
     * @return unescaped string from reader
     */
	//NOTE(az): using Array<CodePoint> here too, check adds
    function unescapeEntities(inAttribute:Bool):String {
        var builder = new StringBuilder();
        while (!reader.isEmpty()) {
            builder.add(reader.consumeTo('&'.code));
            if (reader.matches('&'.code)) {
                reader.consume();
                var c:Array<CodePoint> = consumeCharacterReference(null, inAttribute);
                if (c == null || c.length==0)
                    builder.add('&');
                else
                    for (u in c) builder.add(u.toString());
            }
        }
        return builder.toString();
    }
}
