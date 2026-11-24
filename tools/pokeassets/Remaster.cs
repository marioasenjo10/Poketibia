using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

// "Remasteriza" sprites de pixel art SIN cambiar el dibujo: los amplia con Scale2x (convierte
// los escalones de curvas y diagonales en lineas suaves sin borrar detalles), los vuelve a
// reducir a su tamano promediando (bordes con transparencia suave) y les da un poco mas de
// contraste y saturacion. Trabaja sobre tiras de sprites de 32x32 (como las de SpriteDump).
// Uso (PowerShell): Add-Type -Path Remaster.cs -ReferencedAssemblies System.Drawing
//                   [Remaster]::Strip(entrada.png, salida.png)
public static class Remaster
{
	const int PASSES = 3;            // 2^3 = x8
	const double CONTRAST = 1.08, SATURATION = 1.12;

	public static string Strip(string inPath, string outPath) { return Strip(inPath, outPath, false); }

	// outline: anade un contorno oscuro semitransparente alrededor de la silueta (destaca mas)
	public static string Strip(string inPath, string outPath, bool outline)
	{
		using (var src = new Bitmap(inPath))
		using (var dst = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
		{
			for (int cx = 0; cx + 32 <= src.Width; cx += 32)
				for (int cy = 0; cy + 32 <= src.Height; cy += 32)
				{
					var px = new int[32 * 32];
					for (int y = 0; y < 32; y++)
						for (int x = 0; x < 32; x++)
							px[y * 32 + x] = src.GetPixel(cx + x, cy + y).ToArgb();
					var outPx = Sprite(px);
					if (outline) outPx = Outline(outPx);
					for (int y = 0; y < 32; y++)
						for (int x = 0; x < 32; x++)
							dst.SetPixel(cx + x, cy + y, Color.FromArgb(outPx[y * 32 + x]));
				}
			dst.Save(outPath, ImageFormat.Png);
		}
		return "ok";
	}

	// un sprite 32x32 (ARGB) -> mismo tamano, bordes suavizados
	public static int[] Sprite(int[] px)
	{
		int w = 32;
		int[] big = px;
		for (int p = 0; p < PASSES; p++) { big = Scale2x(big, w); w *= 2; }
		int f = w / 32, area = f * f;
		var res = new int[32 * 32];
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				// promedio con alfa premultiplicado (los bordes no se oscurecen)
				double a = 0, r = 0, g = 0, b = 0;
				for (int sy = 0; sy < f; sy++)
					for (int sx = 0; sx < f; sx++)
					{
						int c = big[(y * f + sy) * w + x * f + sx];
						double ca = ((c >> 24) & 255) / 255.0;
						a += ca; r += ((c >> 16) & 255) * ca; g += ((c >> 8) & 255) * ca; b += (c & 255) * ca;
					}
				if (a <= 0.02 * area) { res[y * 32 + x] = 0; continue; }
				r /= a; g /= a; b /= a;
				int alpha = (int)Math.Round(a / area * 255);
				Enhance(ref r, ref g, ref b);
				res[y * 32 + x] = (alpha << 24) | (Clamp(r) << 16) | (Clamp(g) << 8) | Clamp(b);
			}
		return res;
	}

	// contorno: los pixeles vacios (o casi) junto a la silueta se oscurecen
	public static int[] Outline(int[] px)
	{
		var res = (int[])px.Clone();
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				int i = y * 32 + x;
				int a = (px[i] >> 24) & 255;
				if (a >= 200) continue;
				int near = 0;
				for (int dy = -1; dy <= 1; dy++)
					for (int dx = -1; dx <= 1; dx++)
					{
						int nx = x + dx, ny = y + dy;
						if ((dx == 0 && dy == 0) || nx < 0 || ny < 0 || nx > 31 || ny > 31) continue;
						int na = (px[ny * 32 + nx] >> 24) & 255;
						if (na >= 200) near = Math.Max(near, (dx == 0 || dy == 0) ? 2 : 1);
					}
				if (near == 0) continue;
				int oa = near == 2 ? 150 : 90;
				// mezcla el contorno (20,22,28) por debajo del pixel que ya hubiera
				double fa = a / 255.0, ob = oa / 255.0 * (1 - fa);
				double outA = fa + ob;
				int r = (int)((((px[i] >> 16) & 255) * fa + 20 * ob) / outA);
				int g = (int)((((px[i] >> 8) & 255) * fa + 22 * ob) / outA);
				int b = (int)(((px[i] & 255) * fa + 28 * ob) / outA);
				res[i] = ((int)Math.Round(outA * 255) << 24) | (r << 16) | (g << 8) | b;
			}
		return res;
	}

	static void Enhance(ref double r, ref double g, ref double b)
	{
		double l = 0.299 * r + 0.587 * g + 0.114 * b;
		r = l + (r - l) * SATURATION; g = l + (g - l) * SATURATION; b = l + (b - l) * SATURATION;
		r = (r - 128) * CONTRAST + 128; g = (g - 128) * CONTRAST + 128; b = (b - 128) * CONTRAST + 128;
	}

	static int Clamp(double v) { return Math.Max(0, Math.Min(255, (int)Math.Round(v))); }

	// Scale2x (EPX) sobre ARGB: los transparentes cuentan como un color mas
	static int[] Scale2x(int[] src, int w)
	{
		int w2 = w * 2;
		var dst = new int[w2 * w2];
		for (int y = 0; y < w; y++)
			for (int x = 0; x < w; x++)
			{
				int p = Norm(src[y * w + x]);
				int a = y > 0 ? Norm(src[(y - 1) * w + x]) : p;
				int d = y < w - 1 ? Norm(src[(y + 1) * w + x]) : p;
				int c = x > 0 ? Norm(src[y * w + x - 1]) : p;
				int b = x < w - 1 ? Norm(src[y * w + x + 1]) : p;
				int o = (y * 2) * w2 + x * 2;
				dst[o] = (c == a && c != d && a != b) ? a : p;
				dst[o + 1] = (a == b && a != c && b != d) ? b : p;
				dst[o + w2] = (d == c && d != b && c != a) ? c : p;
				dst[o + w2 + 1] = (b == d && b != a && d != c) ? d : p;
			}
		return dst;
	}

	// todos los pixeles transparentes valen lo mismo (si no, Scale2x los ve distintos)
	static int Norm(int c) { return ((c >> 24) & 255) == 0 ? 0 : c; }
}
