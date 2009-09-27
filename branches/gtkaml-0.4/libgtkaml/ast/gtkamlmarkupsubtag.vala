using GLib;
using Vala;

/*
 * MarkupSubTag is a MarkupTag that has itself a parent: 
 * parent_tag, and g:existing, g:standalone, g:construct, g:private etc.
 */
public abstract class Gtkaml.MarkupSubTag : MarkupTag {

	public weak MarkupTag parent_tag {get;set;}

	public MarkupSubTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference) {
		base (parent_tag.markup_class, tag_name, tag_namespace, source_reference);
		this.parent_tag = parent_tag;
	}

	public void resolve_composition_method (MarkupResolver resolver) {
		var candidates = resolver.get_composition_method_candidates (this.parent_tag.resolved_type.data_type as TypeSymbol);
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
