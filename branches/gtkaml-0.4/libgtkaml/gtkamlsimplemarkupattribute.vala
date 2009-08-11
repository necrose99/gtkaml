using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.SimpleMarkupAttribute : Object, MarkupAttribute {
	public string attribute_name {get { return _attribute_name; }}
	public Expression attribute_expression { get { return _attribute_expression; }}

	private string _attribute_name;
	private Expression _attribute_expression;

	private string attribute_value {get; set;}
	
	public SimpleMarkupAttribute (string attribute_name, string attribute_value) {
		this._attribute_name = attribute_name;
		this.attribute_value = attribute_value;
	}
}

