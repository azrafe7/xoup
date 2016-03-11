package org.jsoup.nodes;

/**
 A data node, for contents of style, script tags etc, where contents should not show in text().

 @author Jonathan Hedley, jonathan@hedley.net */
class DataNode extends Node {
    private static inline var DATA_KEY:String = "data";

    /**
     Create a new DataNode.
     @param data data contents
     @param baseUri base URI
     */
    public function new(data:String, baseUri:String) {
        super(baseUri);
        attributes.put(DATA_KEY, data);
    }

    override public function nodeName():String {
        return "#data";
    }

    /**
     Get the data contents of this node. Will be unescaped and with original new lines, space etc.
     @return data
     */
    public function getWholeData():String {
        return attributes.get(DATA_KEY);
    }

    /**
     * Set the data contents of this node.
     * @param data unencoded data
     * @return this node, for chaining
     */
    public function setWholeData(data:String):DataNode {
        attributes.put(DATA_KEY, data);
        return this;
    }

    override function outerHtmlHead(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void {
        accum.add(getWholeData()); // data is not escaped in return from data nodes, so " in script, style is plain
    }

    override function outerHtmlTail(accum:StringBuf, depth:Int, out:Document.OutputSettings):Void {}

    //@Override
    override public function toString():String {
        return outerHtml();
    }

    /**
     Create a new DataNode from HTML encoded data.
     @param encodedData encoded data
     @param baseUri bass URI
     @return new DataNode
     */
    public static function createFromEncoded(encodedData:String, baseUri:String):DataNode {
        var data:String = Entities.unescape(encodedData);
        return new DataNode(data, baseUri);
    }
}
