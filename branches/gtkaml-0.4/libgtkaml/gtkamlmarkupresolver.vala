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
	
	public Gee.List<CreationMethod> get_creation_methods (DataType type) {
		assert (type.data_type is Class);
		
		Gee.List<CreationMethod> creation_methods = new Gee.ArrayList<CreationMethod> ();
		foreach (Method m in (type.data_type as Class).get_methods ()) {
			if (m is CreationMethod) creation_methods.add (m as CreationMethod);
		}
		
		assert (creation_methods.size > 0);
		return creation_methods;
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
	private bool resolve_markup_tag (MarkupTag markup_tag) {
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
		Gee.List<CreationMethod> candidates = get_creation_methods (markup_tag.resolved_type);
		
		//corner case: one of the creation method's name is present with the value "true"
		foreach (var candidate in candidates) {
			var explicit = markup_tag.get_attribute (candidate.name);
			if (explicit != null) {
				stderr.printf ("Explicitly requesting %s\n", candidate.name);
				markup_tag.remove_attribute (explicit);
				candidates = new Gee.ArrayList<CreationMethod> ();
				candidates.add (candidate);
				break;//before foreach complains
			}
		}
		//we now have a list of creation methods, or a single creation method explicitly requested.
		
		//go through each method, updating max&max_match_method if it matches and min&min_match_method otherwise
		//so that we know the best match method, if found, otherwise the minimum number of arguments to specify

		int min = 100; CreationMethod min_match_method = candidates.get (0);
		int max = -1; CreationMethod max_match_method = candidates.get (0);
		Gee.List<SimpleMarkupAttribute> matched_method_parameters = new Gee.ArrayList<SimpleMarkupAttribute> ();
		
		var i = 0;
		
		do {
			var current_candidate = candidates.get (i);
			var parameters = markup_hints.get_default_parameters (markup_tag.resolved_type.data_type.get_full_name(), current_candidate);
			int matches = 0;

			foreach (var parameter in parameters) {
				if ( (null != markup_tag.get_attribute (parameter.attribute_name)) || parameter.attribute_value != null) {
					matches ++;
				}
			}
			
			if (matches < parameters.size) {  //does not match
				if (parameters.size < min) {
					min = parameters.size;
					min_match_method = current_candidate;
				}
			} else {
				assert (matches == parameters.size);
				if (parameters.size > max) {
					max = parameters.size;
					max_match_method = current_candidate;
					matched_method_parameters = parameters;
				}
			}

			i++;
		} while ( i < candidates.size );

		if (max_match_method.get_parameters ().size == max) { 
			markup_tag.creation_method = max_match_method;
			//save the CreationMethodParameters:
			foreach (var parameter in matched_method_parameters) {
				if (parameter.attribute_value == null) {
					//for the explicit ones, include the original attribute
					var explicit_attribute = markup_tag.get_attribute (parameter.attribute_name);
					markup_tag.creation_parameters.add (explicit_attribute);
					markup_tag.remove_attribute (explicit_attribute);
				} else {
					//for the default ones, include the default attribute
					markup_tag.creation_parameters.add (parameter);
				}
			}
		} else {
			var required = "";
			foreach (var parameter in min_match_method.get_parameters ()) required += "'" + parameter.name + "' ";
			Report.error (markup_tag.source_reference, "at least %s are required\n".printf (required));
		}
	}
	
}
