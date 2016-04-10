package org.jsoup.parser;

import de.polygonal.ds.ArrayList;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Attributes;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.parser.Token;
import org.jsoup.parser.Tokeniser;

//import java.util.ArrayList;

/**
 * @author Jonathan Hedley
 */
@:allow(org.jsoup.parser)
/*abstract*/ class TreeBuilder {
    var reader:CharacterReader;
    var tokeniser:Tokeniser;
    /*protected*/ var doc:Document; // current doc we are building into
    /*protected*/ var stack:ArrayList<Element>; // the stack of open elements
    /*protected*/ var baseUri:String; // current base uri, for creating new elements
    /*protected*/ var currentToken:Token; // currentToken is used only for error tracking.
    /*protected*/ var errors:ParseErrorList; // null when not tracking errors

    private var start:TokenStartTag = new TokenStartTag(); // start tag to process
    private var end:TokenEndTag  = new TokenEndTag();

    function new() { }
	
	/*protected*/ function initialiseParse(input:String, baseUri:String, errors:ParseErrorList ):Void {
        Validate.notNull(input, "String input must not be null");
        Validate.notNull(baseUri, "BaseURI must not be null");

        doc = new Document(baseUri);
        reader = new CharacterReader(input);
        this.errors = errors;
        tokeniser = new Tokeniser(reader, errors);
        stack = new ArrayList<Element>(32);
        this.baseUri = baseUri;
    }

	//NOTE(az): use mehod below
    /*function parse(input:String, baseUri:String):Document {
        return parse(input, baseUri, ParseErrorList.noTracking());
    }*/

    function parse(input:String, baseUri:String, errors:ParseErrorList = null):Document {
        initialiseParse(input, baseUri, errors == null ? ParseErrorList.noTracking() : errors);
        runParser();
        return doc;
    }

    /*protected*/ function runParser():Void {
        while (true) {
            var token:Token = tokeniser.read();
            process(token);
            token.reset();

            if (token.type == TokenType.EOF)
                break;
        }
    }

    /*protected abstract*/ function process(token:Token, state:HtmlTreeBuilderState = null):Bool { throw "Abstract"; return false; };

    /*protected*/ function processStartTag(name:String):Bool {
        if (currentToken == start) { // don't recycle an in-use token
            return process(new TokenStartTag().setName(name));
        }
        return process(start.reset().setName(name));
    }

	//NOTE(az): renamed
    public function processStartTagWithAttrs(name:String, attrs:Attributes):Bool {
        if (currentToken == start) { // don't recycle an in-use token
            return process(new TokenStartTag().nameAttr(name, attrs));
        }
        start.reset();
        start.nameAttr(name, attrs);
        return process(start);
    }

    /*protected*/ function processEndTag(name:String):Bool {
        if (currentToken == end) { // don't recycle an in-use token
            return process(new TokenEndTag().setName(name));
        }
        return process(end.reset().setName(name));
    }


    /*protected*/ function currentElement():Element {
        var size = stack.size;
        return size > 0 ? stack.get(size-1) : null;
    }
}
