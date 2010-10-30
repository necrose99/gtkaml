using Vala;

public class Gtkaml.CodeContext : Vala.CodeContext {

	public SymbolResolver markup_resolver { get; private set; }
	
	public CodeContext () {
		markup_resolver = new MarkupResolver ();
		base ();
	}

	public new void check () {
		markup_resolver.resolve (this);

		if (report.get_errors () > 0) {
			return;
		}

		analyzer.analyze (this);

		if (report.get_errors () > 0) {
			return;
		}

		flow_analyzer.analyze (this);
	}
}
