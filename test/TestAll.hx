package;

import org.jsoup.nodes.AttributesTest;
import org.jsoup.nodes.AttributeTest;
import org.jsoup.nodes.DocumentTest;
import org.jsoup.nodes.DocumentTypeTest;
import org.jsoup.nodes.EntitiesTest;
import org.jsoup.nodes.NodeTest;

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
		
		Report.create(runner);
		runner.run();
		
		#if flash
		flash.system.System.exit(1);
		#end
	}
}