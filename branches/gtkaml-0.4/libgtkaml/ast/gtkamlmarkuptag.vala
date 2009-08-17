using GLib;
using Vala;

/**
 * A tag that is a parent of others. Can be the root tag.
 * 
 * You have to implement:
 * - generate_public_ast
 * - (optionally) resolve
 * - generate
 */ 
public abstract class Gtkaml.MarkupTag : Object {
	
	protected Gee.List<MarkupSubTag> child_tags = new Gee.ArrayList<MarkupSubTag> ();
	protected Gee.List<MarkupAttribute> markup_attributes = new Gee.ArrayList<MarkupAttribute> ();

	/** not-ignorable text nodes concatenated */
	public string text {get; set;}
	/** the actual tag encountered */	
	public string tag_name {get; set;}
	/** the Vala namespace */
	public MarkupNamespace tag_namespace {get; set;}
	/** the Vala class in which this tag was defined */
	public weak MarkupClass markup_class {get; private set;}
	public SourceReference? source_reference {get; set;}
	
	/** the expression to be used (either 'this', or 'property name' or 'temporary variable name') when using the tag */
	public abstract string me {get;}
	
	/** usually an Unresolved data type created from the tag name/namespace */
	public DataType data_type {get ; set;}
	
	private DataTypeParent _data_type_parent;
	/** the determined data type - see resolve() */
	public DataType resolved_type { 
		get {
			assert (!(_data_type_parent.data_type is UnresolvedType));
			return _data_type_parent.data_type;
		}
	}
	
	protected Gee.List<MarkupAttribute> creation_parameters = new Gee.ArrayList<MarkupAttribute> ();
	
	public MarkupTag (MarkupClass markup_class, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null) {
		this.markup_class = markup_class;
		this.tag_name = tag_name;
		this.tag_namespace = tag_namespace;
		this.source_reference = source_reference;
		
		this.data_type = new UnresolvedType.from_symbol (new UnresolvedSymbol (tag_namespace, tag_name, source_reference));
		this.data_type.value_owned = true;
		
		_data_type_parent = new DataTypeParent (data_type);
	}

	/**
	 * Called when parsing.
	 * This only generates placeholder Vala AST so that the Parser can move on.
	 * e.g. the class itself, its public properties go here.
	 */
	public abstract void generate_public_ast ();

	/**
	 * Called when Gtkaml is resolving. 
	 * Here replacements in the Gtkaml AST can be made (e.g. UnresolvedMarkupTag -> MarkupTemp).
	 * Tags to remove must return 'false' here so that the SymbolResolver can remove them later
	 */
	public virtual MarkupTag? resolve (MarkupResolver resolver) {
		resolver.visit_data_type (data_type);
		return this;
	}
	
	/** 
	 * Called after Gtkaml finished resolving, before Vala resolver kicks in.
	 * Final AST generation phase (all AST)
	 */
	public abstract void generate (MarkupResolver resolver);
	
	public Gee.ReadOnlyList<MarkupSubTag> get_child_tags () {
		return new Gee.ReadOnlyList<MarkupSubTag> (child_tags);
	}
	
	public void add_child_tag (MarkupSubTag child_tag) {
		child_tags.add (child_tag);
		child_tag.parent_tag = this;
	}
	
	/** replaces a child tag and moves all its attributes and subtags to the new one */
	public void replace_child_tag (MarkupSubTag old_child, MarkupSubTag new_child) {
		for (int i = 0; i < child_tags.size; i++) {
			if (child_tags[i] == old_child) {
				foreach (MarkupSubTag child_tag in child_tags[i].get_child_tags ())
					new_child.add_child_tag (child_tag);
				foreach (MarkupAttribute attribute in child_tags[i].get_markup_attributes ())
					new_child.add_markup_attribute (attribute);				
				child_tags[i] = new_child;
				return;
			}
		}
	}
	
	public void remove_child_tag (MarkupSubTag old_child) {
		child_tags.remove (old_child);
	}

	public Gee.ReadOnlyList<MarkupAttribute> get_markup_attributes () {
		return new Gee.ReadOnlyList<MarkupAttribute> (markup_attributes);
	}
	
	public void add_markup_attribute (MarkupAttribute markup_attribute) {
		markup_attributes.add (markup_attribute);
	}

}

