package;

import org.jsoup.nodes.AttributeTest;
import org.jsoup.nodes.EntitiesTest;
import utest.Runner;
import utest.ui.Report;

using unifill.Unifill;

class TestAll {
	static public function main():Void {
		var runner = new Runner();
		runner.addCase(new EntitiesTest());
		runner.addCase(new AttributeTest());
		Report.create(runner);
		runner.run();
	}
}