package org.jsoup;

import de.polygonal.ds.Collection;
import org.jsoup.helper.StringBuilder;
import unifill.CodePoint;

using StringTools;
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
	
	// NOTE(az): hacky workaround for js (which doesn't support inline modifiers like (?i) in regexps)
	@:noUsing
	inline static public function jsRegexpHack(pattern:String):EReg {
		return (pattern.startsWith("(?i)")) ? new EReg(pattern.substr(4), "i") : new EReg(pattern, "");
	}
}