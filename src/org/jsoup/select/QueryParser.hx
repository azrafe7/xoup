package org.jsoup.select;

import de.polygonal.ds.ArrayList;
import de.polygonal.ds.List;
import org.jsoup.helper.StringBuilder;
import org.jsoup.select.Evaluator;
import org.jsoup.Exceptions.SelectorParseException;
import org.jsoup.select.CombiningEvaluator;
import org.jsoup.select.StructuralEvaluator;
import unifill.CodePoint;

/*import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;*/

import org.jsoup.helper.StringUtil;
import org.jsoup.helper.Validate;
import org.jsoup.parser.TokenQueue;

using StringTools;

/**
 * Parses a CSS selector into an Evaluator tree.
 */
@:access(org.jsoup.select)
class QueryParser {
    private static var combinators:Array<String> = [",", ">", "+", "~", " "];
    private static var AttributeEvals:Array<String> = ["=", "!=", "^=", "$=", "*=", "~="];

    private var tq:TokenQueue;
    private var query:String;
    private var evals:List<Evaluator> = new ArrayList<Evaluator>();

    /**
     * Create a new QueryParser.
     * @param query CSS query
     */
    private function new(query:String) {
        this.query = query;
        this.tq = new TokenQueue(query);
    }

    /**
     * Parse a CSS query into an Evaluator.
     * @param query CSS query
     * @return Evaluator
     */
    public static function parse(query:String):Evaluator {
        var p:QueryParser = new QueryParser(query);
        return p._parse();
    }

    /**
     * Parse the query
     * @return Evaluator
     */
    function _parse():Evaluator {
        tq.consumeWhitespace();

        if (tq.matchesAny(combinators)) { // if starts with a combinator, use root as elements
            evals.add(new StructuralEvaluatorRoot());
            combinator(tq.consume());
        } else {
            findElements();
        }

        while (!tq.isEmpty()) {
            // hierarchy and extras
            var seenWhite:Bool = tq.consumeWhitespace();

            if (tq.matchesAny(combinators)) {
                combinator(tq.consume());
            } else if (seenWhite) {
                combinator(' '.code);
            } else { // E.class, E#id, E[attr] etc. AND
                findElements(); // take next el, #. etc off queue
            }
        }

        if (evals.size == 1)
            return evals.get(0);

        return new CombiningEvaluatorAnd(evals);
    }

    private function combinator(combinator:CodePoint):Void {
        tq.consumeWhitespace();
        var subQuery:String = consumeSubQuery(); // support multi > childs

        var rootEval:Evaluator; // the new topmost evaluator
        var currentEval:Evaluator; // the evaluator the new eval will be combined to. could be root, or rightmost or.
        var newEval:Evaluator = parse(subQuery); // the evaluator to add into target evaluator
        var replaceRightMost:Bool = false;

        if (evals.size == 1) {
            rootEval = currentEval = evals.get(0);
            // make sure OR (,) has precedence:
            if (Std.is(rootEval, CombiningEvaluatorOr) && combinator != ',') {
                currentEval = cast (currentEval, (CombiningEvaluatorOr)).rightMostEvaluator();
                replaceRightMost = true;
            }
        }
        else {
            rootEval = currentEval = new CombiningEvaluatorAnd(evals);
        }
        evals.clear();

        // for most combinators: change the current eval into an AND of the current eval and the new eval
        if (combinator == '>')
            currentEval = new CombiningEvaluatorAnd([newEval, new StructuralEvaluatorImmediateParent(currentEval)]);
        else if (combinator == ' ')
            currentEval = new CombiningEvaluatorAnd([newEval, new StructuralEvaluatorParent(currentEval)]);
        else if (combinator == '+')
            currentEval = new CombiningEvaluatorAnd([newEval, new StructuralEvaluatorImmediatePreviousSibling(currentEval)]);
        else if (combinator == '~')
            currentEval = new CombiningEvaluatorAnd([newEval, new StructuralEvaluatorPreviousSibling(currentEval)]);
        else if (combinator == ',') { // group or.
            var or:CombiningEvaluatorOr;
            if (Std.is(currentEval, CombiningEvaluatorOr)) {
                or = cast currentEval;
                or.add(newEval);
            } else {
                or = new CombiningEvaluatorOr();
                or.add(currentEval);
                or.add(newEval);
            }
            currentEval = or;
        }
        else
            throw new SelectorParseException("Unknown combinator: " + combinator);

        if (replaceRightMost)
            cast(rootEval, (CombiningEvaluatorOr)).replaceRightMostEvaluator(currentEval);
        else rootEval = currentEval;
        evals.add(rootEval);
    }

