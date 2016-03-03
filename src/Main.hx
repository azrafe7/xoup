package;

import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.system.System;


import de.polygonal.ds.ArrayList;
import org.jsoup.Exceptions;
import org.jsoup.Interfaces;
import org.jsoup.helper.Validate;
//import org.jsoup.nodes.Node;
import org.jsoup.parser.Tag;
//import org.jsoup.nodes.Element;
import org.jsoup.nodes.Attribute;

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