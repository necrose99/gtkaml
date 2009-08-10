using GLib;
using Vala;

/**
 * Any markup tag encountered in XML that is not the root, nor has g:public/g:private identifier.
 * Can later morph into a complex attribute
 */
public class Gtkaml.UnresolvedMarkupSubTag : MarkupSubTag {

	
	public UnresolvedMarkupSubTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
	}	
	
	public override void parse () {
		
	}

	public override void resolve (MarkupResolver resolver) {
		//replace unresolved tags with temp tags or complex attributes
		var markup_temp = new MarkupTemp (parent_tag, tag_name, tag_namespace, source_reference);
		parent_tag.replace_child_tag (this, markup_temp);
		markup_temp.resolve (resolver);
	}
	
	public override void generate (MarkupResolver resolver) {
		//TODO
	}
}
