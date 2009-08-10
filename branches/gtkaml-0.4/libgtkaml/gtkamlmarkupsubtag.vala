using GLib;
using Vala;

/*
 * MarkupSubTag is a MarkupTag that has itself a parent: 
 * parent_tag, parent_class, and g:existing, g:standalone, g:construct, g:private etc.
 */
public class Gtkaml.MarkupSubTag : MarkupTag {

	public weak MarkupTag parent_tag {get;set;}

	public MarkupSubTag (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference) {
		base (parent_tag.markup_class, tag_name, tag_namespace, source_reference);
		this.parent_tag = parent_tag;
	}

}
