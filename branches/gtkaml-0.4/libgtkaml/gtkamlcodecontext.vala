using Vala;

public class Gtkaml.CodeContext : Vala.CodeContext {
	
	public CodeContext () {
		resolver = new MarkupResolver ();
		analyzer = new SemanticAnalyzer ();
		flow_analyzer = new FlowAnalyzer ();
	}
}
