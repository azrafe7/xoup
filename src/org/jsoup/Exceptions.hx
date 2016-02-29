package org.jsoup;

import haxe.CallStack;


class GenericException {

	var message:String;
	var name:String;
	var stackTrace:String;
	
	public function new (message:String = "") {
		this.message = message;
		this.name = Type.getClassName(Type.getClass(this));
		this.stackTrace = getStackTrace();
	}
	
	public function getStackTrace():String {
		return CallStack.toString(CallStack.exceptionStack());
	}
	
	public function toString():String {
		if (message == "") return name;
		else return name + ": " + message;
	}
}


class IllegalArgumentException extends GenericException { }
