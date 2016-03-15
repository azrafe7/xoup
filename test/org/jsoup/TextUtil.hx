package org.jsoup;

/**
 Text utils to ease testing

 @author Jonathan Hedley, jonathan@hedley.net */
class TextUtil {
	//todo: make this platform independent
	// line ending
    public static var LE = "\n";

    public static function stripNewlines(text:String):String {
        //text.replaceAll("\\n\\s*", "");
		text = ~/\r?\n\s*/g.replace(text, "");
        return text;
    }
}
