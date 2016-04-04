package org.jsoup.helper;

import org.jsoup.Connection;
import org.jsoup.helper.HttpConnection.KeyVal;

//NOTE(az): dummy

class HttpConnection implements Connection {
	
	public function new() { }
}


class KeyVal implements Connection.KeyVal {
	
	public var _key:String;
	public var _val:String;
	
	function new(key:String, val:String) {
		setKey(key);
		setValue(val);
	}
	
	public static function create(key:String, val:String):KeyVal {
		return new KeyVal(key, val);
	}
	
	public function getKey():String {
		return _key;
	}
	
	public function setKey(key:String):KeyVal {
		_key = key;
		return this;
	}
	
	public function getValue():String {
		return _val;
	}
	
	public function setValue(val:String):KeyVal {
		_val = val;
		return this;
	}
	
	public function toString():String {
		return '$_key=$_val';
	}
}