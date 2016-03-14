package org.jsoup.parser;

import de.polygonal.ds.List;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.*;
import org.jsoup.nodes.Document.Syntax;
import org.jsoup.parser.tokens.Token;
import org.jsoup.parser.tokens.Token.TokenType;

using StringTools;

//import java.util.List;

/**
 * Use the {@code XmlTreeBuilder} when you want to parse XML without any of the HTML DOM rules being applied to the
 * document.
 * <p>Usage example: {@code Document xmlDoc = Jsoup.parse(html, baseUrl, Parser.xmlParser());}</p>
 *
 * @author Jonathan Hedley
 */
@:allow(org.jsoup.parser.Parser)
class XmlTreeBuilder extends TreeBuilder {
    //@Override
    override /*protected*/ function initialiseParse(input:String, baseUri:String, errors:ParseErrorList):Void {
        super.initialiseParse(input, baseUri, errors);
        stack.add(doc); // place the document onto the stack. differs from HtmlTreeBuilder (not on stack)
        doc.getOutputSettings().setSyntax(Syntax.xml);
    }

    //@Override
    override /*protected*/ function process(token:Token, state:HtmlTreeBuilderState = null):Bool {
        // start tag, end tag, doctype, comment, character, eof
        switch (token.type) {
            case TokenType.StartTag:
                insertStartTag(token.asStartTag());
            case TokenType.EndTag:
                popStackToClose(token.asEndTag());
            case TokenType.Comment:
                insertComment(token.asComment());
            case TokenType.Character:
                insertCharacter(token.asCharacter());
            case TokenType.Doctype:
                insertDoctype(token.asDoctype());
            case TokenType.EOF: // could put some normalisation here if desired
            default:
                Validate.fail("Unexpected token type: " + token.type);
        }
        return true;
    }

    private function insertNode(node:Node):Void {
        currentElement().appendChild(node);
    }

	//NOTE(az): renamed
    function insertStartTag(startTag:TokenStartTag):Element {
        var tag:Tag = Tag.valueOf(startTag.getName());
        // todo: wonder if for xml parsing, should treat all tags as unknown? because it's not html.
        var el:Element = new Element(tag, baseUri, startTag.attributes);
        insertNode(el);
        if (startTag.isSelfClosing()) {
            tokeniser.acknowledgeSelfClosingFlag();
            if (!tag.isKnown()) // unknown tag, remember this is self closing for output. see above.
                tag.setSelfClosing();
        } else {
            stack.add(el);
        }
        return el;
    }

    function insertComment(commentToken:TokenComment):Void {
        var comment = new Comment(commentToken.getData(), baseUri);
        var insert:Node = comment;
        if (commentToken.bogus) { // xml declarations are emitted as bogus comments (which is right for html, but not xml)
            var data:String = comment.getData();
            if (data.length > 1 && (data.startsWith("!") || data.startsWith("?"))) {
                var declaration:String = data.substring(1);
                insert = new XmlDeclaration(declaration, comment.getBaseUri(), data.startsWith("!"));
            }
        }
        insertNode(insert);
    }

    function insertCharacter(characterToken:TokenCharacter):Void {
        var node:Node = new TextNode(characterToken.getData(), baseUri);
        insertNode(node);
    }

    function insertDoctype(d:TokenDoctype):Void {
        var doctypeNode:DocumentType = new DocumentType(d.getName(), d.getPublicIdentifier(), d.getSystemIdentifier(), baseUri);
        insertNode(doctypeNode);
    }

    /**
     * If the stack contains an element with this tag's name, pop up the stack to remove the first occurrence. If not
     * found, skips.
     *
     * @param endTag
     */
    private function popStackToClose(endTag:TokenEndTag):Void {
        var elName:String = endTag.getName();
        var firstFound:Element = null;

		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            if (next.nodeName() == (elName)) {
                firstFound = next;
                break;
            }
			pos--;
        }
        if (firstFound == null)
            return; // not found, skip

		pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            stack.removeAt(pos);
            if (next == firstFound)
                break;
			pos--;
        }
    }

    function parseFragment(inputFragment:String, baseUri:String, errors:ParseErrorList):List<Node> {
        initialiseParse(inputFragment, baseUri, errors);
        runParser();
        return doc.getChildNodes();
    }
}
