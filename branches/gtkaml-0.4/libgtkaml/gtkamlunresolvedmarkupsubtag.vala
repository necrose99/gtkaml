using GLib;
using Vala;

/**
 * Any markup tag encountered in XML that is not the root, nor has g:public/g:private identifier.
 * Can later morph into a complex attribute
 */
public class Gtkaml.UnresolvedMarkupSubTag : MarkupSubTag, MarkupTag, CodeNode {

	private weak MarkupTag parent_tag;
	private weak MarkupClass parent_class;
	private Gee.List<MarkupSubTag> child_tags = new Gee.ArrayList<MarkupSubTag> ();
	private Gee.List<MarkupAttribute> markup_attributes = new Gee.ArrayList<MarkupAttribute> ();
	
	public UnresolvedMarkupSubTag (MarkupClass parent_class, SourceReference? source_reference = null)
	{
		this.parent_class = parent_class;
		this.source_reference = source_reference;
	}	
	
	
	//MarkupTag implementation
		
	public Gee.ReadOnlyList<MarkupSubTag> get_child_tags () {
		return new Gee.ReadOnlyList<MarkupSubTag> (child_tags);
	}
	
	public void add_child_tag (MarkupSubTag child_tag) {
		child_tags.add (child_tag);
		child_tag.set_parent_tag (this);
	}
	
	public Gee.ReadOnlyList<MarkupAttribute> get_markup_attributes () {
		return new Gee.ReadOnlyList<MarkupAttribute> (markup_attributes);
	}
	
	public void add_markup_attribute (MarkupAttribute markup_attribute) {
		markup_attributes.add (markup_attribute);
	}
	
	//MarkupSubTag implementation

	public MarkupTag get_parent_tag () {
		return parent_tag;
	}
	
	public void set_parent_tag (MarkupTag parent_tag) {
		this.parent_tag = parent_tag;
	}
	
	public MarkupClass get_parent_class () {
		return this.parent_class;
	}

}
