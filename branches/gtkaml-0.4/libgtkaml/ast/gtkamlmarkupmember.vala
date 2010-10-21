using GLib;
using Vala;

/**
 * Represents a tag with g:private or g:public which will be declared as a class member
 */
public class Gtkaml.MarkupMember : MarkupSubTag {

	protected string member_name { get; private set; }
	protected SymbolAccessibility access {get; private set;}

	public MarkupMember (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, string member_name, SymbolAccessibility access, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
		this.member_name = member_name;
		this.access = access;
	}

	public override string me { get { return member_name; }}

	public override void generate_public_ast (MarkupParser parser) {
		generate_property ();
	}
	
	public override MarkupTag? resolve (MarkupResolver resolver) {
		return base.resolve (resolver);
	}
	
	public override void generate (MarkupResolver resolver) {
		generate_construct_member ();
		generate_add ();
	}
	
	private void generate_property () {
		var variable_type = data_type.copy ();
		PropertyAccessor getter = new PropertyAccessor (true, false, false, variable_type, null, source_reference);
		
		variable_type = data_type.copy ();
		PropertyAccessor setter = new PropertyAccessor (false, true, false, variable_type, null, source_reference);
		
		variable_type = data_type.copy ();
		Property p = new Property (member_name, variable_type, getter, setter, source_reference);
		p.access = access;
		
		p.field = new Field ("_%s".printf (p.name), variable_type.copy (), p.initializer, p.source_reference);
		p.field.access = SymbolAccessibility.PRIVATE;
		
		markup_class.add_property (p);
	}
	
	private void generate_construct_member ()
	{
		var initializer = get_initializer ();
		var assignment = new Assignment (new MemberAccess.simple (me, source_reference), initializer, AssignmentOperator.SIMPLE, source_reference);
		
		markup_class.constructor.body.add_statement (new ExpressionStatement (assignment, source_reference));
	}
}
