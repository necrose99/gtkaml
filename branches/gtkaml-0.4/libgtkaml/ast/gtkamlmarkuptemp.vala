using GLib;
using Vala;

/**
 * Markup tag that has no g:private or g:public gtkaml attribute, therefore is local to the construct method
 */
public class Gtkaml.MarkupTemp : MarkupSubTag {
	private string temp_name;
	
	public override string me { get { return temp_name; } }
	
	public MarkupTemp (MarkupTag parent_tag, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null)
	{
		base (parent_tag, tag_name, tag_namespace, source_reference);
		//FIXME: get_temp_name is weird
		temp_name = markup_class.get_temp_name ();
	}
	
	public override void generate_public_ast () {
	
	}

	public override void resolve (MarkupResolver resolver) {
		base.resolve (resolver);
	}
	
	public override void generate (MarkupResolver resolver) {
		generate_construct_local ();
	}
	
	private void generate_construct_local() {		
		
		//convert unresolvedsymbol.inner.inner.innner to memberaccess.inner.inner.inner
		MemberAccess namespace_access = null;
		UnresolvedSymbol ns = tag_namespace;
		while (ns is UnresolvedSymbol) {
			namespace_access = new MemberAccess(namespace_access, ns.name, source_reference);
			ns = ns.inner;
		}
		var member_access = new MemberAccess (namespace_access, tag_name, source_reference);
		member_access.creation_member = true;
		var initializer = new ObjectCreationExpression (member_access, source_reference);
		
		//TODO: determine the initialize to call from MarkupHintsStore
		initializer.add_argument (new StringLiteral ("\"_Hello\"", source_reference));
		
		DataType variable_type = resolved_type.copy ();
		variable_type.value_owned = true;
		variable_type.nullable = false;
		variable_type.is_dynamic = false;

		//FIXME: use variable_type instead of type inference.. but why does it look like nullable?		
		var local_variable = new LocalVariable (null, me,  initializer, source_reference);
		var local_declaration = new DeclarationStatement (local_variable, source_reference);
		
		markup_class.constructor.body.add_statement (local_declaration);
	}
}
