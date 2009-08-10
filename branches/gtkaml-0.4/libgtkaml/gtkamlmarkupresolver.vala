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
		//generate_properties (mcl, mcl);
		generate_creation_method (mcl);
		generate_construct (mcl);
	}
	
	void visit_markup_member (MarkupMember member) {
		member.generate_property (this);
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
		generate_construct_locals (markup_class.markup_root, constructor.body);
		initialize_properties (markup_class, constructor.body);
		
		generate_adds (markup_class, constructor.body);
		
		markup_class.constructor = constructor;
	}
	
	private void initialize_properties (MarkupClass markup_class, Block statements) {
		//TODO
	}
	
	private void generate_construct_locals (MarkupTag current_tag, Block statements) {
		//CHANTIER
		var initializer = new ObjectCreationExpression (new MemberAccess (null, "Label", current_tag.source_reference), 
			current_tag.markup_class.source_reference);
		
		//TODO: determine the initialize to call from ImplicitsStore
		initializer.add_argument (new StringLiteral ("\"_Hello\"", current_tag.source_reference));
		
		var local_variable = new LocalVariable (null, "label0",  initializer, current_tag.source_reference);
		var local_declaration = new DeclarationStatement (local_variable, current_tag.source_reference);
		
		statements.add_statement (local_declaration);
	}
	
	private void generate_adds (MarkupClass markup_class, Block statements) {
		//TODO
	}
	
}
