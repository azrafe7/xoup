package;

import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.system.System;


import org.jsoup.Exceptions;

/**
 * 
 * @author azrafe7
 */
class Main extends Sprite {
	
	public function new () 
	{
		super();
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		throw new IllegalArgumentException("fail");
	}
	
	public function onKeyDown(e:KeyboardEvent):Void 
	{
		if (e.keyCode == 27) {
		#if (flash || html5)
			System.exit(1);
		#else
			Sys.exit(1);
		#end
		}
	}
}