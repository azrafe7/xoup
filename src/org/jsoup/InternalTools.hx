package org.jsoup;

import de.polygonal.ds.Collection;
import unifill.CodePoint;

using unifill.Unifill;

class InternalTools {

	static public function toString(arrayCP:Array<CodePoint>):String {
		var sb = new StringBuf();
		for (cp in arrayCP) sb.uAddChar(cp);
		return sb.toString();
	}
	
	static public function asCodePoint(i:Int):CodePoint {
		return CodePoint.fromInt(i);
	}
}