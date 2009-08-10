using GLib;
using Vala;

/**
 * Represents a Class as declared by a Gtkaml root node
 */
public class Gtkaml.MarkupClass : MarkupTag, Vala.Class {

	private Gee.List<MarkupTag> child_tags = new Gee.ArrayList<MarkupTag>();
	
	public Class (string name, SourceReference? source_reference = null)
	{
		base (name, source_reference);
		parent_tag = null;
	}
	
	//MarkupTag implementation
		
	public MarkupTag? get_parent_tag () {
		return null;
	}
	
	public Gee.ReadOnlyList<MarkupTag> get_child_tags () {
		return new Gee.ReadOnlyList<MarkupTag> (child_tags);
	}
	
	public void add_child_tag (MarkupTag child_tag) {
		_child_tags.add (child_tag);
	}

	
}

