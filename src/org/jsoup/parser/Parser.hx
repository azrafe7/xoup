package org.jsoup.parser;

import de.polygonal.ds.List;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.parser.tokens.Tokeniser;

//import java.util.List;

/**
 * Parses HTML into a {@link org.jsoup.nodes.Document}. Generally best to use one of the  more convenient parse methods
 * in {@link org.jsoup.Jsoup}.
 */
class Parser {
    private static inline var DEFAULT_MAX_ERRORS:Int = 0; // by default, error tracking is disabled.
    
    private var treeBuilder:TreeBuilder;
    private var maxErrors:Int = DEFAULT_MAX_ERRORS;
    private var errors:ParseErrorList;

    /**
     * Create a new Parser, using the specified TreeBuilder
     * @param treeBuilder TreeBuilder to use to parse input into Documents.
     */
    public function new(treeBuilder:TreeBuilder) {
        this.treeBuilder = treeBuilder;
    }
    
    public function parseInput(html:String, baseUri:String):Document {
        errors = isTrackErrors() ? ParseErrorList.tracking(maxErrors) : ParseErrorList.noTracking();
        return treeBuilder.parse(html, baseUri, errors);
    }

    // gets & sets
    /**
     * Get the TreeBuilder currently in use.
     * @return current TreeBuilder.
     */
    public function getTreeBuilder():TreeBuilder {
        return treeBuilder;
    }

    /**
     * Update the TreeBuilder used when parsing content.
     * @param treeBuilder current TreeBuilder
     * @return this, for chaining
     */
    public function setTreeBuilder(treeBuilder:TreeBuilder):Parser {
        this.treeBuilder = treeBuilder;
        return this;
    }

    /**
     * Check if parse error tracking is enabled.
     * @return current track error state.
     */
    public function isTrackErrors():Bool {
        return maxErrors > 0;
    }

    /**
     * Enable or disable parse error tracking for the next parse.
     * @param maxErrors the maximum number of errors to track. Set to 0 to disable.
     * @return this, for chaining
     */
    public function setTrackErrors(maxErrors:Int):Parser {
        this.maxErrors = maxErrors;
        return this;
    }

    /**
     * Retrieve the parse errors, if any, from the last parse.
     * @return list of parse errors, up to the size of the maximum errors tracked.
     */
    public function getErrors():List<ParseError> {
        return errors;
    }

    // static parse functions below
    /**
     * Parse HTML into a Document.
     *
     * @param html HTML to parse
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return parsed Document
     */
    public static function parse(html:String, baseUri:String):Document {
        var treeBuilder:TreeBuilder = new HtmlTreeBuilder();
        return treeBuilder.parse(html, baseUri, ParseErrorList.noTracking());
    }

    /**
     * Parse a fragment of HTML into a list of nodes. The context element, if supplied, supplies parsing context.
     *
     * @param fragmentHtml the fragment of HTML to parse
     * @param context (optional) the element that this HTML fragment is being parsed for (i.e. for inner HTML). This
     * provides stack context (for implicit element creation).
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return list of nodes parsed from the input HTML. Note that the context element, if supplied, is not modified.
     */
    public static function parseFragment(fragmentHtml:String, context:Element, baseUri:String):List<Node> {
        var treeBuilder:HtmlTreeBuilder = new HtmlTreeBuilder();
        return treeBuilder.parseFragment(fragmentHtml, context, baseUri, ParseErrorList.noTracking());
    }

    /**
     * Parse a fragment of XML into a list of nodes.
     *
     * @param fragmentXml the fragment of XML to parse
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     * @return list of nodes parsed from the input XML.
     */
    public static function parseXmlFragment(fragmentXml:String, baseUri:String):List<Node> {
        var treeBuilder:XmlTreeBuilder = new XmlTreeBuilder();
        return treeBuilder.parseFragment(fragmentXml, baseUri, ParseErrorList.noTracking());
    }

    /**
     * Parse a fragment of HTML into the {@code body} of a Document.
     *
     * @param bodyHtml fragment of HTML
     * @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return Document, with empty head, and HTML parsed into body
     */
	//NOTE(az): loop
    public static function parseBodyFragment(bodyHtml:String, baseUri:String):Document {
        var doc:Document = Document.createShell(baseUri);
        var body:Element = doc.body();
        var nodeList:List<Node> = parseFragment(bodyHtml, body, baseUri);
        var nodes:Array<Node> = nodeList.toArray(/*new Node[nodeList.size()]*/); // the node list gets modified when re-parented
        var i = nodes.length - 1;
		//for (int i = nodes.length - 1; i > 0; i--) {
		while (i > 0) {
            nodes[i].remove();
			i--;
        }
        for (node in nodes) {
            body.appendChild(node);
        }
        return doc;
    }

    /**
     * Utility method to unescape HTML entities from a string
     * @param string HTML escaped string
     * @param inAttribute if the string is to be escaped in strict mode (as attributes are)
     * @return an unescaped string
     */
    public static function unescapeEntities(string:String, inAttribute:Bool):String {
        var tokeniser = new Tokeniser(new CharacterReader(string), ParseErrorList.noTracking());
        return tokeniser.unescapeEntities(inAttribute);
    }

    /**
     * @param bodyHtml HTML to parse
     * @param baseUri baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
     *
     * @return parsed Document
     * @deprecated Use {@link #parseBodyFragment} or {@link #parseFragment} instead.
     */
    public static function parseBodyFragmentRelaxed(bodyHtml:String, baseUri:String):Document {
        return parse(bodyHtml, baseUri);
    }
    
    // builders

    /**
     * Create a new HTML parser. This parser treats input as HTML5, and enforces the creation of a normalised document,
     * based on a knowledge of the semantics of the incoming tags.
     * @return a new HTML parser.
     */
    public static function htmlParser():Parser {
        return new Parser(new HtmlTreeBuilder());
    }

    /**
     * Create a new XML parser. This parser assumes no knowledge of the incoming tags and does not treat it as HTML,
     * rather creates a simple tree directly from the input.
     * @return a new simple XML parser.
     */
    public static function xmlParser():Parser {
        return new Parser(new XmlTreeBuilder());
    }
}
