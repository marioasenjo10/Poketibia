using System;
using System.Drawing;

// Orbes de evolucion shiny (32x32, pixel art): remolino dentro de una esfera, con aro brillante, halo de luz
// translucido y destellos. El color depende de la rareza del shiny al que evoluciona (pokemon-tiers-review.csv).
// El Pokemon se ve encima en el cliente como holograma (game_containers/pokeballicons.lua).
public static class OrbDesign
{
	static Color H(string hex) { return PixelCanvas.Hex(hex); }

	public static readonly string[] Keys = { "mythic", "legendary", "ultra", "super", "t1", "t2", "bronze" };

	// remolino de oscuro a claro (5 tonos), color del aro/halo y de los destellos
	static Color[] Ramp(string key)
	{
		switch (key)
		{
			case "mythic": return new[] { H("1c0630"), H("5a0f78"), H("b02fb8"), H("ff5fc8"), H("ffd2f4") };
			case "legendary": return new[] { H("3d1802"), H("8f3c06"), H("e07b10"), H("ffbf2e"), H("fff2b0") };
			case "ultra": return new[] { H("041a3d"), H("0a4f9a"), H("1d95e8"), H("5fd2ff"), H("d8f6ff") };
			case "super": return new[] { H("1b0a3d"), H("44198f"), H("7a3ae0"), H("b07cff"), H("eadcff") };
			case "t1": return new[] { H("20262f"), H("4d5868"), H("8996a8"), H("c9d4e2"), H("f8fbff") };
			case "t2": return new[] { H("062a0c"), H("12601c"), H("2fa434"), H("74e04e"), H("dcffc4") };
			default: return new[] { H("2e1406"), H("6a3010"), H("a8571f"), H("e08d45"), H("ffd0a0") };
		}
	}

	static Color Glow(string key)
	{
		switch (key)
		{
			case "mythic": return H("ff5fe0");
			case "legendary": return H("ffb020");
			case "ultra": return H("3fc4ff");
			case "super": return H("a96bff");
			case "t1": return H("bcd8ff");
			case "t2": return H("5cf04a");
			default: return H("ff9a4a");
		}
	}

	static Color WithAlpha(Color c, int a) { return Color.FromArgb(a, c.R, c.G, c.B); }

	static void Star(PixelCanvas c, int x, int y, Color col, bool big)
	{
		c.Set(x, y, Color.White);
		c.Set(x - 1, y, col); c.Set(x + 1, y, col); c.Set(x, y - 1, col); c.Set(x, y + 1, col);
		if (big) { c.Set(x - 2, y, WithAlpha(col, 150)); c.Set(x + 2, y, WithAlpha(col, 150)); c.Set(x, y - 2, WithAlpha(col, 150)); c.Set(x, y + 2, WithAlpha(col, 150)); }
	}

	// Holograma de un Pokemon: su ilustracion en cian translucido con lineas horizontales (cada 3 filas),
	// para que se vea que es una imagen del Pokemon al que sirve el orbe y no el Pokemon de verdad.
	public static void Hologram(string srcPath, string dstPath, int size)
	{
		using (var src = new Bitmap(srcPath))
		using (var b = new Bitmap(size, size, System.Drawing.Imaging.PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(b))
			{
				g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
				g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
				g.DrawImage(src, 0, 0, size, size);
			}
			for (int y = 0; y < size; y++)
				for (int x = 0; x < size; x++)
				{
					var p = b.GetPixel(x, y);
					if (p.A < 20) { b.SetPixel(x, y, Color.Transparent); continue; }
					double l = (0.299 * p.R + 0.587 * p.G + 0.114 * p.B) / 255.0;
					double scan = y % 3 == 0 ? 0.7 : 1.0;
					int a = (int)Math.Min(255, p.A * 0.82 * scan);
					b.SetPixel(x, y, Color.FromArgb(a, (int)(110 + 145 * l), (int)(215 + 40 * l), 255));
				}
			b.Save(dstPath, System.Drawing.Imaging.ImageFormat.Png);
		}
	}

	public static PixelCanvas Orb(string key)
	{
		var c = new PixelCanvas(32);
		var ramp = Ramp(key);
		var glow = Glow(key);
		double R = 11.6, cx = 16, cy = 16.5;

		// halo de luz translucido alrededor
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				double dx = x + 0.5 - cx, dy = y + 0.5 - cy;
				double r = Math.Sqrt(dx * dx + dy * dy);
				if (r > R && r <= R + 1.4) c.Set(x, y, WithAlpha(glow, 150));
				else if (r > R + 1.4 && r <= R + 2.6) c.Set(x, y, WithAlpha(glow, 60));
			}

		// remolino de 3 brazos: el valor sube y baja con el angulo torcido por el radio
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				double dx = x + 0.5 - cx, dy = y + 0.5 - cy;
				double r = Math.Sqrt(dx * dx + dy * dy);
				if (r > R) continue;
				double a = Math.Atan2(dy, dx);
				double v = 0.5 + 0.5 * Math.Sin(3 * a + r * 0.55);
				v = v * 0.7 + (1 - r / R) * 0.6 - 0.15;      // centro brillante, borde mas oscuro
				int k = (int)Math.Round(Math.Max(0, Math.Min(1, v)) * (ramp.Length - 1));
				c.Set(x, y, ramp[k]);
			}
		// nucleo de luz
		c.Ellipse(ramp[4], cx - 0.5, cy - 0.5, 2.2, 2.2);
		c.Set(15, 15, Color.White);

		// aro brillante (mas claro arriba a la izquierda)
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				double dx = x + 0.5 - cx, dy = y + 0.5 - cy;
				double r = Math.Sqrt(dx * dx + dy * dy);
				if (r <= R && r > R - 1.15)
					c.Set(x, y, (dx + dy) < -4 ? ramp[4] : ramp[3]);
			}

		// destellos alrededor (los raros llevan mas)
		Star(c, 4, 6, glow, key == "mythic" || key == "legendary");
		Star(c, 28, 27, glow, false);
		if (key != "bronze" && key != "t2") Star(c, 27, 5, glow, key == "mythic");
		if (key == "mythic" || key == "legendary" || key == "ultra") { Star(c, 3, 26, glow, false); c.Set(30, 15, glow); }
		if (key == "mythic") { Star(c, 16, 2, glow, true); }
		c.Set(1, 14, WithAlpha(glow, 180)); c.Set(29, 20, WithAlpha(glow, 180)); c.Set(9, 30, WithAlpha(glow, 180));
		return c;
	}
}
