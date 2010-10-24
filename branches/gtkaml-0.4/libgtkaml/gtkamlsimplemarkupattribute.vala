using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.SimpleMarkupAttribute : Object, MarkupAttribute {
	public string attribute_name {get { return _attribute_name; }}
	public DataType target_type { get; set; }

	private SourceReference? source_reference;
	private string _attribute_name;
	private Expression _attribute_expression;
	private Vala.Signal _signal;

	public string? attribute_value {get; private set;}
	
	public SimpleMarkupAttribute (string attribute_name, string? attribute_value, SourceReference? source_reference = null) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
		this.source_reference = source_reference;
	}

	public SimpleMarkupAttribute.with_type (string attribute_name, string? attribute_value, DataType target_type, SourceReference? source_reference = null) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
		this.target_type = target_type;
		this.source_reference = source_reference;
	}
	
	public SimpleMarkupAttribute.with_expression (string attribute_name, Expression expression, SourceReference? source_reference)
	{
		this._attribute_name = attribute_name;
		this._attribute_expression = expression;
		this.source_reference = source_reference;
	}
	
	public Expression get_expression () {
		if (_attribute_expression != null) {
			return _attribute_expression;
		}
		
		assert (target_type != null);
		var type_name = target_type.data_type.get_full_name ();
		if (type_name == "string") {
			return new StringLiteral ("\"" + attribute_value + "\"", source_reference);
		} else if (type_name == "bool") {
			//TODO: full boolean check 
			return new BooleanLiteral (attribute_value == "true", source_reference);
		} else if (type_name == "int" || type_name == "uint") {
			return new IntegerLiteral (attribute_value, source_reference);
		} else {
			Report.error (source_reference, "Error: attribute literal of '%s' type found\n".printf (target_type.data_type.get_full_name ()));
		}
		assert_not_reached ();//TODO remove this?
	}

	public Statement get_assignment (Expression parent_access) {
		var attribute_access = new MemberAccess (parent_access, attribute_name, source_reference);
		Assignment assignment;
		if (_signal != null) {
			//TODO: use connect ()
			assignment = new Assignment (attribute_access, get_expression (), AssignmentOperator.ADD, source_reference);
		} else {
			assignment = new Assignment (attribute_access, get_expression (), AssignmentOperator.SIMPLE, source_reference);
		}
		return new ExpressionStatement (assignment);
	}
	
	public void resolve (MarkupResolver resolver, MarkupTag markup_tag) throws ParseError {

		assert (markup_tag.resolved_type is ObjectType);
		var cl = ((ObjectType)markup_tag.resolved_type).type_symbol;
		
		Symbol? resolved_attribute = resolver.search_symbol (cl, attribute_name);
		
		if (resolved_attribute is Property)
		{
			target_type = ((Property)resolved_attribute).property_type.copy ();
		} else if (resolved_attribute is Field) {
			target_type = ((Field)resolved_attribute).variable_type.copy ();
		} else if (resolved_attribute is Vala.Signal) {
			_signal = (Vala.Signal)resolved_attribute;
		} else {
			throw new ParseError.SYNTAX ("Unkown attribute type %s.%s".printf (cl.name, attribute_name));
		}
		
		string stripped_value = attribute_value.strip ();
		if (stripped_value.has_prefix ("{")) {
			if (stripped_value.has_suffix ("}")) {
				string code_source = stripped_value.substring (1, stripped_value.length - 2);
				if (_signal != null) {
					var stmts = resolver.vala_parser.parse_statements (markup_tag.markup_class.name, markup_tag.me, attribute_name, code_source);
					var lambda = new LambdaExpression.with_statement_body(stmts, source_reference);

					lambda.add_parameter ("target");
					foreach (var parameter in _signal.get_parameters ()) {
						lambda.add_parameter (parameter.name);
					}
					
					_attribute_expression = lambda;
				} else {
					_attribute_expression = resolver.vala_parser.parse_expression (markup_tag.markup_class.name, markup_tag.me, attribute_name, code_source);
				}
			} else {
				Report.error (source_reference, "Unmatched closing brace in %'s value.".printf (attribute_name));
			}
		}

	}

}

