using GLib;
using Vala;

/**
 * Represents the building block of the markup hierarchy
 */ 
public interface Gtkaml.MarkupTag : CodeNode {
	
	/**
	 * Vala namespace inferred from XML prefix
	 */
	//TODO:use UnresolvedSymbol/UnresolvedType
	public abstract string get_markup_namespace ();
	
	/**
	 * The list of children MarkupTags
	 */
	public abstract Gee.ReadOnlyList<MarkupSubTag> get_child_tags ();
		
	/**
	 * Adds a child tag to this one
	 */
	public abstract void add_child_tag (MarkupSubTag child_tag);	
	
	/**
	 * The list of attributes
	 */
	public abstract Gee.ReadOnlyList<MarkupAttribute> get_markup_attributes ();	
	
	/**
	 * Adds an attribute
	 */
	public abstract void add_markup_attribute (MarkupAttribute markup_attribute);
	
}

