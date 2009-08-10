using GLib;
using Vala;

/**
 * Gtkaml SymbolResolver's  responsibilities:
 * - determine if an attribute is a field or a signal and use = or += appropiately
 * Literal attribute values:
 * - determine the type of the literal field attribute (boolean, string and enum)
 * - determine the method reference for the literal signal attribute
 * Expression attribute values:
 * - signals: use the result of lambda parsing add the signal parameters
 * - fields: use the expression of the lambda as field assignment
 */
public class Gtkaml.SymbolResolver : Vala.SymbolResolver {
	public override void visit_property (Property prop) {
		if (prop is MarkupMember) message ("hoooooraaaay");
		base.visit_property (prop);
	}

}
