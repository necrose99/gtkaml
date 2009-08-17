using GLib;
using Vala;

/** the parser for the moment simulates the following gtkaml file:
 *
 * <VBox xmlns:g="http://gtkaml.org/0.2" xmlns="Gtk" g:name="MyVBox">  
 *       <Label with-mnemonic="true" expand="false" fill="false" padding="0">
 *             <label>_Hello</label>
 *       </Label>
 *       <Entry label="ok" g:public='entry' clicked='entry.text="text changed"' />
 * </VBox>
 */
public class Gtkaml.MarkupParser : CodeVisitor {

	private CodeContext context;

	public void parse (CodeContext context) {
		this.context = context;
		context.accept (this);
	}
	
	public override void visit_source_file (SourceFile source_file) {
		if (source_file.filename.has_suffix (".gtkaml")) {
			parse_file (source_file);
		}
	}
	
	//Note to self: the parser engine should be able to tell tags with content beforehand (SimpleAttributes)
	/** 
	 * creates appropriate Gtkaml AST nodes (MarkupClass, MarkupSubTag, UnresolvedMarkupSubTag, MarkupMember)
	 * and calls generate_public_ast () on each.
	 */
	void parse_file (SourceFile source_file) {

		// xmlns="Gtk"
		var gtk_namespace = new MarkupNamespace (null, "Gtk");
		gtk_namespace.explicit_prefix = false;
		source_file.add_using_directive (new UsingDirective (gtk_namespace));

		// <VBox g:name="MyVBox">
		var root = new MarkupClass ("VBox", gtk_namespace, "MyVBox", new SourceReference (source_file, 1, 0, 1, 66));
		root.access = SymbolAccessibility.PUBLIC;
		root.markup_root.generate_public_ast ();
		
		source_file.add_node (root);
		context.root.add_class (root);
		
		// <Label label="_Hello" with-mnemonic="true" expand="false" fill="false" padding="0" />
		var label = new UnresolvedMarkupSubTag (root.markup_root, "Label", gtk_namespace, new SourceReference (source_file, 2, 6, 2, 91));
		//label.add_markup_attribute (new SimpleMarkupAttribute ("label", "_Hello"));
		label.add_markup_attribute (new SimpleMarkupAttribute ("with-mnemonic", "true"));
		label.add_markup_attribute (new SimpleMarkupAttribute ("expand", "false"));
		label.add_markup_attribute (new SimpleMarkupAttribute ("fill", "false"));
		label.add_markup_attribute (new SimpleMarkupAttribute ("padding", "0"));
		label.generate_public_ast ();
		
		root.markup_root.add_child_tag (label);
		
		var label_label = new UnresolvedMarkupSubTag (label, "label", gtk_namespace, new SourceReference (source_file, 3, 6, 3, 91));
		
		//<Entry label="ok" g:public='entry' clicked='entry.text="text changed"' />
		var entry = new MarkupMember (root.markup_root, "Entry", gtk_namespace, "entry", SymbolAccessibility.PUBLIC, new SourceReference (source_file, 5, 6, 5, 79));
		entry.add_markup_attribute (new SimpleMarkupAttribute ("label", "ok"));
		entry.add_markup_attribute (new SimpleMarkupAttribute ("clicked", "entry.text=\"text changed\""));
		entry.generate_public_ast ();
		
		root.markup_root.add_child_tag (entry);
		
	}
}

