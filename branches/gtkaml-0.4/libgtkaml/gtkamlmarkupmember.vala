using GLib;
using Vala;

/**
 * Represents a container or widget (with or without gtkaml:name) which is declared as a member
 */
public class Gtkaml.MarkupMember : MarkupTag, Property {

	private MarkupTag? parent_tag;
	private Gee.List<MarkupTag> child_tags = new Gee.ArrayList<MarkupTag>();
	
	public MarkupMember (string name, DataType data_type, SourceReference source_reference)
	{
		base (name, data_type, null, null, source_reference);
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
	}
	

}
