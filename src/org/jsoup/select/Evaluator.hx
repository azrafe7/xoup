package org.jsoup.select;

import de.polygonal.ds.List;
import org.jsoup.helper.Validate;
import org.jsoup.nodes.Comment;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.DocumentType;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.XmlDeclaration;
import org.jsoup.select.Evaluator;

using StringTools;

/*import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
*/

/**
 * Evaluates that an element matches the selector.
 */
/*public abstract*/ class Evaluator {
    /*protected*/ function new() {
    }

    /**
     * Test if the element meets the evaluator's requirements.
     *
     * @param root    Root of the matching subtree
     * @param element tested element
     * @return Returns <tt>true</tt> if the requirements are met or
     * <tt>false</tt> otherwise
     */
    public /*abstract*/ function matches(root:Element, element:Element):Bool { throw "Abstract"; }

	public function toString():String { return "Evaluator base"; }
}

/**
 * Evaluator for tag name
 */
/*public static final*/ class EvaluatorTag extends Evaluator {
	private var tagName:String;

	public function new(tagName:String) {
		super();
		this.tagName = tagName;
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return (element.getTagName() == tagName);
	}

	//@Override
	override public function toString():String {
		return '$tagName';
	}
}

/**
 * Evaluator for element id
 */
/*public static final*/ class EvaluatorId extends Evaluator {
	private var id:String;

	public function new(id:String) {
		super();
		this.id = id;
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return id == element.id();
	}

	//@Override
	override public function toString():String {
		return '#$id';
	}

}

/**
 * Evaluator for element class
 */
/*public static final*/ class EvaluatorClass extends Evaluator {
	private var className:String;

	public function new(className:String) {
		super();
		this.className = className;
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return (element.hasClass(className));
	}

	//@Override
	override public function toString():String {
		return '.$className';
	}

}

/**
 * Evaluator for attribute name matching
 */
/*public static final*/ class EvaluatorAttribute extends Evaluator {
	private var key:String;

	public function new(key:String) {
		super();
		this.key = key;
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.hasAttr(key);
	}

	//@Override
	override public function toString():String {
		return '[$key]';
	}

}

/**
 * Evaluator for attribute name prefix matching
 */
/*public static final*/ class EvaluatorAttributeStarting extends Evaluator {
	private var keyPrefix:String;

	public function new(keyPrefix:String) {
		super();
		this.keyPrefix = keyPrefix;
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var values:List<org.jsoup.nodes.Attribute> = element.getAttributes().asList();
		for (attribute in values) {
			if (attribute.getKey().startsWith(keyPrefix))
				return true;
		}
		return false;
	}

	//@Override
	override public function toString():String {
		return '[^$keyPrefix]';
	}

}

/**
 * Evaluator for attribute name/value matching
 */
/*public static final*/ class EvaluatorAttributeWithValue extends EvaluatorAttributeKeyPair {
	public function new(key:String, value:String) {
		super(key, value);
	}

	//@Override
	//NOTE(az): ignorecase
	override public function matches(root:Element, element:Element):Bool {
		return element.hasAttr(key) && value.toLowerCase() == element.getAttr(key).trim().toLowerCase();
	}

	//@Override
	override public function toString():String {
		return '[$key=$value]';
	}

}

/**
 * Evaluator for attribute name != value matching
 */
/*public static final*/ class EvaluatorAttributeWithValueNot extends EvaluatorAttributeKeyPair {
	public function new(key:String, value:String) {
		super(key, value);
	}

	//@Override
	//NOTE(az): ignorecase
	override public function matches(root:Element, element:Element):Bool {
		return !(value.toLowerCase() == element.getAttr(key).toLowerCase());
	}

	//@Override
	override public function toString():String {
		return '[$key!=$value]';
	}

}

/**
 * Evaluator for attribute name/value matching (value prefix)
 */
