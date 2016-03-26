package org.jsoup;

import de.polygonal.ds.Collection;
import org.jsoup.helper.StringBuilder;
import unifill.CodePoint;

using unifill.Unifill;

class InternalTools {

	static public function toString(arrayCP:Array<CodePoint>):String {
		var sb = new StringBuilder();
		for (cp in arrayCP) sb.uAddChar(cp);
		return sb.toString();
	}
	
	static public function asCodePoint(i:Int):CodePoint {
		return CodePoint.fromInt(i);
	}
}