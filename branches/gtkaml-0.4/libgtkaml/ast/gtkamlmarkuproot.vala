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
		parse_class_members (this.text);
	}

	public override void generate (MarkupResolver resolver) {

	}

	/**
	 * returns the list of possible creation methods, in root's case, only the default creation method
	 */
	public override Gee.List<CreationMethod> get_creation_method_candidates () {
		var candidates = base.get_creation_method_candidates ();
		foreach (var candidate in candidates) {
			if (candidate.name == "new") {
				candidates = new Gee.ArrayList<CreationMethod> ();
				candidates.add (candidate);
				break;//before foreach complains
			}
		}
		assert (candidates.size == 1);
		return candidates;
	}

	override void resolve_creation_method_failed (Method min_match_method){
		var required = "";
		var parameters = min_match_method.get_parameters ();
		int i = 0;
		for (; i < parameters.size - 1; i++ ) {
			required += "'" + parameters[i].name + "',";
		}
		required += "'" + parameters[i].name + "'";
		Report.warning (source_reference, "at least %s required for %s instantiation.\n".printf (required, full_name));
	}

	private void parse_class_members (string source) {
		var classes = call_vala_parser ("public class %s { %s }".printf ("Temp", source), "%s-members".printf (tag_name)).get_classes();
		foreach (var x in classes.get(0).get_methods ()) {
			if (!(x is CreationMethod))  {
				stderr.printf ("adding %s\n", x.name);
				markup_class.add_method (x);
			}
		}
	}

	/**
	 * generate creation method with base () call
	 * DISABLED
	 */
	private void generate_creation_method (MarkupResolver resolver) {
		CreationMethod creation_method = new CreationMethod(markup_class.name, null, markup_class.source_reference);
		creation_method.access = SymbolAccessibility.PUBLIC;
		
		var block = new Block (markup_class.source_reference);

		//unfortunately base/construct detection is not possible before vala symbol resolving:-S
		//if (markup_class.base_class.default_construction_method.has_construct_function) {
			var base_call = new MethodCall (new BaseAccess (markup_class.source_reference), markup_class.source_reference);
			foreach (var parameter in creation_parameters) { 
				base_call.add_argument (parameter.get_expression ());
			}
			block.add_statement (new ExpressionStatement (base_call, markup_class.source_reference));
		//}
		
		creation_method.body = block;
		
		markup_class.add_method (creation_method);
	}

}
