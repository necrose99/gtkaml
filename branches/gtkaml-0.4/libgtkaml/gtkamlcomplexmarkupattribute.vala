using GLib;
using Vala;

public class Gtkaml.ComplexMarkupAttribute: MarkupTag, MarkupAttribute {

	public string attribute_name {get { assert_not_reached (); }}
	public Expression attribute_expression {get { assert_not_reached(); }}
	public DataType target_type {get { assert_not_reached (); }}
	
	public override string me { get { assert_not_reached(); }}
	
	public override void generate_public_ast () {
		assert_not_reached();
	}
	
	public override MarkupTag? resolve (MarkupResolver resolver) {
		assert_not_reached();
	}	
	
	public override void generate (MarkupResolver resolver) {
		assert_not_reached();
	}


}
