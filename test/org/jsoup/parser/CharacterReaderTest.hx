package org.jsoup.parser;

import org.jsoup.parser.CharacterReader;
import unifill.CodePoint;

import utest.Assert;

/*
import org.junit.Test;

import static org.junit.Assert.*;
*/

/**
 * Test suite for character reader.
 *
 * @author Jonathan Hedley, jonathan@hedley.net
 */
class CharacterReaderTest {

	public function new() { }	
	
    public function testConsume() {
        var r = new CharacterReader("one");
        Assert.equals(0, r.getPos());
        Assert.equals('o'.code, r.current());
        Assert.equals('o'.code, r.consume());
        Assert.equals(1, r.getPos());
        Assert.equals('n'.code, r.current());
        Assert.equals(1, r.getPos());
        Assert.equals('n'.code, r.consume());
        Assert.equals('e'.code, r.consume());
        Assert.isTrue(r.isEmpty());
        Assert.equals(CharacterReader.EOF, r.consume());
        Assert.isTrue(r.isEmpty());
        Assert.equals(CharacterReader.EOF, r.consume());
    }

    public function testUnconsume() {
        var r = new CharacterReader("one");
        Assert.equals('o'.code, r.consume());
        Assert.equals('n'.code, r.current());
        r.unconsume();
        Assert.equals('o'.code, r.current());

        Assert.equals('o'.code, r.consume());
        Assert.equals('n'.code, r.consume());
        Assert.equals('e'.code, r.consume());
        Assert.isTrue(r.isEmpty());
        r.unconsume();
        Assert.isFalse(r.isEmpty());
        Assert.equals('e'.code, r.current());
        Assert.equals('e'.code, r.consume());
        Assert.isTrue(r.isEmpty());

        Assert.equals(CharacterReader.EOF, r.consume());
        r.unconsume();
        Assert.isTrue(r.isEmpty());
        Assert.equals(CharacterReader.EOF, r.current());
    }

    public function testMark() {
        var r = new CharacterReader("one");
        r.consume();
        r.mark();
        Assert.equals('n'.code, r.consume());
        Assert.equals('e'.code, r.consume());
        Assert.isTrue(r.isEmpty());
        r.rewindToMark();
        Assert.equals('n'.code, r.consume());
    }

    public function testConsumeToEnd() {
        var input = "one two three";
        var r = new CharacterReader(input);
        var toEnd = r.consumeToEnd();
        Assert.equals(input, toEnd);
        Assert.isTrue(r.isEmpty());
    }

    public function testNextIndexOfChar() {
        var input = "blah blah";
        var r = new CharacterReader(input);

        Assert.equals(-1, r.nextIndexOf('x'.code));
        Assert.equals(3, r.nextIndexOf('h'.code));
        var pull = r.consumeTo('h'.code);
        Assert.equals("bla", pull);
        r.consume();
        Assert.equals(2, r.nextIndexOf('l'.code));
        Assert.equals(" blah", r.consumeToEnd());
        Assert.equals(-1, r.nextIndexOf('x'.code));
    }

    public function testNextIndexOfString() {
        var input = "One Two something Two Three Four";
        var r = new CharacterReader(input);

        Assert.equals(-1, r.nextIndexOfSeq("Foo"));
        Assert.equals(4, r.nextIndexOfSeq("Two"));
        Assert.equals("One Two ", r.consumeToSeq("something"));
        Assert.equals(10, r.nextIndexOfSeq("Two"));
        Assert.equals("something Two Three Four", r.consumeToEnd());
        Assert.equals(-1, r.nextIndexOfSeq("Two"));
    }

    public function testNextIndexOfUnmatched() {
        var r = new CharacterReader("<[[one]]");
        Assert.equals(-1, r.nextIndexOfSeq("]]>"));
    }

    public function testConsumeToChar() {
        var r = new CharacterReader("One Two Three");
        Assert.equals("One ", r.consumeTo('T'.code));
        Assert.equals("", r.consumeTo('T'.code)); // on Two
        Assert.equals('T'.code, r.consume());
        Assert.equals("wo ", r.consumeTo('T'.code));
        Assert.equals('T'.code, r.consume());
        Assert.equals("hree", r.consumeTo('T'.code)); // consume to end
    }

    public function testConsumeToString() {
        var r = new CharacterReader("One Two Two Four");
        Assert.equals("One ", r.consumeToSeq("Two"));
        Assert.equals('T'.code, r.consume());
        Assert.equals("wo ", r.consumeToSeq("Two"));
        Assert.equals('T'.code, r.consume());
        Assert.equals("wo Four", r.consumeToSeq("Qux"));
    }

    public function testAdvance() {
        var r = new CharacterReader("One Two Three");
        Assert.equals('O'.code, r.consume());
        r.advance();
        Assert.equals('e'.code, r.consume());
    }

    public function testConsumeToAny() {
        var r = new CharacterReader("One &bar; qux");
        Assert.equals("One ", r.consumeToAny(['&'.code, ';'.code]));
        Assert.isTrue(r.matches('&'.code));
        Assert.isTrue(r.matchesSeq("&bar;"));
        Assert.equals('&'.code, r.consume());
        Assert.equals("bar", r.consumeToAny(['&'.code, ';'.code]));
        Assert.equals(';'.code, r.consume());
        Assert.equals(" qux", r.consumeToAny(['&'.code, ';'.code]));
    }

