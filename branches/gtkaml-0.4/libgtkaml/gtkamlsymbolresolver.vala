using GLib;
using Vala;

public class Gtkaml.SymbolResolver : Vala.SymbolResolver {
	public override void visit_property (Property prop) {
		if (prop is MarkupMember) message ("hoooooraaaay");
		base.visit_property (prop);
	}

}
