// Rasteriza una fuente TTF al formato de fuentes de OTClient (.otfont + .png, cp1252, 16x14 celdas).
// Uso (PowerShell): Add-Type -Path FontGen.cs -ReferencedAssemblies System.Drawing
//                   [FontGen]::Run('Poppins-SemiBold.ttf', 13, 'poppins-semibold-13px', '<carpeta data/fonts>')
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;
using System.Text;

public static class FontGen
{
	public static string Run(string ttfPath, int size, string name, string outDir)
	{
		var pfc = new PrivateFontCollection();
		pfc.AddFontFile(ttfPath);
		var family = pfc.Families[0];
		var style = FontStyle.Regular;
		foreach (FontStyle s in new[] { FontStyle.Regular, FontStyle.Bold })
			if (family.IsStyleAvailable(s)) { style = s; break; }
		using (var font = new Font(family, size, style, GraphicsUnit.Pixel))
		{
			float em = family.GetEmHeight(style);
			int ascent = (int)Math.Ceiling(size * family.GetCellAscent(style) / em);
			// linea: desde lo alto de las mayusculas acentuadas hasta las colas (g, j, p)
			int top = (int)Math.Round(size * 0.12);   // recorte por arriba (espacio que Poppins deja de sobra)
			int lineHeight = (int)Math.Ceiling(size * 1.28);
			int cellW = (int)Math.Ceiling(size * 1.45) + 2;
			int cellH = lineHeight + 1;
			var enc = Encoding.GetEncoding(1252);
			var tex = new Bitmap(cellW * 16, cellH * 14, PixelFormat.Format32bppArgb);
			int spaceWidth = 0;
			var fmt = StringFormat.GenericTypographic;
			for (int code = 32; code < 256; code++)
			{
				string ch = enc.GetString(new[] { (byte)code });
				// se dibuja en negro sobre blanco y la oscuridad pasa a ser el alfa (texto blanco)
				int tw = cellW * 2, th = cellH * 2, ox = size / 2, oy = size / 2;
				int advance;
				using (var tmp = new Bitmap(tw, th, PixelFormat.Format32bppArgb))
				{
					using (var g = Graphics.FromImage(tmp))
					{
						g.Clear(Color.White);
						g.TextRenderingHint = TextRenderingHint.AntiAlias;
						g.SmoothingMode = SmoothingMode.HighQuality;
						g.DrawString(ch, font, Brushes.Black, ox, oy - top, fmt);
						// avance real del caracter (OTClient mide el ancho por los pixeles: se marca con un pixel casi invisible)
						var ranges = new StringFormat(fmt);
						ranges.SetMeasurableCharacterRanges(new[] { new CharacterRange(0, 1) });
						var region = g.MeasureCharacterRanges(ch + "|", font, new RectangleF(0, 0, 1000, 1000), ranges);
						advance = (int)Math.Round(region[0].GetBounds(g).Width);
					}
					if (code == 32) { spaceWidth = advance; continue; }
					int col = (code - 32) % 16, row = (code - 32) / 16;
					int width = Math.Min(cellW, Math.Max(1, advance));
					for (int x = 0; x < cellW; x++)
						for (int y = 0; y < lineHeight; y++)
						{
							int a = 255 - tmp.GetPixel(ox + x, oy + y).R;
							if (a <= 0) continue;
							tex.SetPixel(col * cellW + x, row * cellH + y, Color.FromArgb(a, 255, 255, 255));
						}
					int mx = col * cellW + width - 1, my = row * cellH;
					if (tex.GetPixel(mx, my).A == 0) tex.SetPixel(mx, my, Color.FromArgb(1, 255, 255, 255));
				}
			}
			Directory.CreateDirectory(outDir);
			tex.Save(Path.Combine(outDir, name + ".png"), ImageFormat.Png);
			File.WriteAllText(Path.Combine(outDir, name + ".otfont"),
				"Font\n  name: " + name + "\n  texture: " + name + "\n  height: " + lineHeight +
				"\n  glyph-size: " + cellW + " " + cellH + "\n  y-offset: 0\n  spacing: 0 0\n  space-width: " + Math.Max(2, spaceWidth) + "\n");
			return name + ": linea " + lineHeight + ", celda " + cellW + "x" + cellH + ", ascent " + ascent;
		}
	}
}
