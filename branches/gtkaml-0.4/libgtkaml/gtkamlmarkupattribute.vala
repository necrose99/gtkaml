using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public interface Gtkaml.MarkupAttribute : Object {
	public abstract string attribute_name {get; }
	public abstract DataType target_type {get; set;} 
	
	public abstract Expression get_expression ();
	public abstract Statement get_assignment (Expression parent_access);
	
	public abstract void resolve (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError;
	
}

