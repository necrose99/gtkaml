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
			if (resolved_tag is MarkupSubTag)
				(resolved_tag as MarkupSubTag).resolve_composition_method (this);
		}		
		return resolved_tag != null;
	}

	private void generate_markup_tag (MarkupTag markup_tag) {
		markup_tag.generate (this);
		foreach (MarkupTag child_tag in markup_tag.get_child_tags ())
			generate_markup_tag (child_tag);
	}
		
	public Gee.List<SimpleMarkupAttribute> get_default_creation_method_parameters (MarkupTag markup_tag, Method method, SourceReference? source_reference = null) {
		return get_default_parameters (markup_tag.full_name, method, source_reference);
	}

	//TODO: merge composition and creation
	Gee.List<SimpleMarkupAttribute> get_default_parameters (string full_type_name, Method m, SourceReference? source_reference = null) {
		var parameters = new Gee.ArrayList<SimpleMarkupAttribute> ();
		var hint = markup_hints.markup_hints.get (full_type_name);
		if (hint != null) {
			Gee.List <Pair<string, string?>> parameter_hints = hint.get_creation_method_parameters (m.name);
			if (parameter_hints != null) {
				assert (parameter_hints.size == m.get_parameters ().size);
				//actual merge. with two parralell foreaches
				int i = 0;
				foreach (var formal_parameter in m.get_parameters ()) {
					assert ( i < parameter_hints.size );
					var parameter = new SimpleMarkupAttribute.with_type ( parameter_hints.get (i).name, parameter_hints.get (i).value, formal_parameter.parameter_type, source_reference );
					parameters.add (parameter);
					i++;
				}
				return parameters;
			} 
		}	
		foreach (var formal_parameter in m.get_parameters ()) {
			var parameter = new SimpleMarkupAttribute.with_type ( formal_parameter.name, null, formal_parameter.parameter_type );
			parameters.add (parameter);
		}
		return parameters;
	}	

	//TODO: merge composition and creation
	public Gee.List<SimpleMarkupAttribute> get_default_composition_method_parameters (string full_type_name, Method m, SourceReference? source_reference = null) {
		var parameters = new Gee.ArrayList<SimpleMarkupAttribute> ();
		var hint = markup_hints.markup_hints.get (full_type_name);
		if (hint != null) {
			Gee.List <Pair<string, string?>> parameter_hints = hint.get_composition_method_parameters (m.name);
			if (parameter_hints != null) {
				assert (parameter_hints.size == m.get_parameters ().size);
				//actual merge. with two parralell foreaches
				int i = 0;
				foreach (var formal_parameter in m.get_parameters ()) {
					assert ( i < parameter_hints.size );
					var parameter = new SimpleMarkupAttribute.with_type ( parameter_hints.get (i).name, parameter_hints.get (i).value, formal_parameter.parameter_type, source_reference );
					parameters.add (parameter);
					i++;
				}
				return parameters;
			} 
		}	
		foreach (var formal_parameter in m.get_parameters ()) {
			var parameter = new SimpleMarkupAttribute.with_type ( formal_parameter.name, null, formal_parameter.parameter_type );
			parameters.add (parameter);
		}
		return parameters;
	}	

	public Gee.List<Member> get_composition_method_candidates (TypeSymbol parent_tag_symbol) {
		Gee.List<Member> candidates = new Gee.ArrayList<Member> ();
		var hint = markup_hints.markup_hints.get (parent_tag_symbol.get_full_name ());
		if (hint != null) {
			Gee.List<string> names = hint.get_composition_method_names ();
			foreach (var name in names) {
				Member? m = search_method_or_signal (parent_tag_symbol, name);
				if (m == null) {
					Report.error (null, "Invalid composition method hint: %s does not belong to %s".printf (name, parent_tag_symbol.get_full_name ()) );
				} else {
					#if DEBUGMARKUPHINTS
					stderr.printf (" FOUND!\n");
					#endif
					candidates.add (m as Member);
				}
			}
		}
		if (parent_tag_symbol is Class) {
			Class parent_class = parent_tag_symbol as Class;
			if (parent_class.base_class != null)
				foreach (Member m in get_composition_method_candidates (parent_class.base_class))
					candidates.add (m);
			foreach (var base_type in parent_class.get_base_types ())
				foreach (Member m in get_composition_method_candidates (base_type.data_type))
					candidates.add (m);
		} 
		return candidates;
	}
	
	/** returns method or signal */
	private Member? search_method_or_signal (TypeSymbol type, string name) {
		#if DEBUGMARKUPHINTS
		stderr.printf ("\rsearching %s in %s..", name, type.name);
		#endif
		if (type is Class) {
			Class class_type = type as Class;
			foreach (var m in class_type.get_methods ())
				if (m.name == name) return m;
			foreach (var s in class_type.get_signals ())
				if (s.name == name) return s;
			if (class_type.base_class != null) {
				Member? m = search_method_or_signal (class_type.base_class, name);
				if (m != null) return m;
			}
			foreach (var base_type in class_type.get_base_types ()) {
				Member ?m = search_method_or_signal (base_type.data_type, name);
				if (m != null) return m;
			}
		} else
		if (type is Interface) {
			Interface interface_type = type as Interface;
			foreach (var m in interface_type.get_methods ())
				if (m.name == name) return m;
			foreach (var s in interface_type.get_signals ())
				if (s.name == name) return s;
		} else
			assert_not_reached ();
		return null;
	}
	
}
