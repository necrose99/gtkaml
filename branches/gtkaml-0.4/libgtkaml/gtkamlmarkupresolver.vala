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
		implicits_store = new ImplicitsStore (context);
		implicits_store.parse ();
		base.resolve (context);
	}

	public override void visit_class (Class cl) {
	
		if (cl is MarkupClass) {
			visit_markup_class (cl as MarkupClass);
		}
		base.visit_class (cl);
	}
	
	public void visit_markup_class (MarkupClass mcl) {
		generate_properties (mcl, mcl);
		generate_creation_method (mcl);
		generate_construct (mcl);
	}

	private void generate_properties (MarkupClass markup_class, MarkupTag current_tag) {
		foreach (MarkupSubTag markup_subtag in current_tag.get_child_tags ()) {
			if (markup_subtag is MarkupMember) {
				generate_property (markup_class, markup_subtag as MarkupMember);
			} 
			
			generate_properties(markup_class, markup_subtag);
		}
	}
	
	private void generate_property (MarkupClass markup_class, MarkupMember markup_member) {
		PropertyAccessor getter = new PropertyAccessor (true, false, false, markup_member.to_unresolved_type (), null, markup_member.source_reference);
		PropertyAccessor setter = new PropertyAccessor (false, true, false, markup_member.to_unresolved_type (), null, markup_member.source_reference);
		
		Property p = new Property (markup_member.member_name, markup_member.to_unresolved_type (), getter, setter, markup_member.source_reference);
		p.access = markup_member.access;
		
		//private field
		var field_type = markup_member.to_unresolved_type ();
		p.field = new Field ("_%s".printf (p.name), field_type, p.default_expression, p.source_reference);
				
		markup_class.add_property (p);
	}

	/**
	 * generate creation method with base () call
	 * CHANTIER
	 */
	private void generate_creation_method (MarkupClass markup_class) {
		CreationMethod creation_method = new CreationMethod(markup_class.name, null, markup_class.source_reference);
		creation_method.access = SymbolAccessibility.PUBLIC;
		
		//TODO: determine the base() to call from ImplicitsStore
		//TODO: take into account the fact that, if the arguments are actually {code} expressions or complex attributes
		//      .. they can't be used in this scenario:(
		var base_call = new MethodCall (new BaseAccess (markup_class.source_reference), markup_class.source_reference);
		base_call.add_argument (new BooleanLiteral (false, markup_class.source_reference));
		base_call.add_argument (new IntegerLiteral ("0", markup_class.source_reference));

		var block = new Block (markup_class.source_reference);
		block.add_statement (new ExpressionStatement (base_call, markup_class.source_reference));
		creation_method.body = block;
		
		//FIXME: add this after vala base() bug is solved - otherwise, refactor to use setters,..
		//markup_class.add_method (creation_method);
	}
	
	private void generate_construct (MarkupClass markup_class) {
		var constructor = new Constructor (markup_class.source_reference);
		constructor.body = new Block (markup_class.source_reference);	
		
		//TODO: this code will currently assume that *creation methods* parameters don't create dependencies between properties 
		// or between properties and locals or etc.		
		generate_construct_locals (markup_class, markup_class, constructor.body);
		initialize_properties (markup_class, constructor.body);
		
		generate_adds (markup_class, constructor.body);
		
		markup_class.constructor = constructor;
	}
	
	private void initialize_properties (MarkupClass markup_class, Block statements) {
		//TODO
	}
	
	private void generate_construct_locals (MarkupClass markup_class, MarkupTag current_tag, Block statements) {
		//CHANTIER
		var initializer = new ObjectCreationExpression (new MemberAccess (null, "Label", markup_class.source_reference), 
			markup_class.source_reference);
		
		//TODO: determine the initialize to call from ImplicitsStore
		initializer.add_argument (new StringLiteral ("\"_Hello\"", markup_class.source_reference));
		
		var local_variable = new LocalVariable (null, "label0",  initializer, markup_class.source_reference);
		var local_declaration = new DeclarationStatement (local_variable, markup_class.source_reference);
		
		statements.add_statement (local_declaration);
	}
	
	private void generate_adds (MarkupClass markup_class, Block statements) {
		//TODO
	}
	
}
