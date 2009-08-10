using GLib;
using Vala;

/**
 * parses gtkaml markup
 * re-uses vala parser for CDATA/code nodes 
 * re-uses vala parser for attribute values when surrounded with {} (parses them as lambdas)
 */
public class Gtkaml.Parser : CodeVisitor {

	CodeContext context;
	SourceFile source_file;

	public void parse (CodeContext context) {
		this.context = context;
		context.accept (this);
	}

	/** calls parse_statements on a Class */
	public void parse_code (Class cl, string code) {
		
	}

	/* an attribute text */
	Expression parse_vala_expression (string expression) {
		//TODO: put here the result of Vala.Parser.parse_expression ()
		/*return new BinaryExpression (BinaryOperator.PLUS, 
			new MemberAccess.simple ("a"), 
			new StringLiteral ("\"234\"")
		);
		*/
		return call_vala_parser (expression) ;
	}

	/* a signal text */
	Block parse_vala_block (string lambdaexpression) {
		//TODO: put here the result of Vala.Parser.parse_block ()
		var block = new Block (new SourceReference (this.source_file, 0, 0, 2, 2));
		block.add_statement (
			new ExpressionStatement (
				new Assignment (
					new MemberAccess.simple ("b"),
					//new StringLiteral("\"456\"")
					parse_vala_expression ("VoidFunc voidFunc = ()=> 5 * 5 == 25 ? 3:4;")
				)
			));
//		var lambda = new LambdaExpression.with_statement_body (block, new SourceReference (this.source_file, 0, 0, 2, 2));
//		lambda.add_parameter ("target");
//		return lambda;
		return block;
	}

	Expression call_vala_parser(string content) throws Error 					{
		var ctx = new CodeContext ();
		var source_file = new SourceFile (ctx, "expression.vala", false, content);
		ctx.add_source_file (source_file);
		var parser = new Vala.Parser ();
		parser.parse (ctx);
		Namespace root = ctx.root;
		/* debugging namespace 
		message ("%d fields", root.get_fields ().size);
		message ("%d ", root.get_classes ().size);
		message ("%d ", root.get_constants ().size);
		message ("%d ", root.get_methods ().size);
		message ("%d ", root.get_namespaces ().size);
		Gee.List <LocalVariable> locals = new Gee.ArrayList<LocalVariable>();
		root.get_defined_variables (locals);
		message ("%d ", locals.size );
		message ("%d ", root.get_delegates ().size);
		//*/
		LambdaExpression e =  root.get_fields ().get (0).initializer as LambdaExpression;
		return e.expression_body;
	}

	//CodeVisitor implementation

	public override void visit_source_file (SourceFile sourcefile) {

		if (!sourcefile.filename.has_suffix (".gtkaml")) return;

		Symbol parent = context.root;
		this.source_file = sourcefile;
	
	
		var ns = parent as Namespace;
		var clazz = new MarkupClass("namez");
		
		var markupmember = new MarkupMember ("veebox", 
			SymbolAccessibility.PUBLIC,
			clazz,
			new SourceReference (sourcefile, 4, 3, 2, 1));
		
		clazz.add_child_tag (markupmember);
		
		var method = new Method ("HuangHe", new VoidType(), new SourceReference (sourcefile, 0, 0, 2, 3));
		method.body = parse_vala_block("asd");
		clazz.add_method (method);

		ns.add_class (clazz);
		this.source_file.add_using_directive (new UsingDirective (new UnresolvedSymbol (null, "Gtk", null)));
		this.source_file.add_node (clazz);
		//this.source_file.add_node (markupmember);

		/*
		if (parent is Namespace) {
			var ns = parent as Namespace;
			var class = new MarkupClass ();
			class.name = "Test";
			class.cdata = "public void main() {  } ";
			ns.add_class (class);
		*/
	}

}

