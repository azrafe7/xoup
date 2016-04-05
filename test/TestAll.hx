package;

import org.jsoup.helper.StringUtil;
import org.jsoup.helper.StringUtilTest;
import org.jsoup.nodes.AttributesTest;
import org.jsoup.nodes.AttributeTest;
import org.jsoup.nodes.DocumentTest;
import org.jsoup.nodes.DocumentTypeTest;
import org.jsoup.nodes.ElementTest;
import org.jsoup.nodes.EntitiesTest;
import org.jsoup.nodes.FormElementTest;
import org.jsoup.nodes.NodeTest;
import org.jsoup.nodes.TextNodeTest;
import org.jsoup.select.CssTest;
import org.jsoup.select.ElementsTest;
import org.jsoup.select.QueryParserTest;
import org.jsoup.select.SelectorTest;
import utest.ui.text.PrintReport;

import utest.Runner;
import utest.ui.Report;

using unifill.Unifill;

class TestAll {
	static public function main():Void {
		
		var runner = new Runner();
		
		runner.addCase(new EntitiesTest());
		runner.addCase(new AttributeTest());
		runner.addCase(new AttributesTest());
		runner.addCase(new DocumentTypeTest());
		runner.addCase(new DocumentTest());
		runner.addCase(new NodeTest());
		runner.addCase(new ElementTest());
		runner.addCase(new TextNodeTest());
		runner.addCase(new FormElementTest());
		runner.addCase(new StringUtilTest());
		
		runner.addCase(new ElementsTest());
		runner.addCase(new SelectorTest());
		runner.addCase(new CssTest());
		runner.addCase(new QueryParserTest());
		
		var report = new PrintReport(runner);
		runner.run();
		
		#if flash
		flash.system.System.exit(1);
		#end
	}
}