package org.jsoup;



/*interface Cloneable<T> {
	function clone():T;
}
*/

typedef IterableWithLength<T> = {
	function iterator() : Iterator<T>;
	var length:Int;
}