using Vala;
using Xml;

/* TODO:
 * darn, no #text nodes on generate_public_ast (). back to DOM??!??!
 * MarkupNamespace ?!? Why this + explicit prefix instead of a string??!?
 * parent_tag in markup_subtag constructor!?? and add_child_tag right after?!?
 */

class Gtkaml.TreeParser {
	CodeContext context;

	SourceFile source_file;
	Namespace user_namespace;
	string gtkaml_uri;
	MarkupClass markup_class;
	Doc* whole_doc;
	Xml.Node* scanner;
	
	public TreeParser (CodeContext context)	{
		this.context = context;
		this.whole_doc = null;
		user_namespace = context.root;
	}
	
	~TreeParser () {
		if (whole_doc != null)
			delete whole_doc;
	}
	
	public void parse_file (string filename) {
		source_file = new SourceFile (context, filename);
		whole_doc = Xml.Parser.read_file (source_file.filename, null, ParserOption.NOWARNING);
		if (whole_doc == null) throw new ParseError.SYNTAX("Error parsing %s".printf (source_file.filename));
		scanner = whole_doc->get_root_element ();
		parse_markup_class ();
	}
	
	public void error (string msg, ParserSeverities severities, TextReaderLocator * wha)
	{
		message("Error %s, Severity %d".printf (msg, severities));
	}
	
	SourceReference get_src () {
		return new SourceReference (source_file, (int)scanner->get_line_no (), 0,
			(int)scanner->get_line_no (), 0);
	}
	
	void parse_markup_class () {
		parse_gtkaml_uri ();
		
		MarkupNamespace base_ns = parse_namespace ();

		string class_name = parse_identifier (scanner->get_ns_prop ("name", gtkaml_uri));
		string base_name = parse_identifier (scanner->name);
		markup_class = new MarkupClass (base_name, base_ns, class_name, get_src ());
		//TODO: create another NS in lieu of user_namespace
		user_namespace.add_class (markup_class);
		source_file.add_node (markup_class);

		parse_using_directives ();

		parse_text (markup_class.markup_root);
		parse_attributes (markup_class.markup_root);
		parse_markup_subtags (markup_class.markup_root);
		
		markup_class.markup_root.generate_public_ast (new Gtkaml.MarkupParser ()); //FIXME: use *this*
		
	}
	
	string parse_identifier (string identifier) {
		return identifier;
	}

	void parse_using_directives () {
		for (Ns* ns = scanner->ns_def; ns != null; ns = ns->next) {
			if (ns->href != gtkaml_uri) 
				parse_using_directive (ns->href);
		}
	}
	
	void parse_using_directive (string ns) {
		var ns_sym = new UnresolvedSymbol (null, parse_identifier(ns), get_src ());
		this.source_file.add_using_directive (new UsingDirective (ns_sym, ns_sym.source_reference));
	}

	MarkupNamespace parse_namespace () {
		message (scanner->name);
		message ("%s %s".printf (scanner->ns->prefix, scanner->ns->href));
		MarkupNamespace ns = new MarkupNamespace (null, scanner->ns->href);
		ns.explicit_prefix = (scanner->ns->prefix != null);
		return ns;
	}

	void parse_gtkaml_uri () {
		for (Ns* ns = scanner->ns_def; ns != null; ns = ns->next) {
			if (ns->href.has_prefix ("http://gtkaml.org")) {
				gtkaml_uri = ns->href;
				return;
			}
		}
		throw new ParseError.SYNTAX ("No gtkaml namespace found.");
	}
	
	void parse_attributes (MarkupTag markup_tag) {
		for (Attr* attr = scanner->properties; attr != null; attr = attr->next) {
			message ("attribute %s, value %s, type %d, ns %x".printf (attr->name, attr->children->content, attr->type, (uint)attr->ns));
			if (attr->ns == null) {
				var attribute = new SimpleMarkupAttribute (attr->name, attr->children->content, get_src ());
				markup_tag.add_markup_attribute (attribute);
			} else
			if (attr->ns->href != gtkaml_uri) {
				throw new ParseError.SYNTAX ("Attribute prefix not expected: %s".printf (attr->ns->href));
			} 
		}
	}
	
	void parse_text (MarkupTag markup_tag) {
		markup_tag.text = "";
		for (Xml.Node* node = scanner->children; node != null; node = node->next)
		{
			if (node->type != ElementType.CDATA_SECTION_NODE && node->type != ElementType.TEXT_NODE) continue;
			markup_tag.text += node->content + "\n";
		}
		markup_tag.text = markup_tag.text.chomp ();
	}
	
	void parse_markup_subtags (MarkupTag parent_tag) {
		for (Xml.Node* node = scanner->children; node != null; node = node->next)
		{
			if (node->type != ElementType.ELEMENT_NODE) continue;
			scanner = node;
			parse_markup_subtag(parent_tag);
		}
	}
	
	void parse_markup_subtag (MarkupTag parent_tag) {
		MarkupSubTag markup_tag;
		string identifier = null;
		if (scanner->get_ns_prop ("public", gtkaml_uri) != null) {
			identifier = parse_identifier (scanner->get_ns_prop ("public", gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag /*TODO:WTF*/, scanner->name, parse_namespace (), identifier, SymbolAccessibility.PUBLIC, get_src ());
		}
		if (scanner->get_ns_prop ("private", gtkaml_uri) != null) {
			if (identifier != null) throw new ParseError.SYNTAX ("Cannot specify both private and public");
			identifier = parse_identifier (scanner->get_ns_prop ("private", gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag /*TODO:WTF*/, scanner->name, parse_namespace (), identifier, SymbolAccessibility.PRIVATE, get_src ());
		} else {
			markup_tag = new UnresolvedMarkupSubTag (parent_tag /*TODO:WTF*/, scanner->name, parse_namespace (), get_src ());
		}
		
		parent_tag.add_child_tag (markup_tag);
		parse_attributes (markup_tag);
		markup_tag.generate_public_ast (new Gtkaml.MarkupParser ()); //FIXME: use *this*
		
		parse_markup_subtags (markup_tag);
	}
}

int main (string[] argv)
{
	try {
		var code_context = new CodeContext();
		Vala.CodeContext.push (code_context);
		new Gtkaml.TreeParser (code_context).parse_file (argv[1]);
		
		var code_writer = new CodeWriter (true, true);
		code_writer.write_file (code_context, "out.vala");
		return 0;
	} catch {
		return -1;
	}
}
