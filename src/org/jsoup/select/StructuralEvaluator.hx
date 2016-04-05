package org.jsoup.select;

import org.jsoup.nodes.Element;

/**
 * Base structural evaluator.
 */
class StructuralEvaluator extends Evaluator {
    var evaluator:Evaluator;

	public function new() {
		super();
	}
	
	override public function toString():String { return "StructuralEvaluator base"; }
}

/*static*/ class StructuralEvaluatorRoot extends Evaluator {
	override public function matches(root:Element, element:Element):Bool {
		return root == element;
	}
	
	override public function toString():String { return "StructuralEvaluatorRoot"; }
}

/*static*/ class StructuralEvaluatorHas extends StructuralEvaluator {
	public function new(evaluator:Evaluator) {
		super();
		this.evaluator = evaluator;
	}

	override public function matches(root:Element, element:Element):Bool {
		for (e in element.getAllElements()) {
			if (e != element && evaluator.matches(root, e))
				return true;
		}
		return false;
	}

	//@Override
	override public function toString():String {
		return ':has($evaluator)';
	}
}

/*static*/ class StructuralEvaluatorNot extends StructuralEvaluator {
	public function new(evaluator:Evaluator) {
		super();
		this.evaluator = evaluator;
	}

	override public function matches(root:Element, node:Element):Bool {
		return !evaluator.matches(root, node);
	}

	//@Override
	override public function toString():String {
		return ':not$evaluator';
	}
}

/*static*/ class StructuralEvaluatorParent extends StructuralEvaluator {
	public function new(evaluator:Evaluator) {
		super();
		this.evaluator = evaluator;
	}

	override public function matches(root:Element, element:Element):Bool {
		if (root == element)
			return false;

		var parent:Element = element.parent();
		while (true) {
			if (evaluator.matches(root, parent))
				return true;
			if (parent == root)
				break;
			parent = parent.parent();
		}
		return false;
	}

	//@Override
	override public function toString():String {
		return ':parent$evaluator';
	}
}

/*static*/ class StructuralEvaluatorImmediateParent extends StructuralEvaluator {
	public function new(evaluator:Evaluator) {
		super();
		this.evaluator = evaluator;
	}

	override public function matches(root:Element, element:Element):Bool {
		if (root == element)
			return false;

		var parent:Element = element.parent();
		return parent != null && evaluator.matches(root, parent);
	}

	//@Override
	override public function toString():String {
		return ':ImmediateParent$evaluator';
	}
}

/*static*/ class StructuralEvaluatorPreviousSibling extends StructuralEvaluator {
	public function new(evaluator:Evaluator) {
		super();
		this.evaluator = evaluator;
	}

	override public function matches(root:Element, element:Element):Bool {
		if (root == element)
			return false;

		var prev:Element = element.previousElementSibling();

		while (prev != null) {
			if (evaluator.matches(root, prev))
				return true;

			prev = prev.previousElementSibling();
		}
		return false;
	}

	//@Override
	override public function toString():String {
		return ':prev*$evaluator';
	}
}

/*static*/ class StructuralEvaluatorImmediatePreviousSibling extends StructuralEvaluator {
	public function new(evaluator:Evaluator) {
		super();
		this.evaluator = evaluator;
	}

	override public function matches(root:Element, element:Element):Bool {
		if (root == element)
			return false;

		var prev:Element = element.previousElementSibling();
		return prev != null && evaluator.matches(root, prev);
	}

	//@Override
	override public function toString():String {
		return ':prev$evaluator';
	}
}
