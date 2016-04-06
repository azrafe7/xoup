package org.jsoup.parser;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.List;
import org.jsoup.Exceptions.IllegalArgumentException;
import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.*;
import org.jsoup.parser.tokens.Token;
import org.jsoup.parser.tokens.TokeniserState;
import org.jsoup.select.Elements;

/*mport java.util.ArrayList;
import java.util.List;
*/

/**
 * HTML Tree Builder; creates a DOM from Tokens.
 */
@:allow(org.jsoup.parser.HtmlTreeBuilderState)
@:allow(org.jsoup.parser.Parser)
class HtmlTreeBuilder extends TreeBuilder {
    // tag searches
    private static var TagsScriptStyle:Array<String> = ["script", "style"];
    public static var TagsSearchInScope:Array<String> = ["applet", "caption", "html", "table", "td", "th", "marquee", "object"];
    private static var TagSearchList:Array<String> = ["ol", "ul"];
    private static var TagSearchButton:Array<String> = ["button"];
    private static var TagSearchTableScope:Array<String> = ["html", "table"];
    private static var TagSearchSelectScope:Array<String> = ["optgroup", "option"];
    private static var TagSearchEndTags:Array<String> = ["dd", "dt", "li", "option", "optgroup", "p", "rp", "rt"];
    private static var TagSearchSpecial:Array<String> = ["address", "applet", "area", "article", "aside", "base", "basefont", "bgsound",
            "blockquote", "body", "br", "button", "caption", "center", "col", "colgroup", "command", "dd",
            "details", "dir", "div", "dl", "dt", "embed", "fieldset", "figcaption", "figure", "footer", "form",
            "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hgroup", "hr", "html",
            "iframe", "img", "input", "isindex", "li", "link", "listing", "marquee", "menu", "meta", "nav",
            "noembed", "noframes", "noscript", "object", "ol", "p", "param", "plaintext", "pre", "script",
            "section", "select", "style", "summary", "table", "tbody", "td", "textarea", "tfoot", "th", "thead",
            "title", "tr", "ul", "wbr", "xmp"];

    private var state:HtmlTreeBuilderState; // the current state
    private var originalState:HtmlTreeBuilderState; // original / marked state

    private var baseUriSetFromDoc:Bool = false;
    private var headElement:Element; // the current head element
    private var formElement:FormElement; // the current form element
    private var contextElement:Element; // fragment parse context -- could be null even if fragment parsing
    private var formattingElements:ArrayList<Element> = new ArrayList<Element>(); // active (open) formatting elements
    private var pendingTableCharacters:List<String> = new ArrayList<String>(); // chars in table to be shifted out
    private var emptyEnd:TokenEndTag = new TokenEndTag(); // reused empty end tag

    private var framesetOk:Bool = true; // if ok to go into frameset
    private var fosterInserts:Bool = false; // if next inserts should be fostered
    private var fragmentParsing:Bool = false; // if parsing a fragment of html

    function new() {
		super();
	}

    //@Override
    override function parse(input:String, baseUri:String, errors:ParseErrorList = null):Document {
        state = HtmlTreeBuilderState.Initial;
        baseUriSetFromDoc = false;
        return super.parse(input, baseUri, errors);
    }

