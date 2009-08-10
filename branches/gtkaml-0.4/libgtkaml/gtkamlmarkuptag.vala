using GLib;
using Vala;

/**
 * A tag that is a parent of others. Can be the root tag.
 */ 
public abstract class Gtkaml.MarkupTag {
	
	private Gee.List<MarkupSubTag> child_tags = new Gee.ArrayList<MarkupSubTag> ();
	private Gee.List<MarkupAttribute> markup_attributes = new Gee.ArrayList<MarkupAttribute> ();
	
	public string tag_name {get; set;}
	public MarkupNamespace tag_namespace {get; set;}
	public weak MarkupClass markup_class {get; private set;}
	public SourceReference? source_reference {get; set;}
	
	public DataType data_type {get ; set;}
	
	private DataTypeParent _data_type_parent;
	public DataType resolved_type { 
		get {
			assert (!(_data_type_parent is UnresolvedType));
			return _data_type_parent.data_type;
		}
	}
			
	
	public abstract void generate_public_ast ();

	public virtual void resolve (MarkupResolver resolver) {
		assert (data_type.parent_node is DataTypeParent);
		resolver.visit_data_type (data_type);
	}
	
	public abstract void generate (MarkupResolver resolver);
	
	public MarkupTag (MarkupClass markup_class, string tag_name, MarkupNamespace tag_namespace, SourceReference? source_reference = null) {
		this.markup_class = markup_class;
		this.tag_name = tag_name;
		this.tag_namespace = tag_namespace;
		this.source_reference = source_reference;
		data_type = new UnresolvedType.from_symbol (new UnresolvedSymbol (tag_namespace, tag_name, source_reference));
		_data_type_parent = new DataTypeParent (data_type);
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

}

