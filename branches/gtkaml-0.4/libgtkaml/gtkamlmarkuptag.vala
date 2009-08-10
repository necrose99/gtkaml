using GLib;
using Vala;

/**
 * Interface representing a tag that is a parent of others. Can be the root tag.
 */ 
public interface Gtkaml.MarkupTag : CodeNode {
	
	public abstract string tag_name {get; set;}

	/**
	 * Vala namespace inferred from XML prefix
	 */
	public abstract MarkupNamespace tag_namespace {get; set;}
	
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
	
	public DataType to_unresolved_type() { 
		return new UnresolvedType.from_symbol (new UnresolvedSymbol (tag_namespace, tag_name));
	}
}

