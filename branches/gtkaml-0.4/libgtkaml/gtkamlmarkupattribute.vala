using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public interface Gtkaml.MarkupAttribute : Object {
	public abstract string attribute_name {get; }
	public abstract Expression attribute_expression {get; }
	public abstract DataType target_type {get; set;} //this will be set later
	
	public abstract Expression get_expression ();
	
}

