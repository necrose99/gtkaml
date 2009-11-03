using Vala;
using Xml;

/* TODO:
 * darn, no #text nodes on generate_public_ast (). back to DOM??!??!
 * MarkupNamespace ?!? Why this + explicit prefix instead of a string??!?
 * parent_tag in markup_subtag constructor!?? and add_child_tag right after?!?
 */

class Gtkaml.Reader {
	TextReader scanner;
	SourceFile source_file;
	Namespace user_namespace;
	string gtkaml_uri;
	MarkupClass markup_class;
	CodeContext context;
	Doc* whole_doc; /*FIXME: require libxml 2.7.4 and get rid of this*/
	
	public Reader (CodeContext context)
	{
		this.context = context;
		user_namespace = context.root;
	}
	
	public void error (string msg, ParserSeverities severities, TextReaderLocator * wha)
	{
		message("Error %s, Severity %d".printf (msg, severities));
	}
	
	public void parse_file (string filename) {
		Xml.Parser.init ();
		source_file = new SourceFile (context, filename);
		//scanner = new TextReader.filename (filename);
		whole_doc = Xml.Parser.read_file (filename, null, ParserOption.NOWARNING);
		scanner = new TextReader.walker (whole_doc);
		parse_markup_class ();
	}
	
	inline ReaderType current () {
		return (ReaderType)scanner.node_type ();
	}
	
	inline void next () {
		switch (scanner.read ()) {
			case 0:  throw new ParseError.SYNTAX ("Unexpected end of document"); 
			case 1:  return;
			default: throw new ParseError.SYNTAX ("Parser error"); 
		}
	}
		
	inline void expect (ReaderType type) throws ParseError
	{
		if (current () != type)
			throw new ParseError.SYNTAX ("Expecting %d, got %d".printf (type, current()));  /*FIXME*/
	}
	
	SourceReference get_src () {
		return new SourceReference (source_file, scanner.get_parser_line_number (), scanner.get_parser_column_number (),
			scanner.get_parser_line_number (), scanner.get_parser_column_number ());
	}
	
	void parse_markup_class () {
		next ();
		if (current () == ReaderType.XML_DECLARATION) next ();
		expect (ReaderType.ELEMENT);
		
		parse_gtkaml_uri ();
		
		MarkupNamespace base_ns = parse_namespace ();

		string class_name = parse_identifier (scanner.get_attribute_ns ("name", gtkaml_uri));
		string base_name = parse_identifier (scanner.local_name ());
		markup_class = new MarkupClass (base_name, base_ns, class_name, get_src ());
		//TODO: create another NS in lieu of user_namespace
		user_namespace.add_class (markup_class);
		source_file.add_node (markup_class);

		parse_using_directives ();
		
		parse_attributes (markup_class.markup_root);
		parse_markup_subtags (markup_class.markup_root);
		
		markup_class.markup_root.generate_public_ast (new Gtkaml.MarkupParser ()); //FIXME: use *this*
		
	}
	
	string parse_identifier (string identifier) {
		return identifier;
	}

	void parse_using_directives () {
		if (1 == scanner.move_to_first_attribute ()) do {
			if (scanner.is_namespace_decl () == 1 && scanner.value () != gtkaml_uri) {
				parse_using_directive (scanner.value ());
			}
		} while (1 == scanner.move_to_next_attribute ());
		scanner.move_to_element ();
	}
	
	void parse_using_directive (string ns) {
		var ns_sym = new UnresolvedSymbol (null, parse_identifier(ns), get_src ());
		this.source_file.add_using_directive (new UsingDirective (ns_sym, ns_sym.source_reference));
	}

	MarkupNamespace parse_namespace () {
		message ("%s %s".printf (scanner.local_name (), scanner.namespace_uri ()));
		MarkupNamespace ns = new MarkupNamespace (null, scanner.namespace_uri ());
		ns.explicit_prefix = (scanner.prefix () != null);
		return ns;
	}

	void parse_gtkaml_uri () {
		if (1 == scanner.move_to_first_attribute ()) do {
			if (scanner.value ().has_prefix ("http://gtkaml.org")) {
				gtkaml_uri = scanner.value ();
				scanner.move_to_element ();
				return;
			}
		} while (1 == scanner.move_to_next_attribute ());
		throw new ParseError.SYNTAX ("No gtkaml namespace found.");
	}
	
	void parse_attributes (MarkupTag markup_tag) {
		if (1 == scanner.move_to_first_attribute ()) do {
			if (scanner.prefix () == null) {
				var attribute = new SimpleMarkupAttribute ( scanner.local_name (), scanner.value (), get_src ());
				markup_tag.add_markup_attribute (attribute);
			}
		} while (1 == scanner.move_to_next_attribute ());
		scanner.move_to_element ();
	}
	
	void parse_markup_subtags (MarkupTag parent_tag) {
		if (1 == scanner.is_empty_element ()) {
			next ();
			return;
		}
		
		while (true)  {
			next ();
			switch (scanner.node_type ())  {
				case ReaderType.END_ELEMENT:
					return;
				case ReaderType.ELEMENT:
					parse_markup_subtag (parent_tag);
					break;
				case ReaderType.TEXT:
					parent_tag.text = scanner.value ();
					break;
			}
		}
	}
	
	void parse_markup_subtag (MarkupTag parent_tag) {
		MarkupSubTag markup_tag;
		string identifier = null;
		if (scanner.get_attribute_ns ("public", gtkaml_uri) != null) {
			identifier = parse_identifier (scanner.get_attribute_ns ("public", gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag /*TODO:WTF*/, scanner.local_name (), parse_namespace (), identifier, SymbolAccessibility.PUBLIC, get_src ());
		}
		if (scanner.get_attribute_ns ("private", gtkaml_uri) != null) {
			if (identifier != null) throw new ParseError.SYNTAX ("Cannot specify both private and public");
			identifier = parse_identifier (scanner.get_attribute_ns ("private", gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag /*TODO:WTF*/, scanner.local_name (), parse_namespace (), identifier, SymbolAccessibility.PRIVATE, get_src ());
		} else {
			markup_tag = new UnresolvedMarkupSubTag (parent_tag /*TODO:WTF*/, scanner.local_name (), parse_namespace (), get_src ());
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
		new Gtkaml.Reader (new CodeContext ()).parse_file (argv[1]);
		return 0;
	} catch {
		return -1;
	}
}
