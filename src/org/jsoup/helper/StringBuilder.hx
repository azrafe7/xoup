package org.jsoup.helper;

/**
 * Wraps a StringBuf.
 */
abstract StringBuilder(StringBuilderImpl) {
	
	/**
		The length of `this` StringBuf in characters.
	**/
	public var length(get,never) : Int;

	/**
		Creates a new StringBuf instance.

		This may involve initialization of the internal buffer.
	**/
	inline public function new(?buf:StringBuf = null) {
		this = new StringBuilderImpl(buf);
	}

	inline function get_length() : Int {
		return this.sb.length;
	}

	/**
		Appends the representation of `x` to `this` StringBuf.

		The exact representation of `x` may vary per platform. To get more
		consistent behavior, this function should be called with
		Std.string(x).

		If `x` is null, the String "null" is appended.
	**/
	inline public function add<T>( x : T ) : Void {
		this.sb.add(x);
	}

	/**
		Appends the character identified by `c` to `this` StringBuf.

		If `c` is negative or has another invalid value, the result is
		unspecified.
	**/
	inline public function addChar( c : Int ) : Void {
		this.sb.addChar(c);
	}

	/**
		Appends a substring of `s` to `this` StringBuf.

		This function expects `pos` and `len` to describe a valid substring of
		`s`, or else the result is unspecified. To get more robust behavior,
		`this.add(s.substr(pos,len))` can be used instead.

		If `s` or `pos` are null, the result is unspecified.

		If `len` is omitted or null, the substring ranges from `pos` to the end
		of `s`.
	**/
	inline public function addSub( s : String, pos : Int, ?len : Int) : Void {
		this.sb.addSub(s, pos, len);
	}

	/**
		Returns the content of `this` StringBuf as String.

		The buffer is not emptied by this operation.
	**/
	inline public function toString() : String {
		return this.sb.toString();
	}

	/**
	 * Clears the buffer.
	 */
	inline public function reset() : Void {
		this.sb = new StringBuf();
	}
	
	@:from inline static function fromStringBuf(buf:StringBuf):StringBuilder {
		return new StringBuilder(buf);
	}
	
	@:to inline function toStringBuf():StringBuf {
		return this.sb;
	}
}

@:allow(org.jsoup.helper.StringBuilder)
class StringBuilderImpl {
	
	var sb:StringBuf;
	
	public function new(?buf:StringBuf = null) {
		this.sb = (buf != null) ? buf : new StringBuf();
	}
}