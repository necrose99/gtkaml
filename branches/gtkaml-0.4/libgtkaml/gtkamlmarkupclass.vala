using GLib;
using Vala;

/**
 * Represents a Class as declared by a Gtkaml root node
 */
public class Gtkaml.MarkupClass : MarkupTag, Class {

	private Gee.List<MarkupSubTag> child_tags = new Gee.ArrayList<MarkupSubTag> ();
	private Gee.List<MarkupAttribute> markup_attributes = new Gee.ArrayList<MarkupAttribute> ();
	
	public string tag_name {get; set;}
	public MarkupNamespace tag_namespace {get; set;}

	
	public MarkupClass (string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		this.tag_name = tag_name;
		this.tag_namespace = tag_namespace;
		//TODO: this class in a namespace
		base (tag_name, source_reference);
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
	
	
}

