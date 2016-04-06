package org.jsoup.parser;

import utest.Assert;

/*
import org.junit.Test;
import static org.junit.Assert.*;
*/

/**
 * Token queue tests.
 */
class TokenQueueTest {
	
	public function new() { }
	
    public function testChompBalanced() {
        var tq = new TokenQueue(":contains(one (two) three) four");
        var pre = tq.consumeTo("(");
        var guts = tq.chompBalanced('('.code, ')'.code);
        var remainder = tq.remainder();

        Assert.equals(":contains", pre);
        Assert.equals("one (two) three", guts);
        Assert.equals(" four", remainder);
    }
    
    public function testChompEscapedBalanced() {
        var tq = new TokenQueue(":contains(one (two) \\( \\) \\) three) four");
        var pre = tq.consumeTo("(");
        var guts = tq.chompBalanced('('.code, ')'.code);
        var remainder = tq.remainder();

        Assert.equals(":contains", pre);
        Assert.equals("one (two) \\( \\) \\) three", guts);
        Assert.equals("one (two) ( ) ) three", TokenQueue.unescape(guts));
        Assert.equals(" four", remainder);
    }

    public function testChompBalancedMatchesAsMuchAsPossible() {
        var tq = new TokenQueue("unbalanced(something(or another");
        tq.consumeTo("(");
        var match = tq.chompBalanced('('.code, ')'.code);
        Assert.equals("something(or another", match);
    }
    
    public function testUnescape() {
        Assert.equals("one ( ) \\", TokenQueue.unescape("one \\( \\) \\\\"));
    }
    
    public function testChompToIgnoreCase() {
        var t = "<textarea>one < two </TEXTarea>";
        var tq = new TokenQueue(t);
        var data = tq.chompToIgnoreCase("</textarea");
        Assert.equals("<textarea>one < two ", data);
        
        tq = new TokenQueue("<textarea> one two < three </oops>");
        data = tq.chompToIgnoreCase("</textarea");
        Assert.equals("<textarea> one two < three </oops>", data);
    }

    public function testAddFirst() {
        var tq = new TokenQueue("One Two");
        tq.consumeWord();
        tq.addFirstSeq("Three");
        Assert.equals("Three Two", tq.remainder());
    }
}
