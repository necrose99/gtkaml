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
	
	/** processes tag hierarchy. Removes unresolved ones after this step */
	private bool resolve_markup_tag (MarkupTag markup_tag) {
		//resolve in preorder
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
				
			//attributes in post_order
			resolve_creation_method (resolved_tag);
		}		
		return resolved_tag != null;
	}
	
	private void generate_markup_tag (MarkupTag markup_tag) {
		markup_tag.generate (this);
		foreach (MarkupTag child_tag in markup_tag.get_child_tags ())
			generate_markup_tag (child_tag);
	}
	
	private void resolve_creation_method (MarkupTag markup_tag) {
		//generate all possible creation methods for a given class
/*		Gee.List<Method> candidates = markup_hints.list_creation_methods (this, markup_tag.resolved_type.data_type as ObjectTypeSymbol);
*/		//TODO: go through each method, updating max&max_match_method if it matches and min&min_match_method otherwise
		//so that we know the best match method, if found, otherwise the minimum number of arguments to specify
/*		int min = 0; Method min_match_method;
		int max = 0; Method max_match_method; 
*/	}
	
}
