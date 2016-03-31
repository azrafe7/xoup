package org.jsoup.parser.tokens;

import org.jsoup.parser.tokens.Token;
import unifill.CodePoint;

using org.jsoup.InternalTools;
using unifill.Unifill;
using StringTools;

//import java.util.Arrays;

/**
 * States and transition activations for the TokeniserState.
 */
//NOTE(az): using an enum abstract
@:enum abstract TokeniserState(Int) to Int {
	var Data                                    = 0;
	var CharacterReferenceInData                = 1;
	var Rcdata                                  = 2;
	var CharacterReferenceInRcdata              = 3;
	var Rawtext                                 = 4;
	var ScriptData                              = 5;
	var PLAINTEXT                               = 6;
	var TagOpen                                 = 7;
	var EndTagOpen                              = 8;
	var TagName                                 = 9;
	var RcdataLessthanSign                      = 10;
	var RCDATAEndTagOpen                        = 11;
	var RCDATAEndTagName                        = 12;
	var RawtextLessthanSign                     = 13;
	var RawtextEndTagOpen                       = 14;
	var RawtextEndTagName                       = 15;
	var ScriptDataLessthanSign                  = 16;
	var ScriptDataEndTagOpen                    = 17;
	var ScriptDataEndTagName                    = 18;
	var ScriptDataEscapeStart                   = 19;
	var ScriptDataEscapeStartDash               = 20;
	var ScriptDataEscaped                       = 21;
	var ScriptDataEscapedDash                   = 22;
	var ScriptDataEscapedDashDash               = 23;
	var ScriptDataEscapedLessthanSign           = 24;
	var ScriptDataEscapedEndTagOpen             = 25;
	var ScriptDataEscapedEndTagName             = 26;
	var ScriptDataDoubleEscapeStart             = 27;
	var ScriptDataDoubleEscaped                 = 28;
	var ScriptDataDoubleEscapedDash             = 29;
	var ScriptDataDoubleEscapedDashDash         = 30;
	var ScriptDataDoubleEscapedLessthanSign     = 31;
	var ScriptDataDoubleEscapeEnd               = 32;
	var BeforeAttributeName                     = 33;
	var AttributeName                           = 34;
	var AfterAttributeName                      = 35;
	var BeforeAttributeValue                    = 36;
	var AttributeValue_doubleQuoted             = 37;
	var AttributeValue_singleQuoted             = 38;
	var AttributeValue_unquoted                 = 39;
	var AfterAttributeValue_quoted              = 40;
	var SelfClosingStartTag                     = 41;
	var BogusComment                            = 42;
	var MarkupDeclarationOpen                   = 43;
	var CommentStart                            = 44;
	var CommentStartDash                        = 45;
	var Comment                                 = 46;
	var CommentEndDash                          = 47;
	var CommentEnd                              = 48;
	var CommentEndBang                          = 49;
	var Doctype                                 = 50;
	var BeforeDoctypeName                       = 51;
	var DoctypeName                             = 52;
	var AfterDoctypeName                        = 53;
	var AfterDoctypePublicKeyword               = 54;
	var BeforeDoctypePublicIdentifier           = 55;
	var DoctypePublicIdentifier_doubleQuoted    = 56;
	var DoctypePublicIdentifier_singleQuoted    = 57;
	var AfterDoctypePublicIdentifier            = 58;
	var BetweenDoctypePublicAndSystemIdentifiers= 59;
	var AfterDoctypeSystemKeyword               = 60;
	var BeforeDoctypeSystemIdentifier           = 61;
	var DoctypeSystemIdentifier_doubleQuoted    = 62;
	var DoctypeSystemIdentifier_singleQuoted    = 63;
	var AfterDoctypeSystemIdentifier            = 64;
	var BogusDoctype                            = 65;
	var CdataSection                            = 66;
	

	//NOTE(az): the BIG SWITCH!!
	public function read(t:Tokeniser, r:CharacterReader):Void {
	
		switch(this) {
			
			case TokeniserState.Data:
				// in data state, gather characters until a character reference or tag is found
				switch (r.current()) {
					case '&'.code:
						t.advanceTransition(CharacterReferenceInData);
					case '<'.code:
						t.advanceTransition(TagOpen);
					case nullChar:
						t.errorState(cast this); // NOT replacement character (oddly?)
						t.emitCodePoint(r.consume());
					case eof:
						t.emit(new TokenEOF());
					default:
						var data:String = r.consumeData();
						t.emitString(data);
				}

			case TokeniserState.CharacterReferenceInData:
				// from & in data
				var c:Array<CodePoint> = t.consumeCharacterReference(null, false);
				if (c == null)
					t.emitCodePoint('&'.code);
				else
					t.emitString(c.uToString());
				t.transition(Data);

			case TokeniserState.Rcdata:
				/// handles data in title, textarea etc
				switch (r.current()) {
					case '&'.code:
						t.advanceTransition(CharacterReferenceInRcdata);
					case '<'.code:
						t.advanceTransition(RcdataLessthanSign);
					case nullChar:
						t.error(cast this);
						r.advance();
						t.emitCodePoint(replacementChar);
					case eof:
						t.emit(new TokenEOF());
					default:
						var data:String = r.consumeToAny(['&'.code, '<'.code, nullChar]);
						t.emitString(data);
				}

			case TokeniserState.CharacterReferenceInRcdata:
				var c:Array<CodePoint> = t.consumeCharacterReference(null, false);
				if (c == null)
					t.emitCodePoint('&'.code);
				else
					t.emitString(c.toString());
				t.transition(Rcdata);
	
			case TokeniserState.Rawtext:
				switch (r.current()) {
					case '<'.code:
						t.advanceTransition(RawtextLessthanSign);
					case nullChar:
						t.errorState(cast this);
						r.advance();
						t.emitCodePoint(replacementChar);
					case eof:
						t.emit(new TokenEOF());
					default:
						var data:String = r.consumeToAny(['<'.code, nullChar]);
						t.emitString(data);
				}
			
			case TokeniserState.ScriptData:
				switch (r.current()) {
					case '<'.code:
						t.advanceTransition(ScriptDataLessthanSign);
					case nullChar:
						t.errorState(cast this);
						r.advance();
						t.emitCodePoint(replacementChar);
					case eof:
						t.emit(new TokenEOF());
					default:
						var data:String = r.consumeToAny(['<'.code, nullChar]);
						t.emitString(data);
				}
			
			case TokeniserState.PLAINTEXT:
				switch (r.current()) {
					case nullChar:
						t.errorState(cast this);
						r.advance();
						t.emitCodePoint(replacementChar);
					case eof:
						t.emit(new TokenEOF());
					default:
						var data:String = r.consumeTo(nullChar);
						t.emitString(data);
				}
			
			case TokeniserState.TagOpen:
				// from < in data
				switch (r.current()) {
					case '!'.code:
						t.advanceTransition(MarkupDeclarationOpen);
					case '/'.code:
						t.advanceTransition(EndTagOpen);
					case '?'.code:
						t.advanceTransition(BogusComment);
					default:
						if (r.matchesLetter()) {
							t.createTagPending(true);
							t.transition(TagName);
						} else {
							t.errorState(cast this);
							t.emitCodePoint('<'.code); // char that got us here
							t.transition(Data);
						}
				}

			case TokeniserState.EndTagOpen:
				if (r.isEmpty()) {
					t.eofError(cast this);
					t.emitString("</");
					t.transition(Data);
				} else if (r.matchesLetter()) {
					t.createTagPending(false);
					t.transition(TagName);
				} else if (r.matches('>'.code)) {
					t.errorState(cast this);
					t.advanceTransition(Data);
				} else {
					t.errorState(cast this);
					t.advanceTransition(BogusComment);
				}
			
			case TokeniserState.TagName:
				// from < or </ in data, will have start or end tag pending
				// previous TagOpen state did NOT consume, will have a letter char in current
				//String tagName = r.consumeToAnySorted(tagCharsSorted).toLowerCase();
				var tagName:String = r.consumeTagName().toLowerCase();
				t.tagPending.appendTagName(tagName);

				switch (r.consume()) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(BeforeAttributeName);
					case '/'.code:
						t.transition(SelfClosingStartTag);
					case '>'.code:
						t.emitTagPending();
						t.transition(Data);
					case nullChar: // replacement
						t.tagPending.appendTagName(replacementStr);
					case eof: // should emit pending tag?
						t.eofError(cast this);
						t.transition(Data);
					// no default, as covered with above consumeToAny
				}

			case TokeniserState.RcdataLessthanSign:
				// from < in rcdata
				if (r.matches('/'.code)) {
					t.createTempBuffer();
					t.advanceTransition(RCDATAEndTagOpen);
				} else if (r.matchesLetter() && t.appropriateEndTagName() != null && !r.containsIgnoreCase("</" + t.appropriateEndTagName())) {
					// diverge from spec: got a start tag, but there's no appropriate end tag (</title>), so rather than
					// consuming to EOF; break out here
					t.tagPending = t.createTagPending(false).setName(t.appropriateEndTagName());
					t.emitTagPending();
					r.unconsume(); // undo "<"
					t.transition(Data);
				} else {
					t.emitString("<");
					t.transition(Rcdata);
				}

			case TokeniserState.RCDATAEndTagOpen:
				if (r.matchesLetter()) {
					t.createTagPending(false);
					t.tagPending.appendTagName(CodePoint.fromInt(r.current()).toString().toLowerCase());
					t.dataBuffer.add(CodePoint.fromInt(r.current()).toString().toLowerCase());
					t.advanceTransition(RCDATAEndTagName);
				} else {
					t.emitString("</");
					t.transition(Rcdata);
				}
			
			case TokeniserState.RCDATAEndTagName:
			
				//NOTE(az): inline fun
				inline function anythingElse(t:Tokeniser, r:CharacterReader) {
					t.emitString("</" + t.dataBuffer.toString());
					r.unconsume();
					t.transition(Rcdata);
				}
			
				if (r.matchesLetter()) {
					var name:String = r.consumeLetterSequence();
					t.tagPending.appendTagName(name.toLowerCase());
					t.dataBuffer.add(name);
					return;
				}

				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						if (t.isAppropriateEndTagToken())
							t.transition(BeforeAttributeName);
						else
							anythingElse(t, r);
					case '/'.code:
						if (t.isAppropriateEndTagToken())
							t.transition(SelfClosingStartTag);
						else
							anythingElse(t, r);
					case '>'.code:
						if (t.isAppropriateEndTagToken()) {
							t.emitTagPending();
							t.transition(Data);
						}
						else
							anythingElse(t, r);
					default:
						anythingElse(t, r);
				}

			case TokeniserState.RawtextLessthanSign:
				if (r.matches('/'.code)) {
					t.createTempBuffer();
					t.advanceTransition(RawtextEndTagOpen);
				} else {
					t.emitCodePoint('<'.code);
					t.transition(Rawtext);
				}
				
			case TokeniserState.RawtextEndTagOpen:
				if (r.matchesLetter()) {
					t.createTagPending(false);
					t.transition(RawtextEndTagName);
				} else {
					t.emitString("</");
					t.transition(Rawtext);
				}
				
			case TokeniserState.RawtextEndTagName:
				handleDataEndTag(t, r, Rawtext);
				
			case TokeniserState.ScriptDataLessthanSign:
				switch (r.consume()) {
					case '/'.code:
						t.createTempBuffer();
						t.transition(ScriptDataEndTagOpen);
					case '!'.code:
						t.emitString("<!");
						t.transition(ScriptDataEscapeStart);
					default:
						t.emitString("<");
						r.unconsume();
						t.transition(ScriptData);
				}
			
			case TokeniserState.ScriptDataEndTagOpen:
				if (r.matchesLetter()) {
					t.createTagPending(false);
					t.transition(ScriptDataEndTagName);
				} else {
					t.emitString("</");
					t.transition(ScriptData);
				}

			case TokeniserState.ScriptDataEndTagName:
				handleDataEndTag(t, r, ScriptData);
			
			case TokeniserState.ScriptDataEscapeStart:
				if (r.matches('-'.code)) {
					t.emitCodePoint('-'.code);
					t.advanceTransition(ScriptDataEscapeStartDash);
				} else {
					t.transition(ScriptData);
				}
			
			case TokeniserState.ScriptDataEscapeStartDash:
				if (r.matches('-'.code)) {
					t.emitCodePoint('-'.code);
					t.advanceTransition(ScriptDataEscapedDashDash);
				} else {
					t.transition(ScriptData);
				}
			
			case TokeniserState.ScriptDataEscaped:
			
				if (r.isEmpty()) {
					t.eofError(cast this);
					t.transition(Data);
					return;
				}

				switch (r.current()) {
					case '-'.code:
						t.emitCodePoint('-'.code);
						t.advanceTransition(ScriptDataEscapedDash);
					case '<'.code:
						t.advanceTransition(ScriptDataEscapedLessthanSign);
					case nullChar:
						t.errorState(cast this);
						r.advance();
						t.emitCodePoint(replacementChar);
					default:
						var data:String = r.consumeToAny(['-'.code, '<'.code, nullChar]);
						t.emitString(data);
				}

			case TokeniserState.ScriptDataEscapedDash:
				if (r.isEmpty()) {
					t.eofError(cast this);
					t.transition(Data);
					return;
				}

				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.emitCodePoint(c);
						t.transition(ScriptDataEscapedDashDash);
					case '<'.code:
						t.transition(ScriptDataEscapedLessthanSign);
					case nullChar:
						t.errorState(cast this);
						t.emitCodePoint(replacementChar);
						t.transition(ScriptDataEscaped);
					default:
						t.emitCodePoint(c);
						t.transition(ScriptDataEscaped);
				}
			
			case TokeniserState.ScriptDataEscapedDashDash:
				if (r.isEmpty()) {
					t.eofError(cast this);
					t.transition(Data);
					return;
				}

				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.emitCodePoint(c);
					case '<'.code:
						t.transition(ScriptDataEscapedLessthanSign);
					case '>'.code:
						t.emitCodePoint(c);
						t.transition(ScriptData);
					case nullChar:
						t.errorState(cast this);
						t.emitCodePoint(replacementChar);
						t.transition(ScriptDataEscaped);
					default:
						t.emitCodePoint(c);
						t.transition(ScriptDataEscaped);
				}
			
			case TokeniserState.ScriptDataEscapedLessthanSign:
				if (r.matchesLetter()) {
					t.createTempBuffer();
					t.dataBuffer.add(CodePoint.fromInt(r.current()).toString().toLowerCase());
					t.emitString("<" + CodePoint.fromInt(r.current()).toString());
					t.advanceTransition(ScriptDataDoubleEscapeStart);
				} else if (r.matches('/'.code)) {
					t.createTempBuffer();
					t.advanceTransition(ScriptDataEscapedEndTagOpen);
				} else {
					t.emitCodePoint('<'.code);
					t.transition(ScriptDataEscaped);
				}
			
			case TokeniserState.ScriptDataEscapedEndTagOpen:
				if (r.matchesLetter()) {
					t.createTagPending(false);
					t.tagPending.appendTagName(CodePoint.fromInt(r.current()).toString().toLowerCase());
					t.dataBuffer.addChar(r.current());
					t.advanceTransition(ScriptDataEscapedEndTagName);
				} else {
					t.emitString("</");
					t.transition(ScriptDataEscaped);
				}
			
			case TokeniserState.ScriptDataEscapedEndTagName:
				handleDataEndTag(t, r, ScriptDataEscaped);
			
			case TokeniserState.ScriptDataDoubleEscapeStart:
				handleDataDoubleEscapeTag(t, r, ScriptDataDoubleEscaped, ScriptDataEscaped);
			
			case TokeniserState.ScriptDataDoubleEscaped:
				var c:Int = r.current();
				switch (c) {
					case '-'.code:
						t.emitCodePoint(c);
						t.advanceTransition(ScriptDataDoubleEscapedDash);
					case '<'.code:
						t.emitCodePoint(c);
						t.advanceTransition(ScriptDataDoubleEscapedLessthanSign);
					case nullChar:
						t.errorState(cast this);
						r.advance();
						t.emitCodePoint(replacementChar);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					default:
						var data:String = r.consumeToAny(['-'.code, '<'.code, nullChar]);
						t.emitString(data);
				}

			case TokeniserState.ScriptDataDoubleEscapedDash:
				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.emitCodePoint(c);
						t.transition(ScriptDataDoubleEscapedDashDash);
					case '<'.code:
						t.emitCodePoint(c);
						t.transition(ScriptDataDoubleEscapedLessthanSign);
					case nullChar:
						t.errorState(cast this);
						t.emitCodePoint(replacementChar);
						t.transition(ScriptDataDoubleEscaped);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					default:
						t.emitCodePoint(c);
						t.transition(ScriptDataDoubleEscaped);
				}
			
			case TokeniserState.ScriptDataDoubleEscapedDashDash:
				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.emitCodePoint(c);
					case '<'.code:
						t.emitCodePoint(c);
						t.transition(ScriptDataDoubleEscapedLessthanSign);
					case '>'.code:
						t.emitCodePoint(c);
						t.transition(ScriptData);
					case nullChar:
						t.errorState(cast this);
						t.emitCodePoint(replacementChar);
						t.transition(ScriptDataDoubleEscaped);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					default:
						t.emitCodePoint(c);
						t.transition(ScriptDataDoubleEscaped);
				}
			
			case TokeniserState.ScriptDataDoubleEscapedLessthanSign:
				if (r.matches('/'.code)) {
					t.emitCodePoint('/'.code);
					t.createTempBuffer();
					t.advanceTransition(ScriptDataDoubleEscapeEnd);
				} else {
					t.transition(ScriptDataDoubleEscaped);
				}
			
			case TokeniserState.ScriptDataDoubleEscapeEnd:
				handleDataDoubleEscapeTag(t,r, ScriptDataEscaped, ScriptDataDoubleEscaped);
			
			case TokeniserState.BeforeAttributeName:
				// from tagname <xxx
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case '/'.code:
						t.transition(SelfClosingStartTag);
					case '>'.code:
						t.emitTagPending();
						t.transition(Data);
					case nullChar:
						t.errorState(cast this);
						t.tagPending.newAttribute();
						r.unconsume();
						t.transition(AttributeName);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					case '"'.code, "'".code, '<'.code, '='.code:
						t.errorState(cast this);
						t.tagPending.newAttribute();
						t.tagPending.appendAttributeName(c.asCodePoint().toString());
						t.transition(AttributeName);
					default: // A-Z, anything else
						t.tagPending.newAttribute();
						r.unconsume();
						t.transition(AttributeName);
				}

			case TokeniserState.AttributeName:
				// from before attribute name
				var name:String = r.consumeToAnySorted(attributeNameCharsSorted);
				t.tagPending.appendAttributeName(name.toLowerCase());

				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(AfterAttributeName);
					case '/'.code:
						t.transition(SelfClosingStartTag);
					case '='.code:
						t.transition(BeforeAttributeValue);
					case '>'.code:
						t.emitTagPending();
						t.transition(Data);
					case nullChar:
						t.errorState(cast this);
						t.tagPending.appendAttributeName(replacementChar.toString());
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					case '"'.code, "'".code, '<'.code:
						t.errorState(cast this);
						t.tagPending.appendAttributeName(c.asCodePoint().toString());
					// no default, as covered in consumeToAny
				}

			case TokeniserState.AfterAttributeName:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						// ignore
					case '/'.code:
						t.transition(SelfClosingStartTag);
					case '='.code:
						t.transition(BeforeAttributeValue);
					case '>'.code:
						t.emitTagPending();
						t.transition(Data);
					case nullChar:
						t.errorState(cast this);
						t.tagPending.appendAttributeName(replacementChar.toString());
						t.transition(AttributeName);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					case '"'.code, "'".code, '<'.code:
						t.errorState(cast this);
						t.tagPending.newAttribute();
						t.tagPending.appendAttributeName(c.asCodePoint().toString());
						t.transition(AttributeName);
					default: // A-Z, anything else
						t.tagPending.newAttribute();
						r.unconsume();
						t.transition(AttributeName);
				}
			
			case TokeniserState.BeforeAttributeValue:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case '"'.code:
						t.transition(AttributeValue_doubleQuoted);
					case '&'.code:
						r.unconsume();
						t.transition(AttributeValue_unquoted);
					case "'".code:
						t.transition(AttributeValue_singleQuoted);
					case nullChar:
						t.errorState(cast this);
						t.tagPending.appendAttributeValue(replacementChar.toString());
						t.transition(AttributeValue_unquoted);
					case eof:
						t.eofError(cast this);
						t.emitTagPending();
						t.transition(Data);
					case '>'.code:
						t.errorState(cast this);
						t.emitTagPending();
						t.transition(Data);
					case '<'.code, '='.code, '`'.code:
						t.errorState(cast this);
						t.tagPending.appendAttributeValue(c.asCodePoint().toString());
						t.transition(AttributeValue_unquoted);
					default:
						r.unconsume();
						t.transition(AttributeValue_unquoted);
				}
			
			case TokeniserState.AttributeValue_doubleQuoted:
				var value:String = r.consumeToAnySorted(attributeDoubleValueCharsSorted);
				if (value.length > 0)
					t.tagPending.appendAttributeValue(value);
				else
					t.tagPending.setEmptyAttributeValue();

				var c:Int = r.consume();
				switch (c) {
					case '"'.code:
						t.transition(AfterAttributeValue_quoted);
					case '&'.code:
						var ref:Array<CodePoint> = t.consumeCharacterReference('"'.code, true);
						if (ref != null)
							t.tagPending.appendAttributeValue(ref.toString());
						else
							t.tagPending.appendAttributeValue('&');
					case nullChar:
						t.errorState(cast this);
						t.tagPending.appendAttributeValue(replacementChar.toString());
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					// no default, handled in consume to any above
				}
			
			case TokeniserState.AttributeValue_singleQuoted:
				var value:String = r.consumeToAnySorted(attributeSingleValueCharsSorted);
				if (value.length > 0)
					t.tagPending.appendAttributeValue(value);
				else
					t.tagPending.setEmptyAttributeValue();

				var c:Int = r.consume();
				switch (c) {
					case "'".code:
						t.transition(AfterAttributeValue_quoted);
					case '&'.code:
						var ref:Array<CodePoint> = t.consumeCharacterReference("'".code, true);
						if (ref != null)
							t.tagPending.appendAttributeValue(ref.uToString());
						else
							t.tagPending.appendAttributeValue('&');
					case nullChar:
						t.errorState(cast this);
						t.tagPending.appendAttributeValue(replacementChar.toString());
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					// no default, handled in consume to any above
				}
			
			case TokeniserState.AttributeValue_unquoted:
				var value:String = r.consumeToAny(['\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code, '&'.code, '>'.code, nullChar, '"'.code, "'".code, '<'.code, '='.code, '`'.code]);
				if (value.length > 0)
					t.tagPending.appendAttributeValue(value);

				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(BeforeAttributeName);
					case '&'.code:
						var ref:Array<CodePoint> = t.consumeCharacterReference('>'.code, true);
						if (ref != null)
							t.tagPending.appendAttributeValue(ref.toString());
						else
							t.tagPending.appendAttributeValue('&');
					case '>'.code:
						t.emitTagPending();
						t.transition(Data);
					case nullChar:
						t.errorState(cast this);
						t.tagPending.appendAttributeValue(replacementChar.toString());
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					case '"'.code, "'".code, '<'.code, '='.code, '`'.code:
						t.errorState(cast this);
						t.tagPending.appendAttributeValue(c.asCodePoint().toString());
					// no default, handled in consume to any above
				}

			// CharacterReferenceInAttributeValue state handled inline
			case TokeniserState.AfterAttributeValue_quoted:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*\f*/, ' '.code:
						t.transition(BeforeAttributeName);
					case '/'.code:
						t.transition(SelfClosingStartTag);
					case '>'.code:
						t.emitTagPending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					default:
						t.errorState(cast this);
						r.unconsume();
						t.transition(BeforeAttributeName);
				}

			case TokeniserState.SelfClosingStartTag:
				var c:Int = r.consume();
				switch (c) {
					case '>'.code:
						t.tagPending.selfClosing = true;
						t.emitTagPending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.transition(BeforeAttributeName);
				}
			
			case TokeniserState.BogusComment:
				// todo: handle bogus comment starting from eof. when does that trigger?
				// rewind to capture character that lead us here
				r.unconsume();
				var comment:TokenComment = new TokenComment();
				comment.bogus = true;
				comment.data.add(r.consumeTo('>'.code));
				// todo: replace nullChar with replaceChar
				t.emit(comment);
				t.advanceTransition(Data);
			
			case TokeniserState.MarkupDeclarationOpen:
				if (r.matchConsume("--")) {
					t.createCommentPending();
					t.transition(CommentStart);
				} else if (r.matchConsumeIgnoreCase("DOCTYPE")) {
					t.transition(Doctype);
				} else if (r.matchConsume("[CDATA[")) {
					// todo: should actually check current namepspace, and only non-html allows cdata. until namespace
					// is implemented properly, keep handling as cdata
					//} else if (!t.currentNodeInHtmlNS() && r.matchConsume("[CDATA[")) {
					t.transition(CdataSection);
				} else {
					t.errorState(cast this);
					t.advanceTransition(BogusComment); // advance so this character gets in bogus comment data's rewind
				}
			
			case TokeniserState.CommentStart:
				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.transition(CommentStartDash);
					case nullChar:
						t.errorState(cast this);
						t.commentPending.data.addChar(replacementChar);
						t.transition(Comment);
					case '>'.code:
						t.errorState(cast this);
						t.emitCommentPending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.emitCommentPending();
						t.transition(Data);
					default:
						t.commentPending.data.addChar(c);
						t.transition(Comment);
				}
			
			case TokeniserState.CommentStartDash:
				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.transition(CommentStartDash);
					case nullChar:
						t.errorState(cast this);
						t.commentPending.data.addChar(replacementChar);
						t.transition(Comment);
					case '>'.code:
						t.errorState(cast this);
						t.emitCommentPending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.emitCommentPending();
						t.transition(Data);
					default:
						t.commentPending.data.addChar(c);
						t.transition(Comment);
				}
			
			case TokeniserState.Comment:
				var c:Int = r.current();
				switch (c) {
					case '-'.code:
						t.advanceTransition(CommentEndDash);
					case nullChar:
						t.errorState(cast this);
						r.advance();
						t.commentPending.data.addChar(replacementChar);
					case eof:
						t.eofError(cast this);
						t.emitCommentPending();
						t.transition(Data);
					default:
						t.commentPending.data.add(r.consumeToAny(['-'.code, nullChar]));
				}
			
			case TokeniserState.CommentEndDash:
				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.transition(CommentEnd);
					case nullChar:
						t.errorState(cast this);
						t.commentPending.data.addChar('-'.code);
						t.commentPending.data.addChar(replacementChar);
						t.transition(Comment);
					case eof:
						t.eofError(cast this);
						t.emitCommentPending();
						t.transition(Data);
					default:
						t.commentPending.data.addChar('-'.code);
						t.commentPending.data.addChar(c);
						t.transition(Comment);
				}
			
			case TokeniserState.CommentEnd:
				var c:Int = r.consume();
				switch (c) {
					case '>'.code:
						t.emitCommentPending();
						t.transition(Data);
					case nullChar:
						t.errorState(cast this);
						t.commentPending.data.add("--");
						t.commentPending.data.addChar(replacementChar);
						t.transition(Comment);
					case '!'.code:
						t.errorState(cast this);
						t.transition(CommentEndBang);
					case '-'.code:
						t.errorState(cast this);
						t.commentPending.data.addChar('-'.code);
					case eof:
						t.eofError(cast this);
						t.emitCommentPending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.commentPending.data.add("--");
						t.commentPending.data.addChar(c);
						t.transition(Comment);
				}

			case TokeniserState.CommentEndBang:
				var c:Int = r.consume();
				switch (c) {
					case '-'.code:
						t.commentPending.data.add("--!");
						t.transition(CommentEndDash);
					case '>'.code:
						t.emitCommentPending();
						t.transition(Data);
					case nullChar:
						t.errorState(cast this);
						t.commentPending.data.add("--!");
						t.commentPending.data.addChar(replacementChar);
						t.transition(Comment);
					case eof:
						t.eofError(cast this);
						t.emitCommentPending();
						t.transition(Data);
					default:
						t.commentPending.data.add("--!");
						t.commentPending.data.addChar(c);
						t.transition(Comment);
				}
			
			case TokeniserState.Doctype:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(BeforeDoctypeName);
					case eof:
						t.eofError(cast this);
						// note: fall through to > case
					case '>'.code: // catch invalid <!DOCTYPE>
						t.errorState(cast this);
						t.createDoctypePending();
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.transition(BeforeDoctypeName);
				}
			
			case TokeniserState.BeforeDoctypeName:
				if (r.matchesLetter()) {
					t.createDoctypePending();
					t.transition(DoctypeName);
					return;
				}
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case nullChar:
						t.errorState(cast this);
						t.createDoctypePending();
						t.doctypePending.name.addChar(replacementChar);
						t.transition(DoctypeName);
					case eof:
						t.eofError(cast this);
						t.createDoctypePending();
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.createDoctypePending();
						t.doctypePending.name.addChar(c);
						t.transition(DoctypeName);
				}
			
			case TokeniserState.DoctypeName:
				if (r.matchesLetter()) {
					var name:String = r.consumeLetterSequence();
					t.doctypePending.name.add(name.toLowerCase());
					return;
				}
				var c:Int = r.consume();
				switch (c) {
					case '>'.code:
						t.emitDoctypePending();
						t.transition(Data);
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(AfterDoctypeName);
					case nullChar:
						t.errorState(cast this);
						t.doctypePending.name.addChar(replacementChar);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.doctypePending.name.addChar(c);
				}
			
			case TokeniserState.AfterDoctypeName:
				if (r.isEmpty()) {
					t.eofError(cast this);
					t.doctypePending.forceQuirks = true;
					t.emitDoctypePending();
					t.transition(Data);
					return;
				}
				if (r.matchesAny(['\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code]))
					r.advance(); // ignore whitespace
				else if (r.matches('>'.code)) {
					t.emitDoctypePending();
					t.advanceTransition(Data);
				} else if (r.matchConsumeIgnoreCase("PUBLIC")) {
					t.transition(AfterDoctypePublicKeyword);
				} else if (r.matchConsumeIgnoreCase("SYSTEM")) {
					t.transition(AfterDoctypeSystemKeyword);
				} else {
					t.errorState(cast this);
					t.doctypePending.forceQuirks = true;
					t.advanceTransition(BogusDoctype);
				}

			case TokeniserState.AfterDoctypePublicKeyword:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(BeforeDoctypePublicIdentifier);
					case '"'.code:
						t.errorState(cast this);
						// set public id to empty string
						t.transition(DoctypePublicIdentifier_doubleQuoted);
					case "'".code:
						t.errorState(cast this);
						// set public id to empty string
						t.transition(DoctypePublicIdentifier_singleQuoted);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.transition(BogusDoctype);
				}
			
			case TokeniserState.BeforeDoctypePublicIdentifier:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case '"'.code:
						// set public id to empty string
						t.transition(DoctypePublicIdentifier_doubleQuoted);
					case "'".code:
						// set public id to empty string
						t.transition(DoctypePublicIdentifier_singleQuoted);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.transition(BogusDoctype);
				}
			
			case TokeniserState.DoctypePublicIdentifier_doubleQuoted:
				var c:Int = r.consume();
				switch (c) {
					case '"'.code:
						t.transition(AfterDoctypePublicIdentifier);
					case nullChar:
						t.errorState(cast this);
						t.doctypePending.publicIdentifier.addChar(replacementChar);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.doctypePending.publicIdentifier.addChar(c);
				}
			
			case TokeniserState.DoctypePublicIdentifier_singleQuoted:
				var c:Int = r.consume();
				switch (c) {
					case "'".code:
						t.transition(AfterDoctypePublicIdentifier);
					case nullChar:
						t.errorState(cast this);
						t.doctypePending.publicIdentifier.addChar(replacementChar);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.doctypePending.publicIdentifier.addChar(c);
				}
			
			case TokeniserState.AfterDoctypePublicIdentifier:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(BetweenDoctypePublicAndSystemIdentifiers);
					case '>'.code:
						t.emitDoctypePending();
						t.transition(Data);
					case '"'.code:
						t.errorState(cast this);
						// system id empty
						t.transition(DoctypeSystemIdentifier_doubleQuoted);
					case "'".code:
						t.errorState(cast this);
						// system id empty
						t.transition(DoctypeSystemIdentifier_singleQuoted);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.transition(BogusDoctype);
				}
			
			case TokeniserState.BetweenDoctypePublicAndSystemIdentifiers:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case '>'.code:
						t.emitDoctypePending();
						t.transition(Data);
					case '"'.code:
						t.errorState(cast this);
						// system id empty
						t.transition(DoctypeSystemIdentifier_doubleQuoted);
					case "'".code:
						t.errorState(cast this);
						// system id empty
						t.transition(DoctypeSystemIdentifier_singleQuoted);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.transition(BogusDoctype);
				}
			
			case TokeniserState.AfterDoctypeSystemKeyword:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
						t.transition(BeforeDoctypeSystemIdentifier);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case '"'.code:
						t.errorState(cast this);
						// system id empty
						t.transition(DoctypeSystemIdentifier_doubleQuoted);
					case "'".code:
						t.errorState(cast this);
						// system id empty
						t.transition(DoctypeSystemIdentifier_singleQuoted);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
				}
			
			case TokeniserState.BeforeDoctypeSystemIdentifier:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case '"'.code:
						// set system id to empty string
						t.transition(DoctypeSystemIdentifier_doubleQuoted);
					case "'".code:
						// set public id to empty string
						t.transition(DoctypeSystemIdentifier_singleQuoted);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.transition(BogusDoctype);
				}
			
			case TokeniserState.DoctypeSystemIdentifier_doubleQuoted:
				var c:Int = r.consume();
				switch (c) {
					case '"'.code:
						t.transition(AfterDoctypeSystemIdentifier);
					case nullChar:
						t.errorState(cast this);
						t.doctypePending.systemIdentifier.addChar(replacementChar);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.doctypePending.systemIdentifier.addChar(c);
				}
			
			case TokeniserState.DoctypeSystemIdentifier_singleQuoted:
				var c:Int = r.consume();
				switch (c) {
					case "'".code:
						t.transition(AfterDoctypeSystemIdentifier);
					case nullChar:
						t.errorState(cast this);
						t.doctypePending.systemIdentifier.addChar(replacementChar);
					case '>'.code:
						t.errorState(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.doctypePending.systemIdentifier.addChar(c);
				}
				
			case TokeniserState.AfterDoctypeSystemIdentifier:
				var c:Int = r.consume();
				switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
					case '>'.code:
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.eofError(cast this);
						t.doctypePending.forceQuirks = true;
						t.emitDoctypePending();
						t.transition(Data);
					default:
						t.errorState(cast this);
						t.transition(BogusDoctype);
						// NOT force quirks
				}
			
			case TokeniserState.BogusDoctype:
				var c:Int = r.consume();
				switch (c) {
					case '>'.code:
						t.emitDoctypePending();
						t.transition(Data);
					case eof:
						t.emitDoctypePending();
						t.transition(Data);
					default:
						// ignore char
				}
			
			case TokeniserState.CdataSection:
				var data:String = r.consumeToSeq("]]>");
				t.emitString(data);
				r.matchConsume("]]>");
				t.transition(Data);
				
		} //NOTE(az): end of BIG SWITCH
	}//end of read()


	public static inline var nullChar:Int = 0;
    private static var attributeSingleValueCharsSorted:Array<CodePoint>;
    private static var attributeDoubleValueCharsSorted:Array<CodePoint>;
    private static var attributeNameCharsSorted:Array<CodePoint>;

    private static var replacementChar:CodePoint = Tokeniser.replacementChar;
    private static var replacementStr:String = Tokeniser.replacementChar.toString();
    private static inline var eof:Int = CharacterReader.EOF;

    static function __init__() {
		attributeSingleValueCharsSorted = ["'".code, '&'.code, nullChar];
		attributeDoubleValueCharsSorted = ['"'.code, '&'.code, nullChar];
		attributeNameCharsSorted = ['\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code, '/'.code, '='.code, '>'.code, nullChar, '"'.code, "'".code, '<'.code];
		
        attributeSingleValueCharsSorted.sort(Reflect.compare);
        attributeDoubleValueCharsSorted.sort(Reflect.compare);
        attributeNameCharsSorted.sort(Reflect.compare);
    }

    /**
     * Handles RawtextEndTagName, ScriptDataEndTagName, and ScriptDataEscapedEndTagName. Same body impl, just
     * different else exit transitions.
     */
    private static function handleDataEndTag(t:Tokeniser, r:CharacterReader, elseTransition:TokeniserState):Void {
        if (r.matchesLetter()) {
            var name:String = r.consumeLetterSequence();
            t.tagPending.appendTagName(name.toLowerCase());
            t.dataBuffer.add(name);
            return;
        }

        var needsExitTransition:Bool = false;
        if (t.isAppropriateEndTagToken() && !r.isEmpty()) {
            var c:Int = r.consume();
            switch (c) {
					case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
                    t.transition(BeforeAttributeName);
                case '/'.code:
                    t.transition(SelfClosingStartTag);
                case '>'.code:
                    t.emitTagPending();
                    t.transition(Data);
                default:
                    t.dataBuffer.addChar(c);
                    needsExitTransition = true;
            }
        } else {
            needsExitTransition = true;
        }

        if (needsExitTransition) {
            t.emitString("</" + t.dataBuffer.toString());
            t.transition(elseTransition);
        }
    }

    private static function handleDataDoubleEscapeTag(t:Tokeniser, r:CharacterReader, primary:TokeniserState, fallback:TokeniserState):Void {
        if (r.matchesLetter()) {
			var name:String = r.consumeLetterSequence();
            t.dataBuffer.add(name.toLowerCase());
            t.emitString(name);
            return;
        }

        var c:Int = r.consume();
        switch (c) {
			case '\t'.code, '\n'.code, '\r'.code, 0xC/*'\f'*/, ' '.code: // whitespace
            case '/'.code, '>'.code:
                if (t.dataBuffer.toString() == "script")
                    t.transition(primary);
                else
                    t.transition(fallback);
                t.emitCodePoint(c);
            default:
                r.unconsume();
                t.transition(fallback);
        }
    }

}