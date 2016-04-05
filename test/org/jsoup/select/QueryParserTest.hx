package org.jsoup.select;

import org.jsoup.select.CombiningEvaluator.CombiningEvaluatorAnd;
import org.jsoup.select.CombiningEvaluator.CombiningEvaluatorOr;
import org.jsoup.select.Evaluator.EvaluatorTag;
import org.jsoup.select.StructuralEvaluator.StructuralEvaluatorParent;

import utest.Assert;

/*
import org.junit.Test;
import static org.junit.Assert.*;
*/

/**
 * Tests for the Selector Query Parser.
 *
 * @author Jonathan Hedley
 */
@:access(org.jsoup.select.CombiningEvaluator)
class QueryParserTest {
    
	public function new() { }
	
	public function testOrGetsCorrectPrecedence() {
        // tests that a selector "a b, c d, e f" evals to (a AND b) OR (c AND d) OR (e AND f)"
        // top level or, three child ands
        var eval = QueryParser.parse("a b, c d, e f");
        Assert.isTrue(Std.is(eval, CombiningEvaluatorOr));
        var or:CombiningEvaluatorOr = cast eval;
        Assert.equals(3, or.evaluators.size);
        for (innerEval in or.evaluators) {
            Assert.isTrue(Std.is(innerEval, CombiningEvaluatorAnd));
            var and:CombiningEvaluatorAnd = cast innerEval;
            Assert.equals(2, and.evaluators.size);
            Assert.isTrue(Std.is(and.evaluators.get(0), EvaluatorTag));
            Assert.isTrue(Std.is(and.evaluators.get(1), StructuralEvaluatorParent));
        }
    }

    public function testParsesMultiCorrectly() {
        var eval = QueryParser.parse(".foo > ol, ol > li + li");
        Assert.isTrue(Std.is(eval, CombiningEvaluatorOr));
        var or:CombiningEvaluatorOr = cast eval;
        Assert.equals(2, or.evaluators.size);

        var andLeft:CombiningEvaluatorAnd = cast or.evaluators.get(0);
        var andRight:CombiningEvaluatorAnd = cast or.evaluators.get(1);

        Assert.equals("ol :ImmediateParent.foo", andLeft.toString());
        Assert.equals(2, andLeft.evaluators.size);
        Assert.equals("li :prevli :ImmediateParentol", andRight.toString());
        Assert.equals(2, andLeft.evaluators.size);
    }
}
