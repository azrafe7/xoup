package org.jsoup.nodes;

import org.jsoup.helper.StringUtil;
import org.jsoup.nodes.Document.OutputSettings.*;
import org.jsoup.nodes.Document.Syntax;

/**
 * A {@code <!DOCTYPE>} node.
 */
class DocumentType extends Node {
    private static inline var NAME:String = "name";
    private static inline var PUBLIC_ID:String = "publicId";
    private static inline var SYSTEM_ID:String = "systemId";
    // todo: quirk mode from publicId and systemId

    /**
     * Create a new doctype element.
     * @param name the doctype's name
     * @param publicId the doctype's public ID
     * @param systemId the doctype's system ID
     * @param baseUri the doctype's base URI
     */
    public function new(name:String, publicId:String, systemId:String, baseUri:String) {
        super(baseUri, new Attributes());

        setAttr(NAME, name);
        setAttr(PUBLIC_ID, publicId);
        setAttr(SYSTEM_ID, systemId);
    }

    //@Override
    override public function nodeName():String {
        return "#doctype";
    }

    //@Override
    override function outerHtmlHead(accum:StringBuf, depth:Int, out: Document.OutputSettings):Void {
        if (out.getSyntax() == Syntax.html && !has(PUBLIC_ID) && !has(SYSTEM_ID)) {
            // looks like a html5 doctype, go lowercase for aesthetics
            accum.add("<!doctype");
        } else {
            accum.add("<!DOCTYPE");
        }
        if (has(NAME)) {
            accum.add(" ");
			accum.add(getAttr(NAME));
		}
        if (has(PUBLIC_ID)) {
            accum.add(" PUBLIC \"");
			accum.add(getAttr(PUBLIC_ID));
			accum.add('"');
		}
        if (has(SYSTEM_ID)) {
            accum.add(" \"");
			accum.add(getAttr(SYSTEM_ID));
			accum.add('"');
		}
        accum.add('>');
    }

    //@Override
    override function outerHtmlTail(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void {
    }

    private function has(attribute:String):Bool {
        return !StringUtil.isBlank(getAttr(attribute));
    }
	
	//@Override
    override public function clone():DocumentType {
        return cast super.copyTo(new DocumentType("", "", "", baseUri), null);
    }
}
