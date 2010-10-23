using GLib;
using Vala;
using Xml;

public class Gtkaml.MarkupParser : CodeVisitor {

	private CodeContext context;
	private Vala.List<SourceFile> temp_source_files = new Vala.ArrayList<SourceFile> ();

	public void parse (CodeContext context) {
		this.context = context;
		context.accept (this);
	}
	
	public override void visit_source_file (SourceFile source_file) {
		if (source_file.filename.has_suffix (".gtkaml")) {
			parse_file (source_file);
		}
	}

	public void parse_file (SourceFile source_file) {
		MarkupScanner scanner = new MarkupScanner(source_file);
		parse_markup_class (scanner);
	}

	void parse_markup_class (MarkupScanner scanner) {
		parse_gtkaml_uri (scanner);
		
		MarkupNamespace base_ns = parse_namespace (scanner);

		string class_name = parse_identifier (scanner.node->get_ns_prop ("name", scanner.gtkaml_uri));
		string base_name = parse_identifier (scanner.node->name);
		MarkupClass markup_class = new MarkupClass (base_name, base_ns, class_name, scanner.get_src ());
		markup_class.access = SymbolAccessibility.PUBLIC;
		//TODO: create another NS in lieu of target_namespace
		Namespace target_namespace = context.root;
		
		target_namespace.add_class (markup_class);
		//scanner.source_file.add_node (markup_class);

		parse_using_directives (scanner);

		markup_class.markup_root.text = parse_text (scanner);
		parse_attributes (scanner, markup_class.markup_root);
		parse_markup_subtags (scanner, markup_class.markup_root);
		
		markup_class.markup_root.generate_public_ast (this); 
		
	}
	
	string parse_identifier (string identifier) {
		return identifier;
	}

	void parse_using_directives (MarkupScanner scanner) {
		for (Ns* ns = scanner.node->ns_def; ns != null; ns = ns->next) {
			if (ns->href != scanner.gtkaml_uri) 
				parse_using_directive (scanner, ns->href);
		}
	}
	
	void parse_using_directive (MarkupScanner scanner, string ns) {
		var ns_sym = new UnresolvedSymbol (null, parse_identifier(ns), scanner.get_src ());
		var ns_ref = new UsingDirective (ns_sym, ns_sym.source_reference);
		scanner.source_file.add_using_directive (ns_ref);
	}

	MarkupNamespace parse_namespace (MarkupScanner scanner) {
		MarkupNamespace ns = new MarkupNamespace (null, scanner.node->ns->href);
		ns.explicit_prefix = (scanner.node->ns->prefix != null);
		return ns;
	}

	void parse_gtkaml_uri (MarkupScanner scanner) {
		for (Ns* ns = scanner.node->ns_def; ns != null; ns = ns->next) {
			if (ns->href.has_prefix ("http://gtkaml.org")) {
				scanner.gtkaml_uri = ns->href;
				return;
			}
		}
		throw new ParseError.SYNTAX ("No gtkaml namespace found.");
	}
	
	void parse_attributes (MarkupScanner scanner, MarkupTag markup_tag) {
		for (Attr* attr = scanner.node->properties; attr != null; attr = attr->next) {
			if (attr->ns == null) {
				parse_attribute (markup_tag, attr->name, attr->children->content);
			} else
			if (attr->ns->href != scanner.gtkaml_uri) {
				throw new ParseError.SYNTAX ("Attribute prefix not expected: %s".printf (attr->ns->href));
			} 
		}
	}
	
	void parse_attribute (MarkupTag markup_tag, string name, string @value) {
		string stripped_value = @value.strip ();
		string undername = name.replace ("-", "_");
		MarkupAttribute attribute;
		if (stripped_value.has_prefix ("{")) {
			if (stripped_value.has_suffix ("}")) {
				string expression_source = stripped_value.substring (1, stripped_value.length - 2);
				var expression = parse_vala_expression (markup_tag.markup_class.name, markup_tag.me, undername, expression_source);
				attribute = new SimpleMarkupAttribute.with_expression (undername, expression, markup_tag.source_reference);
			} else {
				Report.error (markup_tag.source_reference, "Unmatched closing brace in %'s value.".printf (name));
				return;
			}
		} else {
			attribute = new SimpleMarkupAttribute (undername, @value, markup_tag.source_reference);
		}
		markup_tag.add_markup_attribute (attribute);
	}
	
