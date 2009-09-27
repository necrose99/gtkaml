using GLib;
using Vala;

/*
 * MarkupSubTag is a MarkupTag that has itself a parent: 
 * parent_tag, and g:existing, g:standalone, g:construct, g:private etc.
 */
public abstract class Gtkaml.MarkupSubTag : MarkupTag {

	public weak MarkupTag parent_tag {get;set;}

	/** attributes explicitly found as composition parameters + default ones.
		All in the original order.
	 */
	public Gee.List<MarkupAttribute> composition_parameters = new Gee.ArrayList<MarkupAttribute> ();
	/** resolved composition method */
	public Callable composition_method;

	public MarkupSubTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference) {
		base (parent_tag.markup_class, tag_name, tag_namespace, source_reference);
		this.parent_tag = parent_tag;
	}

	public override void resolve_attributes (MarkupResolver resolver) {
		base.resolve_attributes (resolver);
		resolve_composition_method (resolver);
	}

	void resolve_composition_method (MarkupResolver resolver) {
		var candidates = resolver.get_composition_method_candidates (this.parent_tag.resolved_type.data_type as TypeSymbol);
		
		if (candidates.size == 0) {
			Report.error (source_reference, "No composition methods found for adding %s to a %s".printf (full_name, parent_tag.full_name));
			return;
		}

		//go through each method, updating max&max_match_method if it matches and min&min_match_method otherwise
		//so that we know the best match method, if found, otherwise the minimum number of arguments to specify

		int min = 100; Callable min_match_method = candidates.get (0);
		int max = -1; Callable max_match_method = candidates.get (0);
		Gee.List<SimpleMarkupAttribute> matched_method_parameters = new Gee.ArrayList<MarkupAttribute> ();
		
		var i = 0;
		
		do {
			var current_candidate = candidates.get (i);
			var parameters = resolver.get_default_parameters (full_name, current_candidate, source_reference);
			int matches = 0;

			foreach (var parameter in parameters) {
				if ( (null != get_attribute (parameter.attribute_name)) || parameter.attribute_value != null) {
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
			this.composition_method = max_match_method;
			//save the CreationMethodParameters:
			foreach (var parameter in matched_method_parameters) {
				MarkupAttribute explicit_attribute = null;
				if (null != (explicit_attribute = get_attribute (parameter.attribute_name))) {
					//for the explicit ones, copy the data type from the default attribute
					explicit_attribute.target_type = parameter.target_type;
					this.composition_parameters.add (explicit_attribute);
					remove_attribute (explicit_attribute);
				} else {
					//for the default ones, include the default attribute
					this.composition_parameters.add (parameter);
				}
			}
		} else {
			var required = "";
			var parameters = min_match_method.get_parameters ();
			i = 0;
			for (; i < parameters.size - 1; i++ ) {
				required += "'" + parameters[i].name + "',";
			}
			required += "'" + parameters[i].name + "'";
			Report.error (source_reference, "at least %s required for composing %s into %s using %s () .".printf (required, full_name, parent_tag.full_name, min_match_method.name));
		}
	}

	/**
	 * returns the list of possible creation methods, containing a single element if explicitly requested
	 */
	public override Gee.List<CreationMethod> get_creation_method_candidates () {
		var candidates = base.get_creation_method_candidates ();
		
		//for subtags: one of the creation method's name is present with the value "true"
		foreach (var candidate in candidates) {
			var explicit = get_attribute (candidate.name);
			if (explicit != null) {
				remove_attribute (explicit);
				candidates = new Gee.ArrayList<CreationMethod> ();
				candidates.add (candidate);
				break;//before foreach complains
			}
		}

		return candidates;
	}

}
