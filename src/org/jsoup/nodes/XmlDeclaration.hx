package org.jsoup.nodes;

/**
 An XML Declaration.

 @author Jonathan Hedley, jonathan@hedley.net */
class XmlDeclaration extends Node {
    public static inline var DECL_KEY:String = "declaration";
    private var isProcessingInstruction:Bool; // <! if true, <? if false, declaration (and last data char should be ?)

    /**
     Create a new XML declaration
     @param data data
     @param baseUri base uri
     @param isProcessingInstruction is processing instruction
     */
    public function new(data:String, baseUri:String, isProcessingInstruction:Bool) {
        super(baseUri, new Attributes());
        attributes.put(DECL_KEY, data);
        this.isProcessingInstruction = isProcessingInstruction;
    }

    override public function nodeName():String {
        return "#declaration";
    }

    /**
     Get the unencoded XML declaration.
     @return XML declaration
     */
    public function getWholeDeclaration():String {
        var decl:String = attributes.get(DECL_KEY);
        
        if(decl == "xml" && attributes.size() > 1 ) {
            var sb = new StringBuf(/*decl*/);
			sb.add(decl);
            var version:String = attributes.get("version");
            
            if( version != null ) {
                sb.add(" version=\"");
				sb.add(version);
				sb.add("\"");
            }
            
            var encoding:String = attributes.get("encoding");
            
            if( encoding != null ) {
                sb.add(" encoding=\"");
				sb.add(encoding);
				sb.add("\"");
            }
            
            return sb.toString();
        }
        else {
            return attributes.get(DECL_KEY);
        }
    }
    
    override function outerHtmlHead(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void {
        accum.add("<");
		accum.add(isProcessingInstruction ? "!" : "?");
		accum.add(getWholeDeclaration());
		accum.add(">");
    }

    override function outerHtmlTail(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void {}

    //@Override
    override public function toString():String {
        return outerHtml();
    }
}
