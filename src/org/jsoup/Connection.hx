package org.jsoup;

//NOTE(az): dummy


interface Connection {
	
}

/**
 * A Key Value tuple.
 */
interface KeyVal {

	/**
	 * Update the key of a keyval
	 * @param key new key
	 * @return this KeyVal, for chaining
	 */
	//NOTE(az): setter
	function setKey(key:String):KeyVal;

	/**
	 * Get the key of a keyval
	 * @return the key
	 */
	//NOTE(az): getter
	function getKey():String;

	/**
	 * Update the value of a keyval
	 * @param value the new value
	 * @return this KeyVal, for chaining
	 */
	//NOTE(az): setter
	function setValue(value:String):KeyVal;

	/**
	 * Get the value of a keyval
	 * @return the value
	 */
	//NOTE(az): getter
	function getValue():String;
	
	function toString():String;
}