    function parseFragment(inputFragment:String, context:Element, baseUri:String, errors:ParseErrorList):List<Node> {
        // context may be null
        state = HtmlTreeBuilderState.Initial;
        initialiseParse(inputFragment, baseUri, errors);
        contextElement = context;
        fragmentParsing = true;
        var root:Element = null;

        if (context != null) {
            if (context.ownerDocument() != null) // quirks setup:
                doc.setQuirksMode(context.ownerDocument().getQuirksMode());

            // initialise the tokeniser state:
            var contextTag:String = context.getTagName();
            if (StringUtil.isAnyOf(contextTag, ["title", "textarea"]))
                tokeniser.transition(TokeniserState.Rcdata);
            else if (StringUtil.isAnyOf(contextTag, ["iframe", "noembed", "noframes", "style", "xmp"]))
                tokeniser.transition(TokeniserState.Rawtext);
            else if (contextTag == ("script"))
                tokeniser.transition(TokeniserState.ScriptData);
            else if (contextTag == ("noscript"))
                tokeniser.transition(TokeniserState.Data); // if scripting enabled, rawtext
            else if (contextTag == ("plaintext"))
                tokeniser.transition(TokeniserState.Data);
            else
                tokeniser.transition(TokeniserState.Data); // default

            root = new Element(Tag.valueOf("html"), baseUri, new Attributes());
            doc.appendChild(root);
            stack.add(root);
            resetInsertionMode();

            // setup form element to nearest form on context (up ancestor chain). ensures form controls are associated
            // with form correctly
            var contextChain:Elements = context.parents();
            contextChain.insert(0, context);
            for (parent in contextChain) {
                if (Std.is(parent, FormElement)) {
                    formElement = cast parent;
                    break;
                }
            }
        }

        runParser();
        if (context != null && root != null)
            return root.getChildNodes();
        else
            return doc.getChildNodes();
    }

    //@Override
	//NOTE(az): conflate with below
    override /*protected*/ function process(token:Token, state:HtmlTreeBuilderState = null):Bool {
        currentToken = token;
		if (state == null) state = this.state;
        return state.process(token, this);
    }

	//NOTE(az): whut?
    /*boolean process(Token token, HtmlTreeBuilderState state) {
        currentToken = token;
        return state.process(token, this);
    }*/

    function transition(state:HtmlTreeBuilderState):Void {
        this.state = state;
    }

    function getState():HtmlTreeBuilderState {
        return state;
    }

    function markInsertionMode():Void {
        originalState = state;
    }

    function getOriginalState():HtmlTreeBuilderState {
        return originalState;
    }

    function setFramesetOk(framesetOk:Bool):Void {
        this.framesetOk = framesetOk;
    }

    function getFramesetOk():Bool {
        return framesetOk;
    }

    function getDocument():Document {
        return doc;
    }

    function getBaseUri():String {
        return baseUri;
    }

    function maybeSetBaseUri(base:Element):Void {
        if (baseUriSetFromDoc) // only listen to the first <base href> in parse
            return;

        var href:String = base.absUrl("href");
        if (href.length != 0) { // ignore <base target> etc
            baseUri = href;
            baseUriSetFromDoc = true;
            doc.setBaseUri(href); // set on the doc so doc.createElement(Tag) will get updated base, and to update all descendants
        }
    }

    function isFragmentParsing():Bool {
        return fragmentParsing;
    }

    function error(state:HtmlTreeBuilderState):Void {
        if (errors.canAddError())
            errors.add(new ParseError(reader.getPos(), 'Unexpected token [${currentToken.tokenType()}] when in state [$state]'));
    }

	//NOTE(az): renamed and conflated insertStartTag
    function insertStartTag(startTagStringOrToken:Dynamic):Element {
        if (Std.is(startTagStringOrToken, TokenStartTag)) {
			var startTag:TokenStartTag = cast startTagStringOrToken;
			
			// handle empty unknown tags
			// when the spec expects an empty tag, will directly hit insertEmpty, so won't generate this fake end tag.
			if (startTag.isSelfClosing()) {
				var el:Element = insertEmpty(startTag);
				stack.add(el);
				tokeniser.transition(TokeniserState.Data); // handles <script />, otherwise needs breakout steps from script data
				tokeniser.emit(emptyEnd.reset().setName(el.getTagName()));  // ensure we get out of whatever state we are in. emitted for yielded processing
				return el;
			}
			
			var el:Element = new Element(Tag.valueOf(startTag.getName()), baseUri, startTag.attributes);
			insertElement(el);
			return el;
		} else if (Std.is(startTagStringOrToken, String)) {
			var startTagName:String = cast startTagStringOrToken;
			
			return _insertStartTag(startTagName);
		} else throw new IllegalArgumentException("Invalid startTag, must be String or TokenStartTag");
    }