    private function consumeSubQuery():String {
        var sq = new StringBuilder();
        while (!tq.isEmpty()) {
            if (tq.matches("(")) {
                sq.add("(");
				sq.add(tq.chompBalanced('('.code, ')'.code));
				sq.add(")");
			} else if (tq.matches("[")) {
                sq.add("["); 
				sq.add(tq.chompBalanced('['.code, ']'.code));
				sq.add("]");
            } else if (tq.matchesAny(combinators))
                break;
            else
                sq.add(tq.consume());
        }
        return sq.toString();
    }

    private function findElements():Void {
        if (tq.matchChomp("#"))
            byId();
        else if (tq.matchChomp("."))
            byClass();
        else if (tq.matchesWord())
            byTag();
        else if (tq.matches("["))
            byAttribute();
        else if (tq.matchChomp("*"))
            allElements();
        else if (tq.matchChomp(":lt("))
            indexLessThan();
        else if (tq.matchChomp(":gt("))
            indexGreaterThan();
        else if (tq.matchChomp(":eq("))
            indexEquals();
        else if (tq.matches(":has("))
            has();
        else if (tq.matches(":contains("))
            contains(false);
        else if (tq.matches(":containsOwn("))
            contains(true);
        else if (tq.matches(":matches("))
            matches(false);
        else if (tq.matches(":matchesOwn("))
            matches(true);
        else if (tq.matches(":not("))
            not();
		else if (tq.matchChomp(":nth-child("))
        	cssNthChild(false, false);
        else if (tq.matchChomp(":nth-last-child("))
        	cssNthChild(true, false);
        else if (tq.matchChomp(":nth-of-type("))
        	cssNthChild(false, true);
        else if (tq.matchChomp(":nth-last-of-type("))
        	cssNthChild(true, true);
        else if (tq.matchChomp(":first-child"))
        	evals.add(new EvaluatorIsFirstChild());
        else if (tq.matchChomp(":last-child"))
        	evals.add(new EvaluatorIsLastChild());
        else if (tq.matchChomp(":first-of-type"))
        	evals.add(new EvaluatorIsFirstOfType());
        else if (tq.matchChomp(":last-of-type"))
        	evals.add(new EvaluatorIsLastOfType());
        else if (tq.matchChomp(":only-child"))
        	evals.add(new EvaluatorIsOnlyChild());
        else if (tq.matchChomp(":only-of-type"))
        	evals.add(new EvaluatorIsOnlyOfType());
        else if (tq.matchChomp(":empty"))
        	evals.add(new EvaluatorIsEmpty());
        else if (tq.matchChomp(":root"))
        	evals.add(new EvaluatorIsRoot());
		else // unhandled
            throw new SelectorParseException('Could not parse query "$query": unexpected token at "${tq.remainder()}"');

    }

    private function byId():Void {
        var id:String = tq.consumeCssIdentifier();
        Validate.notEmpty(id);
        evals.add(new EvaluatorId(id));
    }

    private function byClass():Void {
        var className:String = tq.consumeCssIdentifier();
        Validate.notEmpty(className);
        evals.add(new EvaluatorClass(className.trim().toLowerCase()));
    }

    private function byTag():Void {
        var tagName:String = tq.consumeElementSelector();
        Validate.notEmpty(tagName);

        // namespaces: if element name is "abc:def", selector must be "abc|def", so flip:
        if (tagName.indexOf("|") >= 0)
            tagName = tagName.replace("|", ":");

        evals.add(new EvaluatorTag(tagName.trim().toLowerCase()));
    }

    private function byAttribute():Void {
        var cq = new TokenQueue(tq.chompBalanced('['.code, ']'.code)); // content queue
        var key:String = cq.consumeToAny(AttributeEvals); // eq, not, start, end, contain, match, (no val)
        Validate.notEmpty(key);
        cq.consumeWhitespace();

        if (cq.isEmpty()) {
            if (key.startsWith("^"))
                evals.add(new EvaluatorAttributeStarting(key.substring(1)));
            else
                evals.add(new EvaluatorAttribute(key));
        } else {
            if (cq.matchChomp("="))
                evals.add(new EvaluatorAttributeWithValue(key, cq.remainder()));

            else if (cq.matchChomp("!="))
                evals.add(new EvaluatorAttributeWithValueNot(key, cq.remainder()));

            else if (cq.matchChomp("^="))
                evals.add(new EvaluatorAttributeWithValueStarting(key, cq.remainder()));

            else if (cq.matchChomp("$="))
                evals.add(new EvaluatorAttributeWithValueEnding(key, cq.remainder()));

            else if (cq.matchChomp("*="))
                evals.add(new EvaluatorAttributeWithValueContaining(key, cq.remainder()));

            else if (cq.matchChomp("~="))
                evals.add(new EvaluatorAttributeWithValueMatching(key, new EReg(cq.remainder(), ""))); // NOTE(az): Pattern
            else
                throw new SelectorParseException('Could not parse attribute query "$query": unexpected token at "${cq.remainder()}"');
        }
    }