    public function testConsumeLetterSequence() {
        var r = new CharacterReader("One &bar; qux");
        Assert.equals("One", r.consumeLetterSequence());
        Assert.equals(" &", r.consumeToSeq("bar;"));
        Assert.equals("bar", r.consumeLetterSequence());
        Assert.equals("; qux", r.consumeToEnd());
    }

    public function testConsumeLetterThenDigitSequence() {
        var r = new CharacterReader("One12 Two &bar; qux");
        Assert.equals("One12", r.consumeLetterThenDigitSequence());
        Assert.equals(' '.code, r.consume());
        Assert.equals("Two", r.consumeLetterThenDigitSequence());
        Assert.equals(" &bar; qux", r.consumeToEnd());
    }

    public function testMatches() {
        var r = new CharacterReader("One Two Three");
        Assert.isTrue(r.matches('O'.code));
        Assert.isTrue(r.matchesSeq("One Two Three"));
        Assert.isTrue(r.matchesSeq("One"));
        Assert.isFalse(r.matchesSeq("one"));
        Assert.equals('O'.code, r.consume());
        Assert.isFalse(r.matchesSeq("One"));
        Assert.isTrue(r.matchesSeq("ne Two Three"));
        Assert.isFalse(r.matchesSeq("ne Two Three Four"));
        Assert.equals("ne Two Three", r.consumeToEnd());
        Assert.isFalse(r.matchesSeq("ne"));
    }

    public function testMatchesIgnoreCase() {
        var r = new CharacterReader("One Two Three");
        Assert.isTrue(r.matchesIgnoreCase("O"));
        Assert.isTrue(r.matchesIgnoreCase("o"));
        Assert.isTrue(r.matches('O'.code));
        Assert.isFalse(r.matches('o'.code));
        Assert.isTrue(r.matchesIgnoreCase("One Two Three"));
        Assert.isTrue(r.matchesIgnoreCase("ONE two THREE"));
        Assert.isTrue(r.matchesIgnoreCase("One"));
        Assert.isTrue(r.matchesIgnoreCase("one"));
        Assert.equals('O'.code, r.consume());
        Assert.isFalse(r.matchesIgnoreCase("One"));
        Assert.isTrue(r.matchesIgnoreCase("NE Two Three"));
        Assert.isFalse(r.matchesIgnoreCase("ne Two Three Four"));
        Assert.equals("ne Two Three", r.consumeToEnd());
        Assert.isFalse(r.matchesIgnoreCase("ne"));
    }

    public function testContainsIgnoreCase() {
        var r = new CharacterReader("One TWO three");
        Assert.isTrue(r.containsIgnoreCase("two"));
        Assert.isTrue(r.containsIgnoreCase("three"));
        // weird one: does not find one, because it scans for consistent case only
        Assert.isFalse(r.containsIgnoreCase("one"));
    }

    public function testMatchesAny() {
        var scan:Array<CodePoint> = [' '.code, '\n'.code, '\t'.code];
        var r = new CharacterReader("One\nTwo\tThree");
        Assert.isFalse(r.matchesAny(scan));
        Assert.equals("One", r.consumeToAny(scan));
        Assert.isTrue(r.matchesAny(scan));
        Assert.equals('\n'.code, r.consume());
        Assert.isFalse(r.matchesAny(scan));
    }

    public function testCachesStrings() {
        var r = new CharacterReader("Check\tCheck\tCheck\tCHOKE\tA var that is longer than 16 chars");
        var one = r.consumeTo('\t'.code);
        r.consume();
        var two = r.consumeTo('\t'.code);
        r.consume();
        var three = r.consumeTo('\t'.code);
        r.consume();
        var four = r.consumeTo('\t'.code);
        r.consume();
        var five = r.consumeTo('\t'.code);

        Assert.equals("Check", one);
        Assert.equals("Check", two);
        Assert.equals("Check", three);
        Assert.equals("CHOKE", four);
        Assert.isTrue(one == two);
        Assert.isTrue(two == three);
        Assert.isTrue(three != four);
        Assert.isTrue(four != five);
        Assert.equals(five, "A var that is longer than 16 chars");
    }

    public function testRangeEquals() {
        var r = new CharacterReader("Check\tCheck\tCheck\tCHOKE");
        Assert.isTrue(r.rangeEquals(0, 5, "Check"));
        Assert.isFalse(r.rangeEquals(0, 5, "CHOKE"));
        Assert.isFalse(r.rangeEquals(0, 5, "Chec"));

        Assert.isTrue(r.rangeEquals(6, 5, "Check"));
        Assert.isFalse(r.rangeEquals(6, 5, "Chuck"));

        Assert.isTrue(r.rangeEquals(12, 5, "Check"));
        Assert.isFalse(r.rangeEquals(12, 5, "Cheeky"));

        Assert.isTrue(r.rangeEquals(18, 5, "CHOKE"));
        Assert.isFalse(r.rangeEquals(18, 5, "CHIKE"));
    }


}
