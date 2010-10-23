using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.SimpleMarkupAttribute : Object, MarkupAttribute {
	public string attribute_name {get { return _attribute_name; }}
	public DataType target_type { get; set; }
	public bool is_signal {get; set;}

	private SourceReference? source_reference;
	private string _attribute_name;
	private Expression _attribute_expression;

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
			if (is_signal) {
				var block = new Block (source_reference);
				block.add_statement (new ExpressionStatement (_attribute_expression));
				var lambda = new LambdaExpression.with_statement_body(block, source_reference);
				//TODO signal parameters w/ lambda.add_parameter;
				return lambda;
			}
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
			stderr.printf ("Error: attribute literal of '%s' type found\n", target_type.data_type.get_full_name ());
		}
		assert_not_reached();
	}

	public Statement get_assignment (Expression parent_access) {
		var attribute_access = new MemberAccess (parent_access, attribute_name, source_reference);
		Assignment assignment;
		if (is_signal) {
			//TODO: use connect ()
			assignment = new Assignment (attribute_access, get_expression (), AssignmentOperator.ADD, source_reference);
		} else {
			assignment = new Assignment (attribute_access, get_expression (), AssignmentOperator.SIMPLE, source_reference);
		}
		return new ExpressionStatement (assignment);
	}
	
	public void resolve (Class owning_class) {
		//search properties
		foreach (var property in owning_class.get_properties ()) {
			if (property.name == attribute_name) {
				target_type = property.property_type.copy ();
				return;
			}
		}

		//search signals
		foreach (var signal in owning_class.get_signals ()) {
			if (signal.name == attribute_name) {
				is_signal = true;
				return;
			}
		}
	}

}

