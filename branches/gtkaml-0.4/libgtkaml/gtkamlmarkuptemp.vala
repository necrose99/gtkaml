using GLib;
using Vala;


public class Gtkaml.MarkupTemp : MarkupSubTag {
	
	public MarkupTemp (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
	}

	public override void parse () {
		//do nothing
	}

	public override void resolve (MarkupResolver resolver) {
		//TODO
	}
	
	public override void generate (MarkupResolver resolver) {
		generate_temp (resolver);
	}
	
	private void generate_temp (MarkupResolver resolver) {
		var initializer = new ObjectCreationExpression (new MemberAccess (null, tag_name, source_reference), source_reference);
		
		//TODO: determine the initialize to call from ImplicitsStore
		initializer.add_argument (new StringLiteral ("\"_Hello\"", source_reference));
		
		var local_variable = new LocalVariable (null, "label0",  initializer, source_reference);
		var local_declaration = new DeclarationStatement (local_variable, source_reference);
		
		markup_class.constructor.body.add_statement (local_declaration);
	}
}
