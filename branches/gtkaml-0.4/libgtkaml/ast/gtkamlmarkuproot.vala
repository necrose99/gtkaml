using GLib;
using Vala;

public class Gtkaml.MarkupRoot : MarkupTag {

	public MarkupRoot (MarkupClass markup_class, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null) {
		base (markup_class, tag_name, tag_namespace, source_reference);
	}
	
	public override string me { get { return "this"; } }

	public override void generate_public_ast () {
		markup_class.add_base_type (data_type.copy ());
		markup_class.constructor = new Constructor (markup_class.source_reference);
		markup_class.constructor.body = new Block (markup_class.source_reference);	
	}

	public override void generate (MarkupResolver resolver) {
		generate_creation_method (resolver);
	}

	/**
	 * generate creation method with base () call
	 */
	private void generate_creation_method (MarkupResolver resolver) {
		CreationMethod creation_method = new CreationMethod(markup_class.name, null, markup_class.source_reference);
		creation_method.access = SymbolAccessibility.PUBLIC;
		
		//TODO: determine the base() to call from MarkupHintsStore
		//TODO: take into account the fact that, if the arguments are actually {code} expressions or complex attributes
		//      .. they can't be used in this scenario:(
		var base_call = new MethodCall (new BaseAccess (markup_class.source_reference), markup_class.source_reference);
		base_call.add_argument (new BooleanLiteral (false, markup_class.source_reference));
		base_call.add_argument (new IntegerLiteral ("0", markup_class.source_reference));

		var block = new Block (markup_class.source_reference);
		block.add_statement (new ExpressionStatement (base_call, markup_class.source_reference));
		creation_method.body = block;
		
		//FIXME: add this after vala base() bug is solved - otherwise, refactor to use setters,..
		markup_class.add_method (creation_method);
	}

}
