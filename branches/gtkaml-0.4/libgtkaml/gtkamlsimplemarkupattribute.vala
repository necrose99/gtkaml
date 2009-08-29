using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.SimpleMarkupAttribute : Object, MarkupAttribute {
	public string attribute_name {get { return _attribute_name; }}
	public Expression attribute_expression { get { return _attribute_expression; }}
	public DataType target_type { get { return _target_type; } }

	private string _attribute_name;
	private Expression _attribute_expression;
	private DataType _target_type;

	public string? attribute_value {get; private set;}
	
	public SimpleMarkupAttribute (string attribute_name, string? attribute_value) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
	}

	public SimpleMarkupAttribute.with_type (string attribute_name, string? attribute_value, DataType target_type) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
		this._target_type = target_type;
	}


}

