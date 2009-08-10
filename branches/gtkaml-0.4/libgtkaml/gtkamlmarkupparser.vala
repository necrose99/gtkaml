using GLib;
using Vala;

/** the parser for the moment simulates the following gtkaml file:
 *
 * <VBox xmlns:g="http://gtkaml.org/0.2" xmlns="Gtk" g:name="MyVBox">  
 *       <Label label="_Hello" with-mnemonic="true" expand="false" fill="false" padding="0" />
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
	
	void parse_file (SourceFile source_file) {

		// xmlns="Gtk"
		var gtk_namespace = new MarkupNamespace (null, "Gtk");
		gtk_namespace.explicit_prefix = false;
		source_file.add_using_directive (new UsingDirective (gtk_namespace));

		// <VBox g:name="MyVBox">
		var root = new MarkupClass ("MyVBox");
		root.add_base_type (new UnresolvedType.from_symbol (new UnresolvedSymbol (gtk_namespace, "VBox")));
		source_file.add_node (root);
		context.root.add_class (root);
		
		// <Label label="_Hello" with-mnemonic="true" expand="false" fill="false" padding="0" />
		var label = new UnresolvedMarkupSubTag (root, "Label");
		label.add_markup_attribute (new MarkupAttribute ("label", "_Hello"));
		label.add_markup_attribute (new MarkupAttribute ("with-mnemonic", "true"));
		label.add_markup_attribute (new MarkupAttribute ("expand", "false"));
		label.add_markup_attribute (new MarkupAttribute ("fill", "false"));
		label.add_markup_attribute (new MarkupAttribute ("padding", "0"));
		
		root.add_child_tag (label);
		
		//<Entry label="ok" g:public='entry' clicked='entry.text="text changed"' />
		var entry = new MarkupMember (root, "Entry", "entry", SymbolAccessibility.PUBLIC);
		entry.add_markup_attribute (new MarkupAttribute ("label", "ok"));
		entry.add_markup_attribute (new MarkupAttribute ("clicked", "entry.text=\"text changed\""));
		
		root.add_child_tag (entry);
		
	}
}


