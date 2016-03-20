package org.jsoup.parser;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.List;
import org.jsoup.helper.StringUtil;
import org.jsoup.nodes.*;
import org.jsoup.nodes.Document.QuirksMode;
import org.jsoup.nodes.Entities.Character;
import org.jsoup.parser.HtmlTreeBuilder;
import org.jsoup.parser.tokens.Token;
import org.jsoup.parser.tokens.TokeniserState;
import unifill.CodePoint;

using unifill.Unifill;

//import java.util.ArrayList;

/**
 * The Tree Builder's current state. Each state embodies the processing for the state, and transitions to other states.
 */
//NOTE(az): using an enum abstract
@:enum abstract HtmlTreeBuilderState(Int) to Int {
    var Initial = 0;
	var BeforeHtml = 1;
	var BeforeHead = 2;
	var InHead = 3;
	var InHeadNoscript = 4;
	var AfterHead = 5;
	var InBody = 6;
	var Text = 7;
	var InTable = 8;
	var InTableText = 9;
	var InCaption = 10;
	var InColumnGroup = 11;
	var InTableBody = 12;
	var InRow = 13;
	var InCell = 14;
	var InSelect = 15;
	var InSelectInTable = 16;
	var AfterBody = 17;
	var InFrameset = 18;
	var AfterFrameset = 19;
	var AfterAfterBody = 20;
	var AfterAfterFrameset = 21;
	var ForeignContent = 22;
	
	
	//NOTE(az): the BIG SWITCH!!
	public function process(t:Token, tb:HtmlTreeBuilder):Bool {
		switch(this) {
        
			case HtmlTreeBuilderState.Initial:
				if (isWhitespace(t)) {
					return true; // ignore whitespace
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype()) {
					// todo: parse error check on expected doctypes
					// todo: quirk state check on doctype ids
					var d:TokenDoctype = t.asDoctype();
					var doctype:DocumentType = new DocumentType(d.getName(), d.getPublicIdentifier(), d.getSystemIdentifier(), tb.getBaseUri());
					tb.getDocument().appendChild(doctype);
					if (d.isForceQuirks())
						tb.getDocument().setQuirksMode(QuirksMode.quirks);
					tb.transition(BeforeHtml);
				} else {
					// todo: check not iframe srcdoc
					tb.transition(BeforeHtml);
					return tb.process(t); // re-process token
				}
				return true;
			
			case HtmlTreeBuilderState.BeforeHtml:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					tb.insertStartTag("html");
					tb.transition(BeforeHead);
					return tb.process(t);
				}
				
				if (t.isDoctype()) {
					tb.error(this);
					return false;
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (isWhitespace(t)) {
					return true; // ignore whitespace
				} else if (t.isStartTag() && t.asStartTag().getName() == ("html")) {
					tb.insertStartTag(t.asStartTag());
					tb.transition(BeforeHead);
				} else if (t.isEndTag() && (StringUtil.isAnyOf(t.asEndTag().getName(), ["head", "body", "html", "br"]))) {
					return anythingElse(t, tb);
				} else if (t.isEndTag()) {
					tb.error(this);
					return false;
				} else {
					return anythingElse(t, tb);
				}
				return true;

			case HtmlTreeBuilderState.BeforeHead:
				if (isWhitespace(t)) {
					return true;
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype()) {
					tb.error(this);
					return false;
				} else if (t.isStartTag() && t.asStartTag().getName() == ("html")) {
					return InBody.process(t, tb); // does not transition
				} else if (t.isStartTag() && t.asStartTag().getName() == ("head")) {
					var head:Element = tb.insertStartTag(t.asStartTag());
					tb.setHeadElement(head);
					tb.transition(InHead);
				} else if (t.isEndTag() && (StringUtil.isAnyOf(t.asEndTag().getName(), ["head", "body", "html", "br"]))) {
					tb.processStartTag("head");
					return tb.process(t);
				} else if (t.isEndTag()) {
					tb.error(this);
					return false;
				} else {
					tb.processStartTag("head");
					return tb.process(t);
				}
				return true;
				
			case HtmlTreeBuilderState.InHead:
				var anythingElse = function(t:Token, tb:TreeBuilder) {
					tb.processEndTag("head");
					return tb.process(t);
				}
				
				if (isWhitespace(t)) {
					tb.insertCharacter(t.asCharacter());
					return true;
				}
				switch (t.type) {
					case Comment:
						tb.insertComment(t.asComment());
						/*break;*/
					case Doctype:
						tb.error(this);
						return false;
					case StartTag:
						var start:TokenStartTag = t.asStartTag();
						var name:String = start.getName();
						if (name == ("html")) {
							return InBody.process(t, tb);
						} else if (StringUtil.isAnyOf(name, ["base", "basefont", "bgsound", "command", "link"])) {
							var el:Element = tb.insertEmpty(start);
							// jsoup special: update base the frist time it is seen
							if (name == ("base") && el.hasAttr("href"))
								tb.maybeSetBaseUri(el);
						} else if (name == ("meta")) {
							var meta:Element = tb.insertEmpty(start);
							// todo: charset switches
						} else if (name == ("title")) {
							handleRcData(start, tb);
						} else if (StringUtil.isAnyOf(name, ["noframes", "style"])) {
							handleRawtext(start, tb);
						} else if (name == ("noscript")) {
							// else if noscript && scripting flag = true: rawtext (jsoup doesn't run script, to handle as noscript)
							tb.insertStartTag(start);
							tb.transition(InHeadNoscript);
						} else if (name == ("script")) {
							// skips some script rules as won't execute them

							tb.tokeniser.transition(TokeniserState.ScriptData);
							tb.markInsertionMode();
							tb.transition(Text);
							tb.insertStartTag(start);
						} else if (name == ("head")) {
							tb.error(this);
							return false;
						} else {
							return anythingElse(t, tb);
						}
						/*break;*/
					case EndTag:
						var end:TokenEndTag = t.asEndTag();
						var name = end.getName();
						if (name == ("head")) {
							tb.pop();
							tb.transition(AfterHead);
						} else if (StringUtil.isAnyOf(name, ["body", "html", "br"])) {
							return anythingElse(t, tb);
						} else {
							tb.error(this);
							return false;
						}
						/*break;*/
					default:
						return anythingElse(t, tb);
				}
				return true;
			
			case HtmlTreeBuilderState.InHeadNoscript:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					tb.error(this);
					tb.insertCharacter(new TokenCharacter().setData(t.toString()));
					return true;
				}
				
				if (t.isDoctype()) {
					tb.error(this);
				} else if (t.isStartTag() && t.asStartTag().getName() == ("html")) {
					return tb.process(t, InBody);
				} else if (t.isEndTag() && t.asEndTag().getName() == ("noscript")) {
					tb.pop();
					tb.transition(InHead);
				} else if (isWhitespace(t) || t.isComment() || (t.isStartTag() && StringUtil.isAnyOf(t.asStartTag().getName(),
						["basefont", "bgsound", "link", "meta", "noframes", "style"]))) {
					return tb.process(t, InHead);
				} else if (t.isEndTag() && t.asEndTag().getName() == ("br")) {
					return anythingElse(t, tb);
				} else if ((t.isStartTag() && StringUtil.isAnyOf(t.asStartTag().getName(), ["head", "noscript"])) || t.isEndTag()) {
					tb.error(this);
					return false;
				} else {
					return anythingElse(t, tb);
				}
				return true;
		
			case HtmlTreeBuilderState.AfterHead:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					tb.processStartTag("body");
					tb.setFramesetOk(true);
					return tb.process(t);
				}
				
				if (isWhitespace(t)) {
					tb.insertCharacter(t.asCharacter());
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype()) {
					tb.error(this);
				} else if (t.isStartTag()) {
					var startTag:TokenStartTag = t.asStartTag();
					var name:String = startTag.getName();
					if (name == ("html")) {
						return tb.process(t, InBody);
					} else if (name == ("body")) {
						tb.insertStartTag(startTag);
						tb.setFramesetOk(false);
						tb.transition(InBody);
					} else if (name == ("frameset")) {
						tb.insertStartTag(startTag);
						tb.transition(InFrameset);
					} else if (StringUtil.isAnyOf(name, ["base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "title"])) {
						tb.error(this);
						var head:Element = tb.getHeadElement();
						tb.push(head);
						tb.process(t, InHead);
						tb.removeFromStack(head);
					} else if (name == ("head")) {
						tb.error(this);
						return false;
					} else {
						anythingElse(t, tb);
					}
				} else if (t.isEndTag()) {
					if (StringUtil.isAnyOf(t.asEndTag().getName(), ["body", "html"])) {
						anythingElse(t, tb);
					} else {
						tb.error(this);
						return false;
					}
				} else {
					anythingElse(t, tb);
				}
				return true;
		
			case HtmlTreeBuilderState.InBody:
				var anyOtherEndTag = function(t:Token, tb:HtmlTreeBuilder):Bool {
					var name:String = t.asEndTag().getName();
					var stack:ArrayList<Element> = tb.getStack();
					var pos = stack.size -1;
					while (pos >= 0) {
						var node:Element = stack.get(pos);
						if (node.nodeName() == (name)) {
							tb.generateImpliedEndTags(name);
							if (!(name == (tb.currentElement().nodeName())))
								tb.error(this);
							tb.popStackToClose(name);
							break;
						} else {
							if (tb.isSpecial(node)) {
								tb.error(this);
								return false;
							}
						}
						pos--;
					}
					return true;
				}
				
				switch (t.type) {
					case TokenType.Character: {
						var c:TokenCharacter = t.asCharacter();
						if (c.getData() == (nullString)) {
							// todo confirm that check
							tb.error(this);
							return false;
						} else if (tb.getFramesetOk() && isWhitespace(c)) { // don't check if whitespace if frames already closed
							tb.reconstructFormattingElements();
							tb.insertCharacter(c);
						} else {
							tb.reconstructFormattingElements();
							tb.insertCharacter(c);
							tb.setFramesetOk(false);
						}
						/*break;*/
					}
					case TokenType.Comment: {
						tb.insertComment(t.asComment());
						/*break;*/
					}
					case TokenType.Doctype: {
						tb.error(this);
						return false;
					}
					case TokenType.StartTag:
						var startTag:TokenStartTag = t.asStartTag();
						var name:String = startTag.getName();
						if (name == ("a")) {
							if (tb.getActiveFormattingElement("a") != null) {
								tb.error(this);
								tb.processEndTag("a");

								// still on stack?
								var remainingA:Element = tb.getFromStack("a");
								if (remainingA != null) {
									tb.removeFromActiveFormattingElements(remainingA);
									tb.removeFromStack(remainingA);
								}
							}
							tb.reconstructFormattingElements();
							var a:Element = tb.insertStartTag(startTag);
							tb.pushActiveFormattingElements(a);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartEmptyFormatters)) {
							tb.reconstructFormattingElements();
							tb.insertEmpty(startTag);
							tb.setFramesetOk(false);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartPClosers)) {
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertStartTag(startTag);
						} else if (name == ("span")) {
							// same as final else, but short circuits lots of checks
							tb.reconstructFormattingElements();
							tb.insertStartTag(startTag);
						} else if (name == ("li")) {
							tb.setFramesetOk(false);
							var stack:ArrayList<Element> = tb.getStack();
							var i = stack.size - 1;
							while (i > 0) {
								var el:Element = stack.get(i);
								if (el.nodeName() == ("li")) {
									tb.processEndTag("li");
									break;
								}
								if (tb.isSpecial(el) && !StringUtil.isAnyOfSorted(el.nodeName(), Constants.InBodyStartLiBreakers))
									break;
								i--;
							}
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertStartTag(startTag);
						} else if (name == ("html")) {
							tb.error(this);
							// merge attributes onto real html
							var html:Element = tb.getStack().get(0);
							for (attribute in startTag.getAttributes()) {
								if (!html.hasAttr(attribute.getKey()))
									html.getAttributes().putAttr(attribute);
							}
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartToHead)) {
							return tb.process(t, InHead);
						} else if (name == ("body")) {
							tb.error(this);
							var stack:ArrayList<Element> = tb.getStack();
							if (stack.size == 1 || (stack.size > 2 && !(stack.get(1).nodeName() == ("body")))) {
								// only in fragment case
								return false; // ignore
							} else {
								tb.setFramesetOk(false);
								var body:Element = stack.get(1);
								for (attribute in startTag.getAttributes()) {
									if (!body.hasAttr(attribute.getKey()))
										body.getAttributes().putAttr(attribute);
								}
							}
						} else if (name == ("frameset")) {
							tb.error(this);
							var stack:ArrayList<Element> = tb.getStack();
							if (stack.size == 1 || (stack.size > 2 && !(stack.get(1).nodeName() == ("body")))) {
								// only in fragment case
								return false; // ignore
							} else if (!tb.getFramesetOk()) {
								return false; // ignore frameset
							} else {
								var second:Element = stack.get(1);
								if (second.parent() != null)
									second.remove();
								// pop up to html element
								while (stack.size > 1)
									stack.removeAt(stack.size-1);
								tb.insertStartTag(startTag);
								tb.transition(InFrameset);
							}
						} else if (StringUtil.isAnyOfSorted(name, Constants.Headings)) {
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							if (StringUtil.isAnyOfSorted(tb.currentElement().nodeName(), Constants.Headings)) {
								tb.error(this);
								tb.pop();
							}
							tb.insertStartTag(startTag);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartPreListing)) {
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertStartTag(startTag);
							// todo: ignore LF if next token
							tb.setFramesetOk(false);
						} else if (name == ("form")) {
							if (tb.getFormElement() != null) {
								tb.error(this);
								return false;
							}
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertForm(startTag, true);
						} else if (StringUtil.isAnyOfSorted(name, Constants.DdDt)) {
							tb.setFramesetOk(false);
							var stack:ArrayList<Element> = tb.getStack();
							var i = stack.size - 1;
							while (i > 0) {
								var el:Element = stack.get(i);
								if (StringUtil.isAnyOfSorted(el.nodeName(), Constants.DdDt)) {
									tb.processEndTag(el.nodeName());
									break;
								}
								if (tb.isSpecial(el) && !StringUtil.isAnyOfSorted(el.nodeName(), Constants.InBodyStartLiBreakers))
									break;
								i--;
							}
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertStartTag(startTag);
						} else if (name == ("plaintext")) {
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertStartTag(startTag);
							tb.tokeniser.transition(TokeniserState.PLAINTEXT); // once in, never gets out
						} else if (name == ("button")) {
							if (tb.inButtonScope("button")) {
								// close and reprocess
								tb.error(this);
								tb.processEndTag("button");
								tb.process(startTag);
							} else {
								tb.reconstructFormattingElements();
								tb.insertStartTag(startTag);
								tb.setFramesetOk(false);
							}
						} else if (StringUtil.isAnyOfSorted(name, Constants.Formatters)) {
							tb.reconstructFormattingElements();
							var el:Element = tb.insertStartTag(startTag);
							tb.pushActiveFormattingElements(el);
						} else if (name == ("nobr")) {
							tb.reconstructFormattingElements();
							if (tb.inScopeSingle("nobr")) {
								tb.error(this);
								tb.processEndTag("nobr");
								tb.reconstructFormattingElements();
							}
							var el:Element = tb.insertStartTag(startTag);
							tb.pushActiveFormattingElements(el);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartApplets)) {
							tb.reconstructFormattingElements();
							tb.insertStartTag(startTag);
							tb.insertMarkerToFormattingElements();
							tb.setFramesetOk(false);
						} else if (name == ("table")) {
							if (tb.getDocument().getQuirksMode() != QuirksMode.quirks && tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertStartTag(startTag);
							tb.setFramesetOk(false);
							tb.transition(InTable);
						} else if (name == ("input")) {
							tb.reconstructFormattingElements();
							var el:Element = tb.insertEmpty(startTag);
							if (!(el.getAttr("type").toLowerCase() == ("hidden").toLowerCase()))
								tb.setFramesetOk(false);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartMedia)) {
							tb.insertEmpty(startTag);
						} else if (name == ("hr")) {
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.insertEmpty(startTag);
							tb.setFramesetOk(false);
						} else if (name == ("image")) {
							if (tb.getFromStack("svg") == null)
								return tb.process(startTag.setName("img")); // change <image> to <img>, unless in svg
							else
								tb.insertStartTag(startTag);
						} else if (name == ("isindex")) {
							// how much do we care about the early 90s?
							tb.error(this);
							if (tb.getFormElement() != null)
								return false;

							tb.tokeniser.acknowledgeSelfClosingFlag();
							tb.processStartTag("form");
							if (startTag.attributes.hasKey("action")) {
								var form:Element = tb.getFormElement();
								form.setAttr("action", startTag.attributes.get("action"));
							}
							tb.processStartTag("hr");
							tb.processStartTag("label");
							// hope you like english.
							var prompt:String = startTag.attributes.hasKey("prompt") ?
									startTag.attributes.get("prompt") :
									"This is a searchable index. Enter search keywords: ";

							tb.process(new TokenCharacter().setData(prompt));

							// input
							var inputAttribs = new Attributes();
							for (attr in startTag.attributes) {
								if (!StringUtil.isAnyOfSorted(attr.getKey(), Constants.InBodyStartInputAttribs))
									inputAttribs.putAttr(attr);
							}
							inputAttribs.put("name", "isindex");
							tb.processStartTagWithAttrs("input", inputAttribs);
							tb.processEndTag("label");
							tb.processStartTag("hr");
							tb.processEndTag("form");
						} else if (name == ("textarea")) {
							tb.insertStartTag(startTag);
							// todo: If the next token is a U+000A LINE FEED (LF) character token, then ignore that token and move on to the next one. (Newlines at the start of textarea elements are ignored as an authoring convenience.)
							tb.tokeniser.transition(TokeniserState.Rcdata);
							tb.markInsertionMode();
							tb.setFramesetOk(false);
							tb.transition(Text);
						} else if (name == ("xmp")) {
							if (tb.inButtonScope("p")) {
								tb.processEndTag("p");
							}
							tb.reconstructFormattingElements();
							tb.setFramesetOk(false);
							handleRawtext(startTag, tb);
						} else if (name == ("iframe")) {
							tb.setFramesetOk(false);
							handleRawtext(startTag, tb);
						} else if (name == ("noembed")) {
							// also handle noscript if script enabled
							handleRawtext(startTag, tb);
						} else if (name == ("select")) {
							tb.reconstructFormattingElements();
							tb.insertStartTag(startTag);
							tb.setFramesetOk(false);

							var state:HtmlTreeBuilderState = tb.getState();
							if (state == (InTable) || state == (InCaption) || state == (InTableBody) || state == (InRow) || state == (InCell))
								tb.transition(InSelectInTable);
							else
								tb.transition(InSelect);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartOptions)) {
							if (tb.currentElement().nodeName() == ("option"))
								tb.processEndTag("option");
							tb.reconstructFormattingElements();
							tb.insertStartTag(startTag);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartRuby)) {
							if (tb.inScopeSingle("ruby")) {
								tb.generateImpliedEndTags();
								if (!(tb.currentElement().nodeName() == ("ruby"))) {
									tb.error(this);
									tb.popStackToBefore("ruby"); // i.e. close up to but not include name
								}
								tb.insertStartTag(startTag);
							}
						} else if (name == ("math")) {
							tb.reconstructFormattingElements();
							// todo: handle A start tag whose tag name is "math" (i.e. foreign, mathml)
							tb.insertStartTag(startTag);
							tb.tokeniser.acknowledgeSelfClosingFlag();
						} else if (name == ("svg")) {
							tb.reconstructFormattingElements();
							// todo: handle A start tag whose tag name is "svg" (xlink, svg)
							tb.insertStartTag(startTag);
							tb.tokeniser.acknowledgeSelfClosingFlag();
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartDrop)) {
							tb.error(this);
							return false;
						} else {
							tb.reconstructFormattingElements();
							tb.insertStartTag(startTag);
						}
						/*break;*/

					case TokenType.EndTag:
						var endTag:TokenEndTag = t.asEndTag();
						var name = endTag.getName();
						if (StringUtil.isAnyOfSorted(name, Constants.InBodyEndAdoptionFormatters)) {
							// Adoption Agency Algorithm.
							for (i in 0...8) {
								var formatEl:Element = tb.getActiveFormattingElement(name);
								if (formatEl == null)
									return anyOtherEndTag(t, tb);
								else if (!tb.onStack(formatEl)) {
									tb.error(this);
									tb.removeFromActiveFormattingElements(formatEl);
									return true;
								} else if (!tb.inScopeSingle(formatEl.nodeName())) {
									tb.error(this);
									return false;
								} else if (tb.currentElement() != formatEl)
									tb.error(this);

								var furthestBlock:Element = null;
								var commonAncestor:Element = null;
								var seenFormattingElement:Bool = false;
								var stack:ArrayList<Element> = tb.getStack();
								// the spec doesn't limit to < 64, but in degenerate cases (9000+ stack depth) this prevents
								// run-aways
								var stackSize:Int = stack.size;
								var si:Int = 0;
								while (si < stackSize && si < 64) {
									var el:Element = stack.get(si);
									if (el == formatEl) {
										commonAncestor = stack.get(si - 1);
										seenFormattingElement = true;
									} else if (seenFormattingElement && tb.isSpecial(el)) {
										furthestBlock = el;
										break;
									}
									si++;
								}
								if (furthestBlock == null) {
									tb.popStackToClose(formatEl.nodeName());
									tb.removeFromActiveFormattingElements(formatEl);
									return true;
								}

								// todo: Let a bookmark note the position of the formatting element in the list of active formatting elements relative to the elements on either side of it in the list.
								// does that mean: int pos of format el in list?
								var node:Element = furthestBlock;
								var lastNode:Element = furthestBlock;
								for (j in 0...3) {
									if (tb.onStack(node))
										node = tb.aboveOnStack(node);
									if (!tb.isInActiveFormattingElements(node)) { // note no bookmark check
										tb.removeFromStack(node);
										continue;
									} else if (node == formatEl)
										break;

									var replacement = new Element(Tag.valueOf(node.nodeName()), tb.getBaseUri(), new Attributes());
									tb.replaceActiveFormattingElement(node, replacement);
									tb.replaceOnStack(node, replacement);
									node = replacement;

									if (lastNode == furthestBlock) {
										// todo: move the aforementioned bookmark to be immediately after the new node in the list of active formatting elements.
										// not getting how this bookmark both straddles the element above, but is inbetween here...
									}
									if (lastNode.parent() != null)
										lastNode.remove();
									node.appendChild(lastNode);

									lastNode = node;
								}

								if (StringUtil.isAnyOfSorted(commonAncestor.nodeName(), Constants.InBodyEndTableFosters)) {
									if (lastNode.parent() != null)
										lastNode.remove();
									tb.insertInFosterParent(lastNode);
								} else {
									if (lastNode.parent() != null)
										lastNode.remove();
									commonAncestor.appendChild(lastNode);
								}

								var adopter = new Element(formatEl.getTag(), tb.getBaseUri(), new Attributes());
								adopter.getAttributes().addAll(formatEl.getAttributes());
								var childNodes:Array<Node> = furthestBlock.getChildNodes().toArray(/*new Node[furthestBlock.childNodeSize()]*/);
								for (childNode in childNodes) {
									adopter.appendChild(childNode); // append will reparent. thus the clone to avoid concurrent mod.
								}
								furthestBlock.appendChild(adopter);
								tb.removeFromActiveFormattingElements(formatEl);
								// todo: insert the new element into the list of active formatting elements at the position of the aforementioned bookmark.
								tb.removeFromStack(formatEl);
								tb.insertOnStackAfter(furthestBlock, adopter);
							}
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyEndClosers)) {
							if (!tb.inScopeSingle(name)) {
								// nothing to close
								tb.error(this);
								return false;
							} else {
								tb.generateImpliedEndTags();
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								tb.popStackToClose(name);
							}
						} else if (name == ("span")) {
							// same as final fall through, but saves short circuit
							return anyOtherEndTag(t, tb);
						} else if (name == ("li")) {
							if (!tb.inListItemScope(name)) {
								tb.error(this);
								return false;
							} else {
								tb.generateImpliedEndTags(name);
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								tb.popStackToClose(name);
							}
						} else if (name == ("body")) {
							if (!tb.inScopeSingle("body")) {
								tb.error(this);
								return false;
							} else {
								// todo: error if stack contains something not dd, dt, li, optgroup, option, p, rp, rt, tbody, td, tfoot, th, thead, tr, body, html
								tb.transition(AfterBody);
							}
						} else if (name == ("html")) {
							var notIgnored:Bool = tb.processEndTag("body");
							if (notIgnored)
								return tb.process(endTag);
						} else if (name == ("form")) {
							var currentForm:Element = tb.getFormElement();
							tb.setFormElement(null);
							if (currentForm == null || !tb.inScopeSingle(name)) {
								tb.error(this);
								return false;
							} else {
								tb.generateImpliedEndTags();
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								// remove currentForm from stack. will shift anything under up.
								tb.removeFromStack(currentForm);
							}
						} else if (name == ("p")) {
							if (!tb.inButtonScope(name)) {
								tb.error(this);
								tb.processStartTag(name); // if no p to close, creates an empty <p></p>
								return tb.process(endTag);
							} else {
								tb.generateImpliedEndTags(name);
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								tb.popStackToClose(name);
							}
						} else if (StringUtil.isAnyOfSorted(name, Constants.DdDt)) {
							if (!tb.inScopeSingle(name)) {
								tb.error(this);
								return false;
							} else {
								tb.generateImpliedEndTags(name);
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								tb.popStackToClose(name);
							}
						} else if (StringUtil.isAnyOfSorted(name, Constants.Headings)) {
							if (!tb.inScope(Constants.Headings)) {
								tb.error(this);
								return false;
							} else {
								tb.generateImpliedEndTags(name);
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								tb.popStackToCloseAny(Constants.Headings);
							}
						} else if (name == ("sarcasm")) {
							// *sigh*
							return anyOtherEndTag(t, tb);
						} else if (StringUtil.isAnyOfSorted(name, Constants.InBodyStartApplets)) {
							if (!tb.inScopeSingle("name")) {
								if (!tb.inScopeSingle(name)) {
									tb.error(this);
									return false;
								}
								tb.generateImpliedEndTags();
								if (!(tb.currentElement().nodeName() == (name)))
									tb.error(this);
								tb.popStackToClose(name);
								tb.clearFormattingElementsToLastMarker();
							}
						} else if (name == ("br")) {
							tb.error(this);
							tb.processStartTag("br");
							return false;
						} else {
							return anyOtherEndTag(t, tb);
						}
						/*break;*/
					
					case TokenType.EOF:
						// todo: error if stack contains something not dd, dt, li, p, tbody, td, tfoot, th, thead, tr, body, html
						// stop parsing
						/*break;*/
				}
				return true;

			case HtmlTreeBuilderState.Text:
				// in script, style etc. normally treated as data tags
				if (t.isCharacter()) {
					tb.insertCharacter(t.asCharacter());
				} else if (t.isEOF()) {
					tb.error(this);
					// if current node is script: already started
					tb.pop();
					tb.transition(tb.getOriginalState());
					return tb.process(t);
				} else if (t.isEndTag()) {
					// if: An end tag whose tag name is "script" -- scripting nesting level, if evaluating scripts
					tb.pop();
					tb.transition(tb.getOriginalState());
				}
				return true;
    
			case HtmlTreeBuilderState.InTable:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					tb.error(this);
					var processed:Bool;
					if (StringUtil.isAnyOf(tb.currentElement().nodeName(), ["table", "tbody", "tfoot", "thead", "tr"])) {
						tb.setFosterInserts(true);
						processed = tb.process(t, InBody);
						tb.setFosterInserts(false);
					} else {
						processed = tb.process(t, InBody);
					}
					return processed;
				}
				if (t.isCharacter()) {
					tb.newPendingTableCharacters();
					tb.markInsertionMode();
					tb.transition(InTableText);
					return tb.process(t);
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
					return true;
				} else if (t.isDoctype()) {
					tb.error(this);
					return false;
				} else if (t.isStartTag()) {
					var startTag:TokenStartTag = t.asStartTag();
					var name:String = startTag.getName();
					if (name == ("caption")) {
						tb.clearStackToTableContext();
						tb.insertMarkerToFormattingElements();
						tb.insertStartTag(startTag);
						tb.transition(InCaption);
					} else if (name == ("colgroup")) {
						tb.clearStackToTableContext();
						tb.insertStartTag(startTag);
						tb.transition(InColumnGroup);
					} else if (name == ("col")) {
						tb.processStartTag("colgroup");
						return tb.process(t);
					} else if (StringUtil.isAnyOf(name, ["tbody", "tfoot", "thead"])) {
						tb.clearStackToTableContext();
						tb.insertStartTag(startTag);
						tb.transition(InTableBody);
					} else if (StringUtil.isAnyOf(name, ["td", "th", "tr"])) {
						tb.processStartTag("tbody");
						return tb.process(t);
					} else if (name == ("table")) {
						tb.error(this);
						var processed:Bool = tb.processEndTag("table");
						if (processed) // only ignored if in fragment
							return tb.process(t);
					} else if (StringUtil.isAnyOf(name, ["style", "script"])) {
						return tb.process(t, InHead);
					} else if (name == ("input")) {
						if (!(startTag.attributes.get("type").toLowerCase() == ("hidden"))) {
							return anythingElse(t, tb);
						} else {
							tb.insertEmpty(startTag);
						}
					} else if (name == ("form")) {
						tb.error(this);
						if (tb.getFormElement() != null)
							return false;
						else {
							tb.insertForm(startTag, false);
						}
					} else {
						return anythingElse(t, tb);
					}
					return true; // todo: check if should return processed http://www.whatwg.org/specs/web-apps/current-work/multipage/tree-construction.html#parsing-main-intable
				} else if (t.isEndTag()) {
					var endTag:TokenEndTag = t.asEndTag();
					var name:String = endTag.getName();

					if (name == ("table")) {
						if (!tb.inTableScope(name)) {
							tb.error(this);
							return false;
						} else {
							tb.popStackToClose("table");
						}
						tb.resetInsertionMode();
					} else if (StringUtil.isAnyOf(name,
							["body", "caption", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"])) {
						tb.error(this);
						return false;
					} else {
						return anythingElse(t, tb);
					}
					return true; // todo: as above todo
				} else if (t.isEOF()) {
					if (tb.currentElement().nodeName() == ("html"))
						tb.error(this);
					return true; // stops parsing
				}
				return anythingElse(t, tb);

			case HtmlTreeBuilderState.InTableText:
				switch (t.type) {
					case TokenType.Character:
						var c:TokenCharacter = t.asCharacter();
						if (c.getData() == (nullString)) {
							tb.error(this);
							return false;
						} else {
							tb.getPendingTableCharacters().add(c.getData());
						}
						/*break;*/
					default:
						// todo - don't really like the way these table character data lists are built
						if (tb.getPendingTableCharacters().size > 0) {
							for (character in tb.getPendingTableCharacters()) {
								if (!_isWhitespace(character)) {
									// InTable anything else section:
									tb.error(this);
									if (StringUtil.isAnyOf(tb.currentElement().nodeName(), ["table", "tbody", "tfoot", "thead", "tr"])) {
										tb.setFosterInserts(true);
										tb.process(new TokenCharacter().setData(character), InBody);
										tb.setFosterInserts(false);
									} else {
										tb.process(new TokenCharacter().setData(character), InBody);
									}
								} else
									tb.insertCharacter(new TokenCharacter().setData(character));
							}
							tb.newPendingTableCharacters();
						}
						tb.transition(tb.getOriginalState());
						return tb.process(t);
				}
				return true;

			case HtmlTreeBuilderState.InCaption:
				if (t.isEndTag() && t.asEndTag().getName() == ("caption")) {
					var endTag:TokenEndTag = t.asEndTag();
					var name:String = endTag.getName();
					if (!tb.inTableScope(name)) {
						tb.error(this);
						return false;
					} else {
						tb.generateImpliedEndTags();
						if (!(tb.currentElement().nodeName() == ("caption")))
							tb.error(this);
						tb.popStackToClose("caption");
						tb.clearFormattingElementsToLastMarker();
						tb.transition(InTable);
					}
				} else if ((
						t.isStartTag() && StringUtil.isAnyOf(t.asStartTag().getName(),
								["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"]) ||
								t.isEndTag() && t.asEndTag().getName() == ("table"))
						) {
					tb.error(this);
					var processed:Bool = tb.processEndTag("caption");
					if (processed)
						return tb.process(t);
				} else if (t.isEndTag() && StringUtil.isAnyOf(t.asEndTag().getName(),
						["body", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"])) {
					tb.error(this);
					return false;
				} else {
					return tb.process(t, InBody);
				}
				return true;

			case HtmlTreeBuilderState.InColumnGroup:
				var anythingElse = function(t:Token, tb:TreeBuilder):Bool {
					var processed = tb.processEndTag("colgroup");
					if (processed) // only ignored in frag case
						return tb.process(t);
					return true;
				}
				
				if (isWhitespace(t)) {
					tb.insertCharacter(t.asCharacter());
					return true;
				}
				switch (t.type) {
					case TokenType.Comment:
						tb.insertComment(t.asComment());
						/*break;*/
					case TokenType.Doctype:
						tb.error(this);
						/*break;*/
					case TokenType.StartTag:
						var startTag:TokenStartTag = t.asStartTag();
						var name = startTag.getName();
						if (name == ("html"))
							return tb.process(t, InBody);
						else if (name == ("col"))
							tb.insertEmpty(startTag);
						else
							return anythingElse(t, tb);
						/*break;*/
					case TokenType.EndTag:
						var endTag:TokenEndTag = t.asEndTag();
						var name = endTag.getName();
						if (name == ("colgroup")) {
							if (tb.currentElement().nodeName() == ("html")) { // frag case
								tb.error(this);
								return false;
							} else {
								tb.pop();
								tb.transition(InTable);
							}
						} else
							return anythingElse(t, tb);
						/*break;*/
					case TokenType.EOF:
						if (tb.currentElement().nodeName() == ("html"))
							return true; // stop parsing; frag case
						else
							return anythingElse(t, tb);
					default:
						return anythingElse(t, tb);
				}
				return true;

			case HtmlTreeBuilderState.InTableBody:
				var exitTableBody = function(t:Token, tb:HtmlTreeBuilder):Bool {
					if (!(tb.inTableScope("tbody") || tb.inTableScope("thead") || tb.inScopeSingle("tfoot"))) {
						// frag case
						tb.error(this);
						return false;
					}
					tb.clearStackToTableBodyContext();
					tb.processEndTag(tb.currentElement().nodeName()); // tbody, tfoot, thead
					return tb.process(t);
				}

				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					return tb.process(t, InTable);
				}
				
				switch (t.type) {
					case TokenType.StartTag:
						var startTag:TokenStartTag = t.asStartTag();
						var name:String = startTag.getName();
						if (name == ("tr")) {
							tb.clearStackToTableBodyContext();
							tb.insertStartTag(startTag);
							tb.transition(InRow);
						} else if (StringUtil.isAnyOf(name, ["th", "td"])) {
							tb.error(this);
							tb.processStartTag("tr");
							return tb.process(startTag);
						} else if (StringUtil.isAnyOf(name, ["caption", "col", "colgroup", "tbody", "tfoot", "thead"])) {
							return exitTableBody(t, tb);
						} else
							return anythingElse(t, tb);
						/*break;*/
					case TokenType.EndTag:
						var endTag:TokenEndTag = t.asEndTag();
						var name = endTag.getName();
						if (StringUtil.isAnyOf(name, ["tbody", "tfoot", "thead"])) {
							if (!tb.inTableScope(name)) {
								tb.error(this);
								return false;
							} else {
								tb.clearStackToTableBodyContext();
								tb.pop();
								tb.transition(InTable);
							}
						} else if (name == ("table")) {
							return exitTableBody(t, tb);
						} else if (StringUtil.isAnyOf(name, ["body", "caption", "col", "colgroup", "html", "td", "th", "tr"])) {
							tb.error(this);
							return false;
						} else
							return anythingElse(t, tb);
						/*break;*/
					default:
						return anythingElse(t, tb);
				}
				return true;
		
			case HtmlTreeBuilderState.InRow:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					return tb.process(t, InTable);
				}

				var handleMissingTr = function(t:Token, tb:TreeBuilder):Bool {
					var processed:Bool = tb.processEndTag("tr");
					if (processed)
						return tb.process(t);
					else
						return false;
				}
				
				if (t.isStartTag()) {
					var startTag:TokenStartTag = t.asStartTag();
					var name:String = startTag.getName();

					if (StringUtil.isAnyOf(name, ["th", "td"])) {
						tb.clearStackToTableRowContext();
						tb.insertStartTag(startTag);
						tb.transition(InCell);
						tb.insertMarkerToFormattingElements();
					} else if (StringUtil.isAnyOf(name, ["caption", "col", "colgroup", "tbody", "tfoot", "thead", "tr"])) {
						return handleMissingTr(t, tb);
					} else {
						return anythingElse(t, tb);
					}
				} else if (t.isEndTag()) {
					var endTag:TokenEndTag = t.asEndTag();
					var name:String = endTag.getName();

					if (name == ("tr")) {
						if (!tb.inTableScope(name)) {
							tb.error(this); // frag
							return false;
						}
						tb.clearStackToTableRowContext();
						tb.pop(); // tr
						tb.transition(InTableBody);
					} else if (name == ("table")) {
						return handleMissingTr(t, tb);
					} else if (StringUtil.isAnyOf(name, ["tbody", "tfoot", "thead"])) {
						if (!tb.inTableScope(name)) {
							tb.error(this);
							return false;
						}
						tb.processEndTag("tr");
						return tb.process(t);
					} else if (StringUtil.isAnyOf(name, ["body", "caption", "col", "colgroup", "html", "td", "th"])) {
						tb.error(this);
						return false;
					} else {
						return anythingElse(t, tb);
					}
				} else {
					return anythingElse(t, tb);
				}
				return true;

			case HtmlTreeBuilderState.InCell:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					return tb.process(t, InBody);
				}

				var closeCell = function(tb:HtmlTreeBuilder):Void {
					if (tb.inTableScope("td"))
						tb.processEndTag("td");
					else
						tb.processEndTag("th"); // only here if th or td in scope
				}
				
				if (t.isEndTag()) {
					var endTag:TokenEndTag = t.asEndTag();
					var name:String = endTag.getName();

					if (StringUtil.isAnyOf(name, ["td", "th"])) {
						if (!tb.inTableScope(name)) {
							tb.error(this);
							tb.transition(InRow); // might not be in scope if empty: <td /> and processing fake end tag
							return false;
						}
						tb.generateImpliedEndTags();
						if (!(tb.currentElement().nodeName() == (name)))
							tb.error(this);
						tb.popStackToClose(name);
						tb.clearFormattingElementsToLastMarker();
						tb.transition(InRow);
					} else if (StringUtil.isAnyOf(name, ["body", "caption", "col", "colgroup", "html"])) {
						tb.error(this);
						return false;
					} else if (StringUtil.isAnyOf(name, ["table", "tbody", "tfoot", "thead", "tr"])) {
						if (!tb.inTableScope(name)) {
							tb.error(this);
							return false;
						}
						closeCell(tb);
						return tb.process(t);
					} else {
						return anythingElse(t, tb);
					}
				} else if (t.isStartTag() &&
						StringUtil.isAnyOf(t.asStartTag().getName(),
								["caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"])) {
					if (!(tb.inTableScope("td") || tb.inTableScope("th"))) {
						tb.error(this);
						return false;
					}
					closeCell(tb);
					return tb.process(t);
				} else {
					return anythingElse(t, tb);
				}
				return true;
			
			case HtmlTreeBuilderState.InSelect:
				var anythingElse = function(t:Token, tb:HtmlTreeBuilder):Bool {
					tb.error(this);
					return false;
				}
				
				switch (t.type) {
					case TokenType.Character:
						var c:TokenCharacter = t.asCharacter();
						if (c.getData() == (nullString)) {
							tb.error(this);
							return false;
						} else {
							tb.insertCharacter(c);
						}
						/*break;*/
					case TokenType.Comment:
						tb.insertComment(t.asComment());
						/*break;*/
					case TokenType.Doctype:
						tb.error(this);
						return false;
					case TokenType.StartTag:
						var start:TokenStartTag = t.asStartTag();
						var name:String = start.getName();
						if (name == ("html"))
							return tb.process(start, InBody);
						else if (name == ("option")) {
							tb.processEndTag("option");
							tb.insertStartTag(start);
						} else if (name == ("optgroup")) {
							if (tb.currentElement().nodeName() == ("option"))
								tb.processEndTag("option");
							else if (tb.currentElement().nodeName() == ("optgroup"))
								tb.processEndTag("optgroup");
							tb.insertStartTag(start);
						} else if (name == ("select")) {
							tb.error(this);
							return tb.processEndTag("select");
						} else if (StringUtil.isAnyOf(name, ["input", "keygen", "textarea"])) {
							tb.error(this);
							if (!tb.inSelectScope("select"))
								return false; // frag
							tb.processEndTag("select");
							return tb.process(start);
						} else if (name == ("script")) {
							return tb.process(t, InHead);
						} else {
							return anythingElse(t, tb);
						}
						/*break;*/
					case TokenType.EndTag:
						var end:TokenEndTag = t.asEndTag();
						var name = end.getName();
						if (name == ("optgroup")) {
							if (tb.currentElement().nodeName() == ("option") && tb.aboveOnStack(tb.currentElement()) != null && tb.aboveOnStack(tb.currentElement()).nodeName() == ("optgroup"))
								tb.processEndTag("option");
							if (tb.currentElement().nodeName() == ("optgroup"))
								tb.pop();
							else
								tb.error(this);
						} else if (name == ("option")) {
							if (tb.currentElement().nodeName() == ("option"))
								tb.pop();
							else
								tb.error(this);
						} else if (name == ("select")) {
							if (!tb.inSelectScope(name)) {
								tb.error(this);
								return false;
							} else {
								tb.popStackToClose(name);
								tb.resetInsertionMode();
							}
						} else
							return anythingElse(t, tb);
						/*break;*/
					case TokenType.EOF:
						if (!(tb.currentElement().nodeName() == ("html")))
							tb.error(this);
						/*break;*/
					default:
						return anythingElse(t, tb);
				}
				return true;
			
			case HtmlTreeBuilderState.InSelectInTable:
				if (t.isStartTag() && StringUtil.isAnyOf(t.asStartTag().getName(), ["caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"])) {
					tb.error(this);
					tb.processEndTag("select");
					return tb.process(t);
				} else if (t.isEndTag() && StringUtil.isAnyOf(t.asEndTag().getName(), ["caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"])) {
					tb.error(this);
					if (tb.inTableScope(t.asEndTag().getName())) {
						tb.processEndTag("select");
						return (tb.process(t));
					} else
						return false;
				} else {
					return tb.process(t, InSelect);
				}
			
			case HtmlTreeBuilderState.AfterBody:
				if (isWhitespace(t)) {
					return tb.process(t, InBody);
				} else if (t.isComment()) {
					tb.insertComment(t.asComment()); // into html node
				} else if (t.isDoctype()) {
					tb.error(this);
					return false;
				} else if (t.isStartTag() && t.asStartTag().getName() == ("html")) {
					return tb.process(t, InBody);
				} else if (t.isEndTag() && t.asEndTag().getName() == ("html")) {
					if (tb.isFragmentParsing()) {
						tb.error(this);
						return false;
					} else {
						tb.transition(AfterAfterBody);
					}
				} else if (t.isEOF()) {
					// chillax! we're done
				} else {
					tb.error(this);
					tb.transition(InBody);
					return tb.process(t);
				}
				return true;

			case HtmlTreeBuilderState.InFrameset:
				if (isWhitespace(t)) {
					tb.insertCharacter(t.asCharacter());
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype()) {
					tb.error(this);
					return false;
				} else if (t.isStartTag()) {
					var start:TokenStartTag = t.asStartTag();
					var name:String = start.getName();
					if (name == ("html")) {
						return tb.process(start, InBody);
					} else if (name == ("frameset")) {
						tb.insertStartTag(start);
					} else if (name == ("frame")) {
						tb.insertEmpty(start);
					} else if (name == ("noframes")) {
						return tb.process(start, InHead);
					} else {
						tb.error(this);
						return false;
					}
				} else if (t.isEndTag() && t.asEndTag().getName() == ("frameset")) {
					if (tb.currentElement().nodeName() == ("html")) { // frag
						tb.error(this);
						return false;
					} else {
						tb.pop();
						if (!tb.isFragmentParsing() && !(tb.currentElement().nodeName() == ("frameset"))) {
							tb.transition(AfterFrameset);
						}
					}
				} else if (t.isEOF()) {
					if (!(tb.currentElement().nodeName() == ("html"))) {
						tb.error(this);
						return true;
					}
				} else {
					tb.error(this);
					return false;
				}
				return true;

			case HtmlTreeBuilderState.AfterFrameset:
				if (isWhitespace(t)) {
					tb.insertCharacter(t.asCharacter());
				} else if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype()) {
					tb.error(this);
					return false;
				} else if (t.isStartTag() && t.asStartTag().getName() == ("html")) {
					return tb.process(t, InBody);
				} else if (t.isEndTag() && t.asEndTag().getName() == ("html")) {
					tb.transition(AfterAfterFrameset);
				} else if (t.isStartTag() && t.asStartTag().getName() == ("noframes")) {
					return tb.process(t, InHead);
				} else if (t.isEOF()) {
					// cool your heels, we're complete
				} else {
					tb.error(this);
					return false;
				}
				return true;
			
			case HtmlTreeBuilderState.AfterAfterBody:
				if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype() || isWhitespace(t) || (t.isStartTag() && t.asStartTag().getName() == ("html"))) {
					return tb.process(t, InBody);
				} else if (t.isEOF()) {
					// nice work chuck
				} else {
					tb.error(this);
					tb.transition(InBody);
					return tb.process(t);
				}
				return true;
			
			case HtmlTreeBuilderState.AfterAfterFrameset:
				if (t.isComment()) {
					tb.insertComment(t.asComment());
				} else if (t.isDoctype() || isWhitespace(t) || (t.isStartTag() && t.asStartTag().getName() == ("html"))) {
					return tb.process(t, InBody);
				} else if (t.isEOF()) {
					// nice work chuck
				} else if (t.isStartTag() && t.asStartTag().getName() == ("noframes")) {
					return tb.process(t, InHead);
				} else {
					tb.error(this);
					return false;
				}
				return true;

			case HtmlTreeBuilderState.ForeignContent:
				return true;
				// todo: implement. Also; how do we get here?
				
			default:
				return true;
				
		} //NOTE(az): end of BIG SWITCH
	}//end of process()

    private static var nullString:String = CodePoint.fromInt(0).toString();

    private static function isWhitespace(t:Token):Bool {
        if (t.isCharacter()) {
            var data:String = t.asCharacter().getData();
            return _isWhitespace(data);
        }
        return false;
    }

    private static function _isWhitespace(data:String):Bool {
        // todo: this checks more than spec - "\t", "\n", "\f", "\r", " "
        for (i in 0...data.uLength()) {
            var c:CodePoint = data.uCharCodeAt(i);
            if (!StringUtil.isWhitespace(c))
                return false;
        }
        return true;
    }

    private static function handleRcData(startTag:TokenStartTag, tb:HtmlTreeBuilder):Void {
        tb.insertStartTag(startTag);
        tb.tokeniser.transition(TokeniserState.Rcdata);
        tb.markInsertionMode();
        tb.transition(Text);
    }

    private static function handleRawtext(startTag:TokenStartTag, tb:HtmlTreeBuilder):Void {
        tb.insertStartTag(startTag);
        tb.tokeniser.transition(TokeniserState.Rawtext);
        tb.markInsertionMode();
        tb.transition(Text);
    }

}

