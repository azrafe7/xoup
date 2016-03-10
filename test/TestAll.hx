package;

import org.jsoup.nodes.EntitiesTest;
import utest.Runner;
import utest.ui.Report;

class TestAll {
	static public function main():Void {
		var runner = new Runner();
		runner.addCase(new EntitiesTest());
		Report.create(runner);
		runner.run();
	}
}