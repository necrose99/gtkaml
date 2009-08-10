using GLib;
using Vala;

/**
 * Represents the building block of the markup hierarchy
 */ 
public interface Gtkaml.MarkupTag : CodeNode {

	public abstract string prop {get;}
	
	/**
	 * The parent of this tag
	 */
	public abstract MarkupTag? get_parent_tag ();
	
	public abstract void set_parent_tag (MarkupTag? parent_tag);	
	/**
	 * The list of children MarkupTags
	 */
	public abstract Gee.ReadOnlyList<MarkupTag> get_child_tags ();
		
	/**
	 * Adds a child tag to this one
	 */
	public abstract void add_child_tag (MarkupTag child_tag);		
}

