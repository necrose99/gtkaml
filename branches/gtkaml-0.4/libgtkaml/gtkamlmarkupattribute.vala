using GLib;
using Vala;

/**
 * Represents an attribute of a MarkupTag
 */
public class Gtkaml.MarkupAttribute {
	public string attribute_name {get; set;}
	//TODO: extend this in complex attributes to return the identifier
	//FIXME: virtual
	public string attribute_value {get; set;}
	
	public MarkupAttribute (string attribute_name, string attribute_value) {
		this.attribute_name = attribute_name;
		this.attribute_value = attribute_value;
	}
}

