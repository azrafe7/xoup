package org.jsoup.select;

import de.polygonal.ds.ArrayList;
import org.jsoup.helper.StringUtil;
import org.jsoup.nodes.Element;

/*import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
*/


/**
 * Base combining (and, or) evaluator.
 */
/*abstract*/ class CombiningEvaluator extends Evaluator {
    var evaluators:ArrayList<Evaluator>;
    var num:Int = 0;

    //NOTE(az): merge with below
	function new(evaluators:Iterable<Evaluator> = null) {
        super();
        this.evaluators = new ArrayList<Evaluator>();
		if (evaluators != null) {
			for (e in evaluators) this.evaluators.add(e);
			updateNumEvaluators();
		}
    }

	/*
    CombiningEvaluator(Collection<Evaluator> evaluators) {
        this();
        this.evaluators.addAll(evaluators);
        updateNumEvaluators();
    }*/

    function rightMostEvaluator():Evaluator {
        return num > 0 ? evaluators.get(num - 1) : null;
    }
    
    function replaceRightMostEvaluator(replacement:Evaluator):Void {
        evaluators.set(num - 1, replacement);
    }

    function updateNumEvaluators() {
        // used so we don't need to bash on size() for every match test
        num = evaluators.size;
    }

}


/*static final*/ class CombiningEvaluatorAnd extends CombiningEvaluator {
	function new(evaluators:Iterable<Evaluator>) {
		super(evaluators);
	}

	/*
	And(Evaluator... evaluators) {
		this(Arrays.asList(evaluators));
	}*/

	//@Override
	override public function matches(root:Element, node:Element):Bool {
		for (i in 0...num) {
			var s:Evaluator = evaluators.get(i);
			if (!s.matches(root, node))
				return false;
		}
		return true;
	}

	//@Override
	public function toString():String {
		return StringUtil.join(evaluators, " ");
	}
}

/*static final*/ class CombiningEvaluatorOr extends CombiningEvaluator {
	/**
	 * Create a new Or evaluator. The initial evaluators are ANDed together and used as the first clause of the OR.
	 * @param evaluators initial OR clause (these are wrapped into an AND evaluator).
	 */
	//NOTE(az): with below
	function new(evaluators:Iterable<Evaluator> = null) {
		super();
		if (evaluators == null) evaluators = [];
		if (num > 1)
			this.evaluators.add(new CombiningEvaluatorAnd(evaluators));
		else // 0 or 1
			for (e in evaluators) this.evaluators.add(e);
			
		updateNumEvaluators();
	}

	/*
	Or() {
		super();
	}*/

	public function add(e:Evaluator):Void {
		evaluators.add(e);
		updateNumEvaluators();
	}

	//@Override
	override public function matches(root:Element, node:Element):Bool {
		for (i in 0...num) {
			var s:Evaluator = evaluators.get(i);
			if (s.matches(root, node))
				return true;
		}
		return false;
	}

	//@Override
	public function toString():String {
		return ':or$evaluators';
	}
}