/*public static final*/ class EvaluatorAttributeWithValueStarting extends EvaluatorAttributeKeyPair {
	public function new(key:String, value:String) {
		super(key, value);
	}

	//@Override
	//NOTE(az): ignorecase
	override public function matches(root:Element, element:Element):Bool {
		return element.hasAttr(key) && element.getAttr(key).toLowerCase().startsWith(value); // value is lower case already
	}

	//@Override
	override public function toString():String {
		return '[$key^=$value]';
	}

}

/**
 * Evaluator for attribute name/value matching (value ending)
 */
/*public static final*/ class EvaluatorAttributeWithValueEnding extends EvaluatorAttributeKeyPair {
	public function new(key:String, value:String) {
		super(key, value);
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.hasAttr(key) && element.getAttr(key).toLowerCase().endsWith(value); // value is lower case
	}

	//@Override
	override public function toString():String {
		return '[$key$$=$value]';
	}

}

/**
 * Evaluator for attribute name/value matching (value containing)
 */
/*public static final*/ class EvaluatorAttributeWithValueContaining extends EvaluatorAttributeKeyPair {
	public function new(key:String, value:String) {
		super(key, value);
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.hasAttr(key) && element.getAttr(key).toLowerCase().indexOf(value) >= 0; // value is lower case
	}

	//@Override
	override public function toString():String {
		return '[$key*=$value]';
	}

}

/**
 * Evaluator for attribute name/value matching (value regex matching)
 */
/*public static final*/ class EvaluatorAttributeWithValueMatching extends Evaluator {
	var key:String;
	var pattern:EReg;

	public function new(key:String, pattern:EReg) {
		super();
		this.key = key.trim().toLowerCase();
		this.pattern = pattern;
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.hasAttr(key) && pattern.match(element.getAttr(key));
	}

	//@Override
	override public function toString():String {
		return '[$key~=$pattern]';
	}

}

/**
 * Abstract evaluator for attribute name/value matching
 */
/*public abstract static*/ class EvaluatorAttributeKeyPair extends Evaluator {
	var key:String;
	var value:String;

	public function new(key:String, value:String) {
		super();
		Validate.notEmpty(key);
		Validate.notEmpty(value);

		this.key = key.trim().toLowerCase();
		if (value.startsWith("\"") && value.endsWith("\"")) {
			value = value.substring(1, value.length-1);
		}
		this.value = value.trim().toLowerCase();
	}
}

/**
 * Evaluator for any / all element matching
 */
/*public static final*/ class EvaluatorAllElements extends Evaluator {

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return true;
	}

	//@Override
	override public function toString():String {
		return "*";
	}
}

/**
 * Evaluator for matching by sibling index number (e {@literal <} idx)
 */
/*public static final*/ class EvaluatorIndexLessThan extends EvaluatorIndexEvaluator {
	public function new(index:Int) {
		super(index);
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.elementSiblingIndex() < index;
	}

	//@Override
	override public function toString():String {
		return ':lt($index)';
	}

}

/**
 * Evaluator for matching by sibling index number (e {@literal >} idx)
 */
/*public static final*/ class EvaluatorIndexGreaterThan extends EvaluatorIndexEvaluator {
	public function new(index:Int) {
		super(index);
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.elementSiblingIndex() > index;
	}

	//@Override
	override public function toString():String {
		return ':gt($index)';
	}

}

/**
 * Evaluator for matching by sibling index number (e = idx)
 */
/*public static final*/ class EvaluatorIndexEquals extends EvaluatorIndexEvaluator {
	public function new(index:Int) {
		super(index);
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return element.elementSiblingIndex() == index;
	}

	//@Override
	override public function toString():String {
		return ':eq($index)';
	}

}

/**
 * Evaluator for matching the last sibling (css :last-child)
 */
/*public static final*/ class EvaluatorIsLastChild extends Evaluator {
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var p:Element = element.parent();
		return p != null && !(Std.is(p, Document)) && element.elementSiblingIndex() == p.children().size-1;
	}
	
	//@Override
	override public function toString():String {
		return ":last-child";
	}
}