    function _insertStartTag(startTagName:String):Element {
        var el:Element = new Element(Tag.valueOf(startTagName), baseUri, new Attributes());
        insertElement(el);
        return el;
    }

	//NOTE(az): renamed to insertElement
    function insertElement(el:Element):Void {
        insertNode(el);
        stack.add(el);
    }

    function insertEmpty(startTag:TokenStartTag):Element {
        var tag:Tag = Tag.valueOf(startTag.getName());
        var el:Element = new Element(tag, baseUri, startTag.attributes);
        insertNode(el);
        if (startTag.isSelfClosing()) {
            if (tag.isKnown()) {
                if (tag.isSelfClosing()) tokeniser.acknowledgeSelfClosingFlag(); // if not acked, promulagates error
            } else {
                // unknown tag, remember this is self closing for output
                tag.setSelfClosing();
                tokeniser.acknowledgeSelfClosingFlag(); // not an distinct error
            }
        }
        return el;
    }

    function insertForm(startTag:TokenStartTag, onStack:Bool):FormElement {
        var tag:Tag = Tag.valueOf(startTag.getName());
        var el:FormElement = new FormElement(tag, baseUri, startTag.attributes);
        setFormElement(el);
        insertNode(el);
        if (onStack)
            stack.add(el);
        return el;
    }

	//NOTE(az): renamed 
    function insertComment(commentToken:TokenComment):Void {
		var comment = new Comment(commentToken.getData(), baseUri);
        insertNode(comment);
    }

	//NOTE(az): renamed
    function insertCharacter(characterToken:TokenCharacter):Void {
        var node:Node;
        // characters in script and style go in as datanodes, not text nodes
        var tagName:String = currentElement().getTagName();
        if (tagName == ("script") || tagName == ("style"))
            node = new DataNode(characterToken.getData(), baseUri);
        else
            node = new TextNode(characterToken.getData(), baseUri);
        currentElement().appendChild(node); // doesn't use insertNode, because we don't foster these; and will always have a stack.
    }

    private function insertNode(node:Node):Void {
        // if the stack hasn't been set up yet, elements (doctype, comments) go into the doc
        if (stack.size == 0)
            doc.appendChild(node);
        else if (isFosterInserts())
            insertInFosterParent(node);
        else
            currentElement().appendChild(node);

        // connect form controls to their form element
        if (Std.is(node, Element) && (cast(node, Element).getTag().isFormListed())) {
            if (formElement != null)
                formElement.addElement(cast(node, Element));
        }
    }

    function pop():Element {
        var size = stack.size;
        return stack.removeAt(size-1);
    }

    function push(element:Element):Void {
        stack.add(element);
    }

    function getStack():ArrayList<Element> {
        return stack;
    }

    function onStack(el:Element):Bool {
        return isElementInQueue(stack, el);
    }

    private function isElementInQueue(queue:ArrayList<Element>, element:Element):Bool {
		var pos = queue.size -1;
        while (pos >= 0) {
            var next:Element = queue.get(pos);
            if (next == element) {
                return true;
            }
			pos--;
        }
        return false;
    }

