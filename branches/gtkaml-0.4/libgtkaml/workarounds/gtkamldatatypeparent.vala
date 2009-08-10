using GLib;
using Vala;

/**
 * this class here only to make visit_data_type work
 */
class Gtkaml.DataTypeParent : Symbol {
	private weak DataType _data_type;
	public DataType data_type {
		get {
			return _data_type;
		}
		private set {
			_data_type = value;
			_data_type.parent_node = this;
		}	
	}
	
	public DataType resolved_type {get; private set;}
	
	public DataTypeParent (DataType data_type) {
		this.data_type = data_type;
	}
	
	public override void replace_type (DataType old_type, DataType new_type) {
		assert (data_type == old_type);
		data_type = new_type;
	}
}
