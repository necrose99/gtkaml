using GLib;
using Vala;

/**
 * Represents a tag with g:private or g:public which will be declared as a class member
 */
public class Gtkaml.MarkupMember : MarkupSubTag {

	public string member_name { get; private set; }
	public SymbolAccessibility access {get; private set;}

	public MarkupMember (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, string member_name, SymbolAccessibility access, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
		this.member_name = member_name;
		this.access = access;
	}
	
	public void generate_property (CodeVisitor visitor) {
		var unresolved_type = new UnresolvedType.from_symbol (new UnresolvedSymbol (tag_namespace, tag_name));
		
		PropertyAccessor getter = new PropertyAccessor (true, false, false, unresolved_type.copy (), null, source_reference);
		PropertyAccessor setter = new PropertyAccessor (false, true, false, unresolved_type.copy (), null, source_reference);
		
		Property p = new Property (member_name, unresolved_type, getter, setter, source_reference);
		p.access = access;
		
		//private field
		var field_type = unresolved_type.copy ();
		p.field = new Field ("_%s".printf (p.name), field_type, p.default_expression, p.source_reference);
				
		markup_class.add_property (p);
	}
	
		
}
