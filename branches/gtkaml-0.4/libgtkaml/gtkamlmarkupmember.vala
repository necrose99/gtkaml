using GLib;
using Vala;

/**
 * Represents a tag with g:private or g:public which will be declared as a class member
 */
public class Gtkaml.MarkupMember : UnresolvedMarkupSubTag {

	public string member_name { get; private set; }
	public SymbolAccessibility access {get; private set;}

	public MarkupMember (MarkupClass parent_class, string tag_name, MarkupNamespace tag_namespace, string member_name, SymbolAccessibility access, SourceReference? source_reference = null)
	{
		base (parent_class, tag_name, tag_namespace, source_reference);
		this.member_name = member_name;
		this.access = access;
	}	
		
}
