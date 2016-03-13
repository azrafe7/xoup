package org.jsoup.select;

import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.select.Elements;

/**
 * Collects a list of elements that match the supplied criteria.
 *
 * @author Jonathan Hedley
 */
class Collector {

    private function new() {
    }

    /**
     Build a list of elements, by visiting root and every descendant of root, and testing it against the evaluator.
     @param eval Evaluator to test elements against
     @param root root of tree to descend
     @return list of matches; empty if none
     */
    public static function collect(eval:Evaluator, root:Element):Elements {
        var elements:Elements = new Elements();
        new NodeTraversor(new Accumulator(root, elements, eval)).traverse(root);
        return elements;
    }

}

/*private static*/ class Accumulator /*implements NodeVisitor*/ {
	private var root:Element;
	private var elements:Elements;
	private var eval:Evaluator;

	public function new(root:Element, elements:Elements, eval:Evaluator) {
		this.root = root;
		this.elements = elements;
		this.eval = eval;
	}

	public function head(node:Node, depth:Int):Void {
		if (Std.is(node, Element)) {
			var el:Element = cast node;
			if (eval.matches(root, el))
				elements.add(el);
		}
	}

	public function tail(node:Node, depth:Int):Void {
		// void
	}
}
