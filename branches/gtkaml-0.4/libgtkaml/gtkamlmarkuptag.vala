using GLib;
using Vala;

/**
 * A tag that is a parent of others. Can be the root tag.
 */ 
public class Gtkaml.MarkupTag {
	
	private Gee.List<MarkupSubTag> child_tags = new Gee.ArrayList<MarkupSubTag> ();
	private Gee.List<MarkupAttribute> markup_attributes = new Gee.ArrayList<MarkupAttribute> ();
	
	public string tag_name {get; set;}
	public MarkupNamespace tag_namespace {get; set;}
	public weak MarkupClass markup_class {get; private set;}
	public SourceReference? source_reference {get; set;}
	
	//filled by the resolver
	public DataType data_type {get ; set;}
	
	public virtual void parse () {
		markup_class.add_base_type (new UnresolvedType.from_symbol (new UnresolvedSymbol (tag_namespace, tag_name)));
	}

	public virtual void resolve (MarkupResolver resolver) {
		//TODO data_type
	}
	
	public virtual void generate (MarkupResolver resolver) {
		generate_creation_method (resolver);
		generate_construct (resolver);
	}
	
	public MarkupTag (MarkupClass markup_class, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null) {
		this.markup_class = markup_class;
		this.tag_name = tag_name;
		this.tag_namespace = tag_namespace;
		this.source_reference = source_reference;
	}

	public Gee.ReadOnlyList<MarkupSubTag> get_child_tags () {
		return new Gee.ReadOnlyList<MarkupSubTag> (child_tags);
	}
	
	public void add_child_tag (MarkupSubTag child_tag) {
		child_tags.add (child_tag);
		child_tag.parent_tag = this;
	}
	
	public void replace_child_tag (MarkupSubTag old_child, MarkupSubTag new_child)
	{
		for (int i = 0; i < child_tags.size; i++) {
			if (child_tags[i] == old_child) {
				child_tags[i] = new_child;
				return;
			}
		}
	}

	public Gee.ReadOnlyList<MarkupAttribute> get_markup_attributes () {
		return new Gee.ReadOnlyList<MarkupAttribute> (markup_attributes);
	}
	
	public void add_markup_attribute (MarkupAttribute markup_attribute) {
		markup_attributes.add (markup_attribute);
	}
	
	/**
	 * generate creation method with base () call
	 */
	private void generate_creation_method (MarkupResolver resolver) {
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
		markup_class.add_method (creation_method);
	}

	private void generate_construct (MarkupResolver resolver) {
		var constructor = new Constructor (markup_class.source_reference);
		constructor.body = new Block (markup_class.source_reference);	
		
		markup_class.constructor = constructor;
	}
	

}

