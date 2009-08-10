using GLib;
using Vala;

/*
 * MarkupSubTag is a MarkupTag that has itself a parent: 
 * parent_tag, parent_class, and g:existing, g:standalone, g:construct, g:private etc.
 */
public interface Gtkaml.MarkupSubTag : MarkupTag {
	/**
	 * The class this tag is defined in
	 */
	public abstract MarkupClass get_parent_class ();
			
	/**
	 * The parent MarkupTag
	 */
	public abstract MarkupTag get_parent_tag ();
	
	public abstract void set_parent_tag (MarkupTag parent_tag);
}