/*public static final*/ class EvaluatorIsFirstOfType extends EvaluatorIsNthOfType {
	public function new() {
		super(0,1);
	}
	
	//@Override
	override public function toString():String {
		return ":first-of-type";
	}
}

/*public static final*/ class EvaluatorIsLastOfType extends EvaluatorIsNthLastOfType {
	public function new() {
		super(0,1);
	}
	
	//@Override
	override public function toString():String {
		return ":last-of-type";
	}
}


/*public static abstract*/ class EvaluatorCssNthEvaluator extends Evaluator {
	/*protected final*/ var a:Int;
	var b:Int;
	
	//NOTE(az): first default?
	public function new(a:Int = 0, b:Int) {
		super();
		this.a = a;
		this.b = b;
	}
	/*public CssNthEvaluator(int b) {
		this(0,b);
	}*/
	
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var p:Element = element.parent();
		if (p == null || (Std.is(p, Document))) return false;
		
		var pos:Int = calculatePosition(root, element);
		if (a == 0) return pos == b;
		
		return (pos-b)*a >= 0 && (pos-b)%a==0;
	}
	
	//@Override
	override public function toString():String {
		if (a == 0)
			return ':${getPseudoClass()}($b)';
		if (b == 0)
			return ':${getPseudoClass()}($a)';
		return ':${getPseudoClass()}(${a}n${b})';
	}
	
	/*protected abstract*/ function getPseudoClass():String { throw "Abstract"; }
	/*protected abstract*/ function calculatePosition(root:Element, element:Element):Int { throw "Abstract"; }
}


/**
 * css-compatible Evaluator for :eq (css :nth-child)
 * 
 * @see IndexEquals
 */
/*public static final*/ class EvaluatorIsNthChild extends EvaluatorCssNthEvaluator {

	public function new(a:Int, b:Int) {
		super(a,b);
	}

	override /*protected*/ function calculatePosition(root:Element, element:Element):Int {
		return element.elementSiblingIndex()+1;
	}

	
	override /*protected*/ function getPseudoClass():String {
		return "nth-child";
	}
}

/**
 * css pseudo class :nth-last-child)
 * 
 * @see IndexEquals
 */
/*public static final*/ class EvaluatorIsNthLastChild extends EvaluatorCssNthEvaluator {
	public function new(a:Int, b:Int) {
		super(a,b);
	}

	//@Override
	override /*protected*/ function calculatePosition(root:Element, element:Element):Int {
		return element.parent().children().size - element.elementSiblingIndex();
	}
	
	//@Override
	override /*protected*/ function getPseudoClass():String {
		return "nth-last-child";
	}
}

/**
 * css pseudo class nth-of-type
 * 
 */
/*public static*/ class EvaluatorIsNthOfType extends EvaluatorCssNthEvaluator {
	public function new(a:Int, b:Int) {
		super(a,b);
	}

	override /*protected*/ function calculatePosition(root:Element, element:Element):Int {
		var pos:Int = 0;
		var family:Elements = element.parent().children();
		for (i in 0...family.size) {
			if (family.get(i).getTag().equals(element.getTag())) pos++;
			if (family.get(i) == element) break;
		}
		return pos;
	}

	//@Override
	override /*protected*/ function getPseudoClass():String {
		return "nth-of-type";
	}
}

/*public static*/ class EvaluatorIsNthLastOfType extends EvaluatorCssNthEvaluator {

	public function new(a:Int, b:Int) {
		super(a, b);
	}
	
	//@Override
	override /*protected*/ function calculatePosition(root:Element, element:Element):Int {
		var pos:Int = 0;
		var family:Elements = element.parent().children();
		for (i in element.elementSiblingIndex()...family.size) {
			if (family.get(i).getTag().equals(element.getTag())) pos++;
		}
		return pos;
	}

	//@Override
	override /*protected*/ function getPseudoClass():String {
		return "nth-last-of-type";
	}
}

/**
 * Evaluator for matching the first sibling (css :first-child)
 */
