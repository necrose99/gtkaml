using GLib;
using Vala;

/**
 * TODO:
 * Gtkaml SymbolResolver's  responsibilities:
 * - determine if an attribute is a field or a signal and use = or += appropiately
 * Literal attribute values:
 * - determine the type of the literal field attribute (boolean, string and enum)
 * - determine the method reference for the literal signal attribute
 * Expression attribute values:
 * - signals: use the result of lambda parsing add the signal parameters
 * - fields: use the expression of the lambda as field assignment
 */
public class Gtkaml.MarkupResolver : SymbolResolver {

	public ImplicitsStore implicits_store;

	public new void resolve (CodeContext context) {
		
		base.resolve (context);
	}

	public override void visit_class (Class cl) {
	
		if (cl is MarkupClass) {
			var mcl = cl as MarkupClass;
			resolve_creation_method (mcl);
		
			foreach (var child_tag in mcl.get_child_tags ())
			{
				if (child_tag is MarkupMember)
					message ("found child tag %s", (child_tag as MarkupMember).member_name);
				else if (child_tag is UnresolvedMarkupSubTag) 
					message ("found child tag %s", (child_tag as UnresolvedMarkupSubTag).tag_name);
			}
		}
		base.visit_class (cl);
	}	

	public override void visit_property (Property prop) {
		if (prop is MarkupMember) message ("hoooooraaaay");
		base.visit_property (prop);
	}

	public void resolve_creation_method (MarkupClass markup_class) {
		//generate Constructor AST
		CreationMethod creation_method = new CreationMethod(markup_class.name, null, markup_class.source_reference);
		creation_method.access = SymbolAccessibility.PUBLIC;
		var block = new Block (markup_class.source_reference);
	
		//TODO: determine the base() to call..
		var base_call = new MethodCall (new BaseAccess (markup_class.source_reference), markup_class.source_reference);
		base_call.add_argument (new BooleanLiteral (false, markup_class.source_reference));
		base_call.add_argument (new IntegerLiteral ("0", markup_class.source_reference));
		
		block.add_statement ( new ExpressionStatement (base_call, markup_class.source_reference));
		creation_method.body = block;
		markup_class.add_method (creation_method);
	
	}
}
