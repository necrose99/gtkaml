using GLib;
using Vala;

/**
 * Represents a Class as declared by a Gtkaml root node
 */
public class Gtkaml.Class : MarkupTag, Vala.Class {

	private weak MarkupTag? parent_tag;
	private Gee.List<MarkupTag> child_tags = new Gee.ArrayList<MarkupTag>();
	
	public Class (string name, SourceReference? source_reference)
	{
		base (name, source_reference);
	}
	
	//MarkupTag implementation
		
	public MarkupTag? get_parent_tag () {
		return parent_tag;
	}
	
	public void set_parent_tag (MarkupTag? parent_tag) {
		this.parent_tag = parent_tag;
	}
	
	public Gee.ReadOnlyList<MarkupTag> get_child_tags () {
		return new Gee.ReadOnlyList<MarkupTag> (child_tags);
	}
	
	public void add_child_tag (MarkupTag child_tag) {
		child_tags.add (child_tag);
		child_tag.set_parent_tag (this);
		
		this.add_property (child_tag as MarkupMember);
	}

	
}

