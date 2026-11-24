using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

// Aura arcoiris para los pokemon en Premier Ball: efecto de 2x2 casillas (64x64), 10 fotogramas.
// Un aro de destellos a los pies del pokemon que gira y cambia de color recorriendo el arcoiris,
// mas unos puntos de purpurina que suben. Misma zona que el aura del boost maximo (efecto 475).
// Uso: [AuraDesign]::Strip(salida.png)  -> tira de 10 fotogramas de 64x64
public static class AuraDesign
{
	public const int FRAMES = 10;
	const int SS = 4, SIZE = 64;
	const float CX = 33, CY = 47, RX = 22, RY = 9; // aro a los pies (coordenadas del cuadro de 64)
	const int SPARKLES = 10;

	public static Bitmap Frame(int f)
	{
		var big = new Bitmap(SIZE * SS, SIZE * SS, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(big))
		{
			g.Clear(Color.Transparent);
			g.SmoothingMode = SmoothingMode.AntiAlias;
			double phase = (double)f / FRAMES;
			// aro tenue de fondo
			using (var pen = new Pen(Color.FromArgb(70, 255, 255, 255), 1.2f * SS))
				g.DrawEllipse(pen, (CX - RX) * SS, (CY - RY) * SS, RX * 2 * SS, RY * 2 * SS);
			for (int i = 0; i < SPARKLES; i++)
			{
				double ang = 2 * Math.PI * ((double)i / SPARKLES + phase / SPARKLES * 2);
				float x = (float)(CX + Math.Cos(ang) * RX), y = (float)(CY + Math.Sin(ang) * RY);
				bool front = Math.Sin(ang) > 0;
				float size = front ? 3.4f : 2.4f;
				int alpha = front ? 255 : 170;
				Color c = Hue((double)i / SPARKLES + phase);
				Star(g, x, y, size, c, alpha);
			}
			// purpurina que sube (cada punto nace abajo y se apaga al subir)
			var rnd = new Random(7);
			for (int k = 0; k < 7; k++)
			{
				double start = rnd.NextDouble();
				double life = (phase + start) % 1.0;
				double ang = rnd.NextDouble() * 2 * Math.PI;
				float x = (float)(CX + Math.Cos(ang) * RX * 0.9);
				float y = (float)(CY + Math.Sin(ang) * RY * 0.6 - life * 30);
				int a = (int)(220 * (1 - life));
				Color c = Hue(start + phase);
				using (var b = new SolidBrush(Color.FromArgb(a, c)))
					g.FillEllipse(b, (x - 0.9f) * SS, (y - 0.9f) * SS, 1.8f * SS, 1.8f * SS);
			}
		}
		var small = new Bitmap(SIZE, SIZE, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(small))
		{
			g.Clear(Color.Transparent);
			g.InterpolationMode = InterpolationMode.HighQualityBicubic;
			g.PixelOffsetMode = PixelOffsetMode.HighQuality;
			g.DrawImage(big, new Rectangle(0, 0, SIZE, SIZE), new Rectangle(0, 0, SIZE * SS, SIZE * SS), GraphicsUnit.Pixel);
		}
		big.Dispose();
		return small;
	}

	// destello de 4 puntas con centro blanco
	static void Star(Graphics g, float x, float y, float r, Color c, int alpha)
	{
		x *= SS; y *= SS; r *= SS;
		using (var glow = new SolidBrush(Color.FromArgb(alpha / 3, c)))
			g.FillEllipse(glow, x - r * 1.3f, y - r * 1.3f, r * 2.6f, r * 2.6f);
		using (var b = new SolidBrush(Color.FromArgb(alpha, c)))
		{
			g.FillPolygon(b, new[] { new PointF(x, y - r), new PointF(x + r * 0.28f, y - r * 0.28f), new PointF(x + r, y),
				new PointF(x + r * 0.28f, y + r * 0.28f), new PointF(x, y + r), new PointF(x - r * 0.28f, y + r * 0.28f),
				new PointF(x - r, y), new PointF(x - r * 0.28f, y - r * 0.28f) });
		}
		using (var w = new SolidBrush(Color.FromArgb(alpha, 255, 255, 255)))
			g.FillEllipse(w, x - r * 0.3f, y - r * 0.3f, r * 0.6f, r * 0.6f);
	}

	// tono del arcoiris (0..1) con saturacion y brillo altos
	static Color Hue(double h)
	{
		h = (h % 1.0 + 1.0) % 1.0 * 6;
		int i = (int)h;
		double fr = h - i, v = 1.0, s = 0.85, p = v * (1 - s), q = v * (1 - s * fr), t = v * (1 - s * (1 - fr));
		double r, gg, b;
		switch (i)
		{
			case 0: r = v; gg = t; b = p; break;
			case 1: r = q; gg = v; b = p; break;
			case 2: r = p; gg = v; b = t; break;
			case 3: r = p; gg = q; b = v; break;
			case 4: r = t; gg = p; b = v; break;
			default: r = v; gg = p; b = q; break;
		}
		return Color.FromArgb(255, (int)(r * 255), (int)(gg * 255), (int)(b * 255));
	}

	public static string Strip(string outPath)
	{
		using (var strip = new Bitmap(SIZE * FRAMES, SIZE, PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(strip))
			{
				g.Clear(Color.Transparent);
				for (int f = 0; f < FRAMES; f++)
					using (var fr = Frame(f)) g.DrawImage(fr, f * SIZE, 0);
			}
			strip.Save(outPath, ImageFormat.Png);
		}
		return "ok";
	}
}
