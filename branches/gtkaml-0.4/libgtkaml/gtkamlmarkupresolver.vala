using GLib;
using Vala;

/**
 * TODO:
 * Gtkaml SymbolResolver's  responsibilities:
 * - determine if an attribute is a field or a signal and use = or += appropiately
 * Literal attribute values:
 * - determine the type of the literal field attribute (boolean, string and enum)
 * - determine the method reference for the literal signal attribute
 * Expression attribute values:
 * - signals: use the result of lambda parsing add the signal parameters
 * - fields: use the expression of the lambda as field assignment
 */
public class Gtkaml.MarkupResolver : SymbolResolver {

	public ImplicitsStore implicits_store;

	public new void resolve (CodeContext context) {
		implicits_store = new ImplicitsStore (context);
		implicits_store.parse ();
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
	
	public void resolve_markup_tag (MarkupTag markup_tag) {
		markup_tag.resolve (this);
		foreach (MarkupTag child_tag in markup_tag.get_child_tags ())
			resolve_markup_tag (child_tag);
	}
	
	public void generate_markup_tag (MarkupTag markup_tag) {
		markup_tag.generate (this);
		foreach (MarkupTag child_tag in markup_tag.get_child_tags ())
			generate_markup_tag (child_tag);
	}
	
}