    function getFromStack(elName:String):Element {
        //for (int pos = stack.size() -1; pos >= 0; pos--) {
		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            if (next.nodeName() == (elName)) {
                return next;
            }
			pos--;
        }
        return null;
    }

    function removeFromStack(el:Element):Bool {
		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            if (next == el) {
                stack.removeAt(pos);
                return true;
            }
			pos--;
        }
        return false;
    }

    function popStackToClose(elName:String):Void {
		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            stack.removeAt(pos);
            if (next.nodeName() == (elName))
                break;
			pos--;	
        }
    }

	//NOTE(az): renamed
    function popStackToCloseAny(elNames:Array<String>):Void {
		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            stack.removeAt(pos);
            if (StringUtil.isAnyOf(next.nodeName(), elNames))
                break;
			pos--;
        }
    }

    function popStackToBefore(elName:String):Void {
		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            if (next.nodeName() == (elName)) {
                break;
            } else {
                stack.removeAt(pos);
            }
			pos--;
        }
    }

    function clearStackToTableContext():Void {
        clearStackToContext(["table"]);
    }

    function clearStackToTableBodyContext():Void {
        clearStackToContext(["tbody", "tfoot", "thead"]);
    }

    function clearStackToTableRowContext():Void {
        clearStackToContext(["tr"]);
    }

    private function clearStackToContext(nodeNames:Array<String>):Void {
        var pos = stack.size -1;
		while (pos >= 0) {
            var next:Element = stack.get(pos);
            if (StringUtil.isAnyOf(next.nodeName(), nodeNames) || next.nodeName() == ("html"))
                break;
            else
                stack.removeAt(pos);
			pos--;
        }
    }

    function aboveOnStack(el:Element):Element {
        Validate.isTrue(onStack(el));
		var pos = stack.size -1;
        while (pos >= 0) {
            var next:Element = stack.get(pos);
            if (next == el) {
                return stack.get(pos-1);
            }
			pos--;
        }
        return null;
    }

    function insertOnStackAfter(after:Element, input:Element):Void {
        var i:Int = stack.lastIndexOf(after);
        Validate.isTrue(i != -1);
        stack.insert(i+1, input);
    }

    function replaceOnStack(out:Element, input:Element):Void {
        replaceInQueue(stack, out, input);
    }

    private function replaceInQueue(queue:ArrayList<Element>, out:Element, input:Element):Void {
        var i:Int = queue.lastIndexOf(out);
        Validate.isTrue(i != -1);
        queue.set(i, input);
    }

    function resetInsertionMode():Void {
        var last:Bool = false;
		var pos = stack.size -1;
        while (pos >= 0) {
            var node:Element = stack.get(pos);
            if (pos == 0) {
                last = true;
                node = contextElement;
            }
            var name:String = node.nodeName();
            if ("select" == (name)) {
                transition(HtmlTreeBuilderState.InSelect);
                break; // frag
            } else if (("td" == (name) || "th" == (name) && !last)) {
                transition(HtmlTreeBuilderState.InCell);
                break;
            } else if ("tr" == (name)) {
                transition(HtmlTreeBuilderState.InRow);
                break;
            } else if ("tbody" == (name) || "thead" == (name) || "tfoot" == (name)) {
                transition(HtmlTreeBuilderState.InTableBody);
                break;
            } else if ("caption" == (name)) {
                transition(HtmlTreeBuilderState.InCaption);
                break;
            } else if ("colgroup" == (name)) {
                transition(HtmlTreeBuilderState.InColumnGroup);
                break; // frag
            } else if ("table" == (name)) {
                transition(HtmlTreeBuilderState.InTable);
                break;
            } else if ("head" == (name)) {
                transition(HtmlTreeBuilderState.InBody);
                break; // frag
            } else if ("body" == (name)) {
                transition(HtmlTreeBuilderState.InBody);
                break;
            } else if ("frameset" == (name)) {
                transition(HtmlTreeBuilderState.InFrameset);
                break; // frag
            } else if ("html" == (name)) {
                transition(HtmlTreeBuilderState.BeforeHead);
                break; // frag
            } else if (last) {
                transition(HtmlTreeBuilderState.InBody);
                break; // frag
            }
			pos--;
        }
    }

    // todo: tidy up in specific scope methods
    private var specificScopeTarget:Array<String> = [null];

	//NOTE(az): renamed
    private function inSpecificScopeSingle(targetName:String, baseTypes:Array<String>, extraTypes:Array<String>):Bool {
        specificScopeTarget[0] = targetName;
        return inSpecificScope(specificScopeTarget, baseTypes, extraTypes);
    }

    private function inSpecificScope(targetNames:Array<String>, baseTypes:Array<String>, extraTypes:Array<String>):Bool {
		var pos = stack.size -1;
        while (pos >= 0) {
			var el:Element = stack.get(pos);
            var elName:String = el.nodeName();
            if (StringUtil.isAnyOf(elName, targetNames))
                return true;
            if (StringUtil.isAnyOf(elName, baseTypes))
                return false;
            if (extraTypes != null && StringUtil.isAnyOf(elName, extraTypes))
                return false;
			pos--;
        }
        Validate.fail("Should not be reachable");
        return false;
    }

    function inScope(targetNames:Array<String>):Bool {
        return inSpecificScope(targetNames, TagsSearchInScope, null);
    }

	//NOTE(az): renamed
    function inScopeSingle(targetName:String):Bool {
        return inScopeExtras(targetName, null);
    }

    function inScopeExtras(targetName:String, extras:Array<String>):Bool {
        return inSpecificScopeSingle(targetName, TagsSearchInScope, extras);
        // todo: in mathml namespace: mi, mo, mn, ms, mtext annotation-xml
        // todo: in svg namespace: forignOjbect, desc, title
    }

    function inListItemScope(targetName:String):Bool {
        return inScopeExtras(targetName, TagSearchList);
    }

    function inButtonScope(targetName:String):Bool {
        return inScopeExtras(targetName, TagSearchButton);
    }

    function inTableScope(targetName:String):Bool {
        return inSpecificScopeSingle(targetName, TagSearchTableScope, null);
    }

    function inSelectScope(targetName:String):Bool {
		var pos = stack.size -1;
        while (pos >= 0) {
            var el:Element = stack.get(pos);
            var elName:String = el.nodeName();
            if (elName == (targetName))
                return true;
            if (!StringUtil.isAnyOf(elName, TagSearchSelectScope)) // all elements except
                return false;
			pos--;
        }
        Validate.fail("Should not be reachable");
        return false;
    }

    function setHeadElement(headElement:Element):Void {
        this.headElement = headElement;
    }

    function getHeadElement():Element {
        return headElement;
    }

    function isFosterInserts():Bool {
        return fosterInserts;
    }

    function setFosterInserts(fosterInserts:Bool):Void {
        this.fosterInserts = fosterInserts;
    }

    function getFormElement():FormElement {
        return formElement;
    }

    function setFormElement(formElement:FormElement):Void {
        this.formElement = formElement;
    }

    function newPendingTableCharacters():Void {
        pendingTableCharacters = new ArrayList<String>();
    }

    function getPendingTableCharacters():List<String> {
        return pendingTableCharacters;
    }

    function setPendingTableCharacters(pendingTableCharacters:List<String>):Void {
        this.pendingTableCharacters = pendingTableCharacters;
    }

    /**
     11.2.5.2 Closing elements that have implied end tags<p/>
     When the steps below require the UA to generate implied end tags, then, while the current node is a dd element, a
     dt element, an li element, an option element, an optgroup element, a p element, an rp element, or an rt element,
     the UA must pop the current node off the stack of open elements.

     @param excludeTag If a step requires the UA to generate implied end tags but lists an element to exclude from the
     process, then the UA must perform the above steps as if that element was not in the above list.
     */
	//NOTE(az): conflate with below
    function generateImpliedEndTags(excludeTag:String = null):Void {
        while ((excludeTag != null && !(currentElement().nodeName() == (excludeTag))) &&
                StringUtil.isAnyOf(currentElement().nodeName(), TagSearchEndTags))
            pop();
    }

	/*
    void generateImpliedEndTags() {
        generateImpliedEndTags(null);
    }*/

    function isSpecial(el:Element):Bool {
        // todo: mathml's mi, mo, mn
        // todo: svg's foreigObject, desc, title
        var name:String = el.nodeName();
        return StringUtil.isAnyOf(name, TagSearchSpecial);
    }

    function lastFormattingElement():Element {
        return formattingElements.size > 0 ? formattingElements.get(formattingElements.size-1) : null;
    }

    function removeLastFormattingElement():Element {
        var size = formattingElements.size;
        if (size > 0)
            return formattingElements.removeAt(size-1);
        else
            return null;
    }

    // active formatting elements
    function pushActiveFormattingElements(input:Element):Void {
        var numSeen:Int = 0;
		var pos = formattingElements.size -1;
        while (pos >= 0) {
            var el:Element = formattingElements.get(pos);
            if (el == null) // marker
                break;

            if (isSameFormattingElement(input, el))
                numSeen++;

            if (numSeen == 3) {
                formattingElements.removeAt(pos);
                break;
            }
			pos--;
        }
        formattingElements.add(input);
    }

    private function isSameFormattingElement(a:Element, b:Element):Bool {
        // same if: same namespace, tag, and attributes. Element.equals only checks tag, might in future check children
        return a.nodeName() == (b.nodeName()) &&
                // a.namespace().equals(b.namespace()) &&
                a.getAttributes().equals(b.getAttributes());
        // todo: namespaces
    }

    function reconstructFormattingElements():Void {
        var last:Element = lastFormattingElement();
        if (last == null || onStack(last))
            return;

        var entry:Element = last;
        var size:Int = formattingElements.size;
        var pos:Int = size - 1;
        var skip:Bool = false;
        while (true) {
            if (pos == 0) { // step 4. if none before, skip to 8
                skip = true;
                break;
            }
            entry = formattingElements.get(--pos); // step 5. one earlier than entry
            if (entry == null || onStack(entry)) // step 6 - neither marker nor on stack
                break; // jump to 8, else continue back to 4
        }
        while(true) {
            if (!skip) // step 7: on later than entry
                entry = formattingElements.get(++pos);
            Validate.notNull(entry); // should not occur, as we break at last element

            // 8. create new element from element, 9 insert into current node, onto stack
            skip = false; // can only skip increment from 4.
            var newEl:Element = insertStartTag(entry.nodeName()); // todo: avoid fostering here?
            // newEl.namespace(entry.namespace()); // todo: namespaces
            newEl.getAttributes().addAll(entry.getAttributes());

            // 10. replace entry with new entry
            formattingElements.set(pos, newEl);

            // 11
            if (pos == size-1) // if not last entry in list, jump to 7
                break;
        }
    }

    function clearFormattingElementsToLastMarker():Void {
        while (!formattingElements.isEmpty()) {
            var el:Element = removeLastFormattingElement();
            if (el == null)
                break;
        }
    }

    function removeFromActiveFormattingElements(el:Element):Void {
		var pos:Int = formattingElements.size -1;
        while (pos >= 0) {
            var next:Element = formattingElements.get(pos);
            if (next == el) {
                formattingElements.removeAt(pos);
                break;
            }
			pos--;
        }
    }

    function isInActiveFormattingElements(el:Element):Bool {
        return isElementInQueue(formattingElements, el);
    }

    function getActiveFormattingElement(nodeName:String):Element {
		var pos = formattingElements.size -1;
        while (pos >= 0) {
            var next:Element = formattingElements.get(pos);
            if (next == null) // scope marker
                break;
            else if (next.nodeName() == (nodeName))
                return next;
			pos--;
        }
        return null;
    }

    function replaceActiveFormattingElement(out:Element, input:Element):Void {
        replaceInQueue(formattingElements, out, input);
    }

    function insertMarkerToFormattingElements():Void {
        formattingElements.add(null);
    }

    function insertInFosterParent(input:Node):Void {
        var fosterParent:Element;
        var lastTable:Element = getFromStack("table");
        var isLastTableParent:Bool = false;
        if (lastTable != null) {
            if (lastTable.parent() != null) {
                fosterParent = lastTable.parent();
                isLastTableParent = true;
            } else
                fosterParent = aboveOnStack(lastTable);
        } else { // no table == frag
            fosterParent = stack.get(0);
        }

        if (isLastTableParent) {
            Validate.notNull(lastTable); // last table cannot be null by this point.
            lastTable.beforeNode(input);
        }
        else
            fosterParent.appendChild(input);
    }

    //@Override
    public function toString():String {
        return "TreeBuilder{" +
                "currentToken=" + currentToken +
                ", state=" + state +
                ", currentElement=" + currentElement() +
                '}';
    }
}
