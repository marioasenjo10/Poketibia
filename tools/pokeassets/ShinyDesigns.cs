using System;
using System.Drawing;

// Dibujos propios de los objetos de evolucion shiny (32x32, pixel art). Uno por metodo; el nombre del
// metodo es el id del objeto (lib/core/shinyevolution.lua). Herramienta: PixelArt.cs.
public static class ShinyDesigns
{
	static Color H(string hex) { return PixelCanvas.Hex(hex); }
	static readonly Color Outline = H("120f14");

	// 46027 - Shiny Charizard: ala de dragon negra con membrana roja (como su retrato)
	public static PixelCanvas Item46027()
	{
		var c = new PixelCanvas(32);
		Color boneDark = H("1f1f26"), bone = H("34343e"), boneLight = H("71717f");
		Color memDeep = H("4f0d13"), memDark = H("7c141c"), mem = H("a51e27"), memLight = H("cf3b37");
		Color claw = H("d9d5cc");

		// membrana: hombro (abajo izquierda) -> muneca -> punta (arriba derecha); borde de abajo en ondas
		c.Polygon(mem,
			3, 29,   // hombro
			12, 13,  // muneca
			27, 3,   // punta
			30, 15,  // dedo 1
			24, 15,  // entrante
			27, 25,  // dedo 2
			19, 21,  // entrante
			18, 30,  // dedo 3
			11, 25,  // entrante
			7, 30);  // vuelta al hombro

		// bordes de la membrana mas oscuros (lejos de los huesos)
		c.Recolor(mem, memDark, (x, y) => c.DistanceToEmpty(x, y) <= 2.2 && y > 8);
		c.Recolor(memDark, memDeep, (x, y) => c.DistanceToEmpty(x, y) <= 1.0 && y > 12);

		// huesos: brazo grueso (hombro -> muneca -> punta) y tres dedos desde la muneca
		c.Line(boneDark, 4, 28, 12, 13, 3);
		c.Line(boneDark, 12, 13, 26, 4, 3);
		c.Line(bone, 13, 14, 29, 15, 2);
		c.Line(bone, 13, 15, 26, 24, 2);
		c.Line(bone, 12, 16, 17, 29, 2);
		// brillo en el lado de arriba del brazo
		c.Line(boneLight, 3, 26, 10, 13, 1);
		c.Line(boneLight, 12, 11, 24, 3, 1);

		// luz de la membrana pegada a los huesos (solo 1 px)
		c.Recolor(mem, memLight, (x, y) => c.DistanceTo(x, y, bone) <= 1.0);

		// garra en la punta
		c.Set(27, 2, claw); c.Set(28, 1, claw); c.Set(28, 2, H("9e9a92"));
		c.Set(12, 12, boneLight); // nudillo

		c.Outline(Outline);
		return c;
	}
}