    private function allElements():Void {
        evals.add(new EvaluatorAllElements());
    }

    // pseudo selectors :lt, :gt, :eq
    private function indexLessThan():Void {
        evals.add(new EvaluatorIndexLessThan(consumeIndex()));
    }

    private function indexGreaterThan():Void {
        evals.add(new EvaluatorIndexGreaterThan(consumeIndex()));
    }

    private function indexEquals():Void {
        evals.add(new EvaluatorIndexEquals(consumeIndex()));
    }
    
    //pseudo selectors :first-child, :last-child, :nth-child, ...
    private static var NTH_AB:EReg = new EReg("((\\+|-)?(\\d+)?)n(\\s*(\\+|-)?\\s*\\d+)?", "i"/*Pattern.CASE_INSENSITIVE*/);
    private static var NTH_B:EReg  = new EReg("(\\+|-)?(\\d+)", "");

	//NOTE(az): matchers
	private function cssNthChild(backwards:Bool, ofType:Bool):Void {
		var argS:String = tq.chompTo(")").trim().toLowerCase();
		//Matcher mAB = NTH_AB.matcher(argS);
		var mAB_matches = NTH_AB.match(argS);
		//Matcher mB = NTH_B.matcher(argS);
		var mB_matches = NTH_B.match(argS);
		var a:Int;
		var b:Int;
		if ("odd" == (argS)) {
			a = 2;
			b = 1;
		} else if ("even" == (argS)) {
			a = 2;
			b = 0;
		} else if (mAB_matches) {
			//NOTE(az): these probably need try/catch
			a = NTH_AB.matched(3) != null ? Std.parseInt(new EReg("^\\+", "").replace(NTH_AB.matched(1), "")) : 1;
			b = NTH_AB.matched(4) != null ? Std.parseInt(new EReg("^\\+", "").replace(NTH_AB.matched(4), "")) : 0;
		} else if (mB_matches) {
			a = 0;
			b = Std.parseInt(new EReg("^\\+", "").replace(NTH_B.matched(0), ""));
		} else {
			throw new SelectorParseException('Could not parse nth-index "$argS"');
		}
		if (ofType)
			if (backwards)
				evals.add(new EvaluatorIsNthLastOfType(a, b));
			else
				evals.add(new EvaluatorIsNthOfType(a, b));
		else {
			if (backwards)
				evals.add(new EvaluatorIsNthLastChild(a, b));
			else
				evals.add(new EvaluatorIsNthChild(a, b));
		}
	}

    private function consumeIndex():Int {
        var indexS:String = tq.chompTo(")").trim();
        Validate.isTrue(StringUtil.isNumeric(indexS), "Index must be numeric");
        return Std.parseInt(indexS);
    }

    // pseudo selector :has(el)
    private function has():Void {
        tq.consumeSeq(":has");
        var subQuery:String = tq.chompBalanced('('.code, ')'.code);
        Validate.notEmpty(subQuery, ":has(el) subselect must not be empty");
        evals.add(new StructuralEvaluatorHas(parse(subQuery)));
    }

    // pseudo selector :contains(text), containsOwn(text)
    private function contains(own:Bool):Void {
        tq.consumeSeq(own ? ":containsOwn" : ":contains");
        var searchText:String = TokenQueue.unescape(tq.chompBalanced('('.code, ')'.code));
        Validate.notEmpty(searchText, ":contains(text) query must not be empty");
        if (own)
            evals.add(new EvaluatorContainsOwnText(searchText));
        else
            evals.add(new EvaluatorContainsText(searchText));
    }

    // :matches(regex), matchesOwn(regex)
    private function matches(own:Bool):Void {
        tq.consumeSeq(own ? ":matchesOwn" : ":matches");
        var regex:String = tq.chompBalanced('('.code, ')'.code); // don't unescape, as regex bits will be escaped
        Validate.notEmpty(regex, ":matches(regex) query must not be empty");

        if (own)
            evals.add(new EvaluatorMatchesOwn(new EReg(regex, "")));
        else
			evals.add(new EvaluatorMatches(new EReg(regex, "")));
    }

    // :not(selector)
    private function not():Void {
        tq.consumeSeq(":not");
        var subQuery:String = tq.chompBalanced('('.code, ')'.code);
        Validate.notEmpty(subQuery, ":not(selector) subselect must not be empty");

        evals.add(new StructuralEvaluatorNot(parse(subQuery)));
    }
}