// lists of tags to search through. A little harder to read here, but causes less GC than dynamic varargs.
// was contributing around 10% of parse GC load.
@:allow(org.jsoup.parser.HtmlTreeBuilderState)
private /*static final*/ class Constants {
	private static var InBodyStartToHead:Array<String> = ["base", "basefont", "bgsound", "command", "link", "meta", "noframes", "script", "style", "title"];
	private static var InBodyStartPClosers:Array<String> = ["address", "article", "aside", "blockquote", "center", "details", "dir", "div", "dl",
			"fieldset", "figcaption", "figure", "footer", "header", "hgroup", "menu", "nav", "ol",
			"p", "section", "summary", "ul"];
	private static var Headings:Array<String> = ["h1", "h2", "h3", "h4", "h5", "h6"];
	private static var InBodyStartPreListing:Array<String> = ["pre", "listing"];
	private static var InBodyStartLiBreakers = ["address", "div", "p"];
	private static var DdDt = ["dd", "dt"];
	private static var Formatters = ["b", "big", "code", "em", "font", "i", "s", "small", "strike", "strong", "tt", "u"];
	private static var InBodyStartApplets = ["applet", "marquee", "object"];
	private static var InBodyStartEmptyFormatters = ["area", "br", "embed", "img", "keygen", "wbr"];
	private static var InBodyStartMedia = ["param", "source", "track"];
	private static var InBodyStartInputAttribs = ["name", "action", "prompt"];
	private static var InBodyStartOptions = ["optgroup", "option"];
	private static var InBodyStartRuby = ["rp", "rt"];
	private static var InBodyStartDrop = ["caption", "col", "colgroup", "frame", "head", "tbody", "td", "tfoot", "th", "thead", "tr"];
	private static var InBodyEndClosers = ["address", "article", "aside", "blockquote", "button", "center", "details", "dir", "div",
			"dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "listing", "menu",
			"nav", "ol", "pre", "section", "summary", "ul"];
	private static var InBodyEndAdoptionFormatters = ["a", "b", "big", "code", "em", "font", "i", "nobr", "s", "small", "strike", "strong", "tt", "u"];
	private static var InBodyEndTableFosters = ["table", "tbody", "tfoot", "thead", "tr"];
	
	function new() { }
}
