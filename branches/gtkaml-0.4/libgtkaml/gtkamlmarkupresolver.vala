using GLib;
using Vala;

/**
 * TODO: Gtkaml SymbolResolver's  responsibilities:
 * - determine if an attribute is a field or a signal and use = or += appropiately
 * Literal attribute values:
 * - determine the type of the literal field attribute (boolean, string and enum)
 * - determine the method reference for the literal signal attribute
 * Expression attribute values:
 * - signals: use the result of lambda parsing add the signal parameters
 * - fields: use the expression of the lambda as field assignment
 */
public class Gtkaml.MarkupResolver : SymbolResolver {

	public MarkupHintsStore markup_hints;

	public new void resolve (CodeContext context) {
		markup_hints = new MarkupHintsStore (context);
		markup_hints.parse ();
		base.resolve (context);
	}

	public override void visit_class (Class cl) {
		if (cl is MarkupClass) {
			visit_markup_class (cl as MarkupClass);
		}
		base.visit_class (cl);
	}
	
	public void visit_markup_class (MarkupClass mcl) {
		resolve_markup_tag (mcl.markup_root);
		generate_markup_tag (mcl.markup_root);
	}
	
	public Gee.List<DataType> get_what_extends (DataType type) {
		if (type is Class) {
			return (type as Class).get_base_types ();
		} 
		else
		if (type is Interface) {
			return (type as Interface).get_prerequisites (); 
		}
		else
			return new Gee.ArrayList<DataType> ();
	}
	
	/** processes tag hierarchy. Removes unresolved ones after this step */
	public bool resolve_markup_tag (MarkupTag markup_tag) {
		//resolve first
		MarkupTag? resolved_tag = markup_tag.resolve (this);
		
		if (resolved_tag != null) {
			Gee.List<MarkupSubTag> to_remove = new Gee.ArrayList<MarkupSubTag> ();

			//recurse
			foreach (var child_tag in resolved_tag.get_child_tags ()) {
				if (false == resolve_markup_tag (child_tag)) {
					to_remove.add (child_tag);
				}
			}
		
			foreach (var remove in to_remove)
				resolved_tag.remove_child_tag (remove);
				
			//attributes last
			resolved_tag.resolve_creation_method (this);
		}		
		return resolved_tag != null;
	}
	
	public Gee.List<SimpleMarkupAttribute> get_default_parameters (MarkupTag markup_tag, Method method, SourceReference? source_reference = null) {
		return markup_hints.get_default_parameters (markup_tag.full_name, method, source_reference);
	}
	
	private void generate_markup_tag (MarkupTag markup_tag) {
		markup_tag.generate (this);
		foreach (MarkupTag child_tag in markup_tag.get_child_tags ())
			generate_markup_tag (child_tag);
	}
	
}