	string parse_text (MarkupScanner scanner) {
		string text = "";
		for (Xml.Node* node = scanner.node->children; node != null; node = node->next)
		{
			if (node->type != ElementType.CDATA_SECTION_NODE && node->type != ElementType.TEXT_NODE) continue;//TODO break?
			text += node->content + "\n";
		}
		return text.chomp ();
	}
	
	void parse_markup_subtags (MarkupScanner scanner, MarkupTag parent_tag) {
		for (Xml.Node* node = scanner.node->children; node != null; node = node->next)
		{
			if (node->type != ElementType.ELEMENT_NODE) continue;
			
			scanner.node = node;
			if (scanner.node->ns->href == scanner.gtkaml_uri)
				parse_gtkaml_tag (scanner, parent_tag);
			else
				parse_markup_subtag(scanner, parent_tag);
		}
	}
	
	void parse_markup_subtag (MarkupScanner scanner, MarkupTag parent_tag) {
		MarkupSubTag markup_tag;
		string identifier = null;
		if (scanner.node->get_ns_prop ("public", scanner.gtkaml_uri) != null) {
			identifier = parse_identifier (scanner.node->get_ns_prop ("public", scanner.gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag /*TODO:WTF*/, scanner.node->name, parse_namespace (scanner), identifier, SymbolAccessibility.PUBLIC, scanner.get_src ());
		} else
		if (scanner.node->get_ns_prop ("private", scanner.gtkaml_uri) != null) {
			if (identifier != null) throw new ParseError.SYNTAX ("Cannot specify both private and public");
			identifier = parse_identifier (scanner.node->get_ns_prop ("private", scanner.gtkaml_uri));
			markup_tag = new MarkupMember (parent_tag /*TODO:WTF*/, scanner.node->name, parse_namespace (scanner), identifier, SymbolAccessibility.PRIVATE, scanner.get_src ());
		} else {
			markup_tag = new UnresolvedMarkupSubTag (parent_tag /*TODO:WTF*/, scanner.node->name, parse_namespace (scanner), scanner.get_src ());
		}
		
		parent_tag.add_child_tag (markup_tag);
		parse_attributes (scanner, markup_tag);
		markup_tag.generate_public_ast (this);
		
		parse_markup_subtags (scanner, markup_tag);
	}

	void parse_gtkaml_tag (MarkupScanner scanner, MarkupTag parent_tag) {
		message ("found gtkaml tag %s".printf (scanner.node->name)); //TODO
	}
	
	public Class parse_vala_members (string class_name, string members_source) throws ParseError  {
		var temp_source = "public class Temp { %s }".printf (members_source);
		
		var temp_ns = call_vala_parser (temp_source, class_name + "-members");
		if (temp_ns is Namespace && temp_ns.get_classes ().size == 1) {
			return temp_ns.get_classes ().get (0);
		} else {
			throw new ParseError.SYNTAX ("There was an error parsing the code section.");
		}
	}
	
	public Expression parse_vala_expression (string class_name, string target, string target_member, string expression_source) throws ParseError {
		var temp_source = "VoidFunc voidFunc = ()=> %s;".printf (expression_source);
		
		var temp_ns = call_vala_parser (temp_source, class_name + "_" + target + "_" + target_member + "_expression");
		if (temp_ns is Namespace && temp_ns.get_fields ().size == 1 && temp_ns.get_fields ().get (0).initializer is LambdaExpression) {
			var temp_lambda = (LambdaExpression)temp_ns.get_fields ().get (0).initializer;
			return temp_lambda.expression_body;
		} else {
			throw new ParseError.SYNTAX ("There was an error parsing the code section.");
		}
	}
	
	/**
	 * parses a vala source string temporary stored in .gtkaml/what.vala
	 * returns the root namespace
	 */
	protected Namespace call_vala_parser(string source, string temp_filename) {
		var ctx = new CodeContext ();
		var filename = ".gtkaml/" + temp_filename + ".vala";
		
		DirUtils.create_with_parents (".gtkaml", 488 /*0750*/);
		FileUtils.set_contents (filename, source);
		var temp_source_file = new SourceFile (ctx, SourceFileType.SOURCE, filename, source);
		temp_source_files.add (temp_source_file);
		ctx.add_source_file (temp_source_file);
		
		var parser = new Vala.Parser ();
		parser.parse (ctx);
		return ctx.root;
	}


}