/*public static final*/ class EvaluatorIsFirstChild extends Evaluator {
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var p:Element = element.parent();
		return p != null && !(Std.is(p, Document)) && element.elementSiblingIndex() == 0;
	}
	
	//@Override
	override public function toString():String {
		return ":first-child";
	}
}

/**
 * css3 pseudo-class :root
 * @see <a href="http://www.w3.org/TR/selectors/#root-pseudo">:root selector</a>
 *
 */
/*public static final*/ class EvaluatorIsRoot extends Evaluator {
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var r:Element = Std.is(root, Document) ? root.child(0) : root;
		return element == r;
	}
	
	//@Override
	override public function toString():String {
		return ":root";
	}
}

/*public static final*/ class EvaluatorIsOnlyChild extends Evaluator {
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var p:Element = element.parent();
		return p!=null && !(Std.is(p, Document)) && element.siblingElements().size == 0;
	}
	
	//@Override
	override public function toString():String {
		return ":only-child";
	}
}

/*public static final*/ class EvaluatorIsOnlyOfType extends Evaluator {
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var p:Element = element.parent();
		if (p==null || Std.is(p, Document)) return false;
		
		var pos:Int = 0;
		var family:Elements = p.children();
		for (i in 0...family.size) {
			if (family.get(i).getTag().equals(element.getTag())) pos++;
		}
		return pos == 1;
	}
	
	//@Override
	override public function toString():String {
		return ":only-of-type";
	}
}

/*public static final*/ class EvaluatorIsEmpty extends Evaluator {
	//@Override
	override public function matches(root:Element, element:Element):Bool {
		var family:List<Node> = element.getChildNodes();
		for (i in 0...family.size) {
			var n:Node = family.get(i);
			if (!(Std.is(n, Comment) || Std.is(n, XmlDeclaration) || Std.is(n, DocumentType))) return false; 
		}
		return true;
	}
	
	//@Override
	override public function toString():String {
		return ":empty";
	}
}

/**
 * Abstract evaluator for sibling index matching
 *
 * @author ant
 */
/*public abstract static*/ class EvaluatorIndexEvaluator extends Evaluator {
	var index:Int;

	public function new(index:Int) {
		super();
		this.index = index;
	}
}

/**
 * Evaluator for matching Element (and its descendants) text
 */
/*public static final*/ class EvaluatorContainsText extends Evaluator {
	private var searchText:String;

	public function new(searchText:String) {
		super();
		this.searchText = searchText.toLowerCase();
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return (element.getText().toLowerCase().indexOf(searchText) >= 0);
	}

	//@Override
	override public function toString():String {
		return ':contains($searchText';
	}
}

/**
 * Evaluator for matching Element's own text
 */
/*public static final*/ class EvaluatorContainsOwnText extends Evaluator {
	private var searchText:String;

	public function new(searchText:String) {
		super();
		this.searchText = searchText.toLowerCase();
	}

	//@Override
	override public function matches(root:Element, element:Element):Bool {
		return (element.ownText().toLowerCase().indexOf(searchText) >= 0);
	}

	//@Override
	override public function toString():String {
		return ':containsOwn($searchText';
	}
}

/**
 * Evaluator for matching Element (and its descendants) text with regex
 */
/*public static final*/ class EvaluatorMatches extends Evaluator {
	private var pattern:EReg;

	public function new(pattern:EReg) {
		super();
		this.pattern = pattern;
	}

	//@Override
	//NOTE(az): Matcher.find
	override public function matches(root:Element, element:Element):Bool {
		return pattern.match(element.getText());
	}

	//@Override
	override public function toString():String {
		return ':matches($pattern';
	}
}

/**
 * Evaluator for matching Element's own text with regex
 */
/*public static final*/ class EvaluatorMatchesOwn extends Evaluator {
	private var pattern:EReg;

	public function new(pattern:EReg) {
		super();
		this.pattern = pattern;
	}

	//@Override
	//NOTE(az): Matcher.find
	override public function matches(root:Element, element:Element):Bool {
		return pattern.match(element.ownText());
	}

	//@Override
	override public function toString():String {
		return ':matchesOwn($pattern)';
	}
}
