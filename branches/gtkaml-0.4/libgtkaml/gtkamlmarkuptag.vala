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
	
	//filled by the resolver
	public DataType data_type {get ; set;}
	
	public virtual void parse () {
	}

	public virtual void resolve (MarkupResolver resolver) {
		//TODO data_type
	}
	
	public virtual void generate (MarkupResolver resolver) {
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

}

