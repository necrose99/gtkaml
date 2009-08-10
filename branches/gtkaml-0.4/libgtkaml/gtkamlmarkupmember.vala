using GLib;
using Vala;

/**
 * Represents a widget with g:private or g:public which will be declared as a class member
 */
public class Gtkaml.MarkupMember : UnresolvedMarkupSubTag {

	public string member_name { get; private set; }
	public SymbolAccessibility access {get; private set;}

	public MarkupMember (string member_name, SymbolAccessibility access, Gtkaml.Class parent_class, SourceReference? source_reference)
	{
		base (parent_class, source_reference);
		this.member_name = member_name;
		this.access = access;
	}	
		
}
