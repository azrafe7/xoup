package;

import org.jsoup.helper.StringUtil;
import org.jsoup.helper.StringUtilTest;
import org.jsoup.integration.ParseTest;
import org.jsoup.nodes.AttributesTest;
import org.jsoup.nodes.AttributeTest;
import org.jsoup.nodes.DocumentTest;
import org.jsoup.nodes.DocumentTypeTest;
import org.jsoup.nodes.ElementTest;
import org.jsoup.nodes.EntitiesTest;
import org.jsoup.nodes.FormElementTest;
import org.jsoup.nodes.NodeTest;
import org.jsoup.nodes.TextNodeTest;
import org.jsoup.parser.AttributeParseTest;
import org.jsoup.parser.CharacterReaderTest;
import org.jsoup.parser.TagTest;
import org.jsoup.parser.TokenQueueTest;
import org.jsoup.parser.XmlTreeBuilderTest;
import org.jsoup.select.CssTest;
import org.jsoup.select.ElementsTest;
import org.jsoup.select.QueryParserTest;
import org.jsoup.select.SelectorTest;
import org.jsoup.parser.HtmlParserTest;
import utest.TestFixture;
import utest.ui.text.PrintReport;

import utest.Runner;
import utest.ui.Report;

using unifill.Unifill;

class TestAll {
	
	static var runner:Runner = new Runner();
	
	static public function main():Void {
		
		addHelperTests();
		addNodesTests();
		addSelectTests();
		addParserTests();
		addParseTests();
		
		var report = new PrintReport(runner);
		runner.run();
		
	#if flash
		flash.system.System.exit(1);
	#end
	}
	
	static function addHelperTests() {
		runner.addCase(new StringUtilTest());
	}
	
	static function addNodesTests() {
		runner.addCase(new EntitiesTest());
		runner.addCase(new AttributeTest());
		runner.addCase(new AttributesTest());
		runner.addCase(new DocumentTypeTest());
		runner.addCase(new DocumentTest());
		runner.addCase(new NodeTest());
		runner.addCase(new ElementTest());
		runner.addCase(new TextNodeTest());
		runner.addCase(new FormElementTest());
	}
	
	static function addSelectTests() {
		runner.addCase(new ElementsTest());
		runner.addCase(new SelectorTest());
		runner.addCase(new CssTest());
		runner.addCase(new QueryParserTest());
	}

	static function addParserTests() {
		runner.addCase(new AttributeParseTest());
		runner.addCase(new TagTest());
		runner.addCase(new TokenQueueTest());
		runner.addCase(new XmlTreeBuilderTest());
		runner.addCase(new CharacterReaderTest());
		runner.addCase(new HtmlParserTest());
	}

	static function addParseTests() {
		runner.addCase(new ParseTest());
	}
}