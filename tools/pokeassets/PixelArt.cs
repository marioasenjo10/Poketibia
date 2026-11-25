using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;

// Dibujo de objetos en pixel art (32x32) desde cero: formas sin suavizado, sombreado por zonas y
// contorno oscuro de 1 px. Se usa para los objetos de evolucion shiny (uno por Pokemon).
//   var c = new PixelCanvas(32);  c.Polygon(...); c.Line(...); c.Outline(); c.Save("x.png", 1); c.Save("x8.png", 8);
public class PixelCanvas
{
	public readonly int Size;
	public readonly Color[,] Px;

	public PixelCanvas(int size)
	{
		Size = size;
		Px = new Color[size, size];
	}

	public bool Inside(int x, int y) { return x >= 0 && y >= 0 && x < Size && y < Size; }
	public bool Filled(int x, int y) { return Inside(x, y) && Px[x, y].A > 0; }

	public void Set(int x, int y, Color c)
	{
		if (Inside(x, y)) Px[x, y] = c;
	}

	// relleno de poligono por filas (centro del pixel), sin suavizado
	public void Polygon(Color c, params int[] pts)
	{
		int n = pts.Length / 2;
		for (int y = 0; y < Size; y++)
		{
			double sy = y + 0.5;
			var xs = new List<double>();
			for (int i = 0; i < n; i++)
			{
				double x1 = pts[2 * i], y1 = pts[2 * i + 1];
				double x2 = pts[2 * ((i + 1) % n)], y2 = pts[2 * ((i + 1) % n) + 1];
				if ((y1 <= sy && y2 > sy) || (y2 <= sy && y1 > sy))
					xs.Add(x1 + (sy - y1) / (y2 - y1) * (x2 - x1));
			}
			xs.Sort();
			for (int k = 0; k + 1 < xs.Count; k += 2)
				for (int x = (int)Math.Ceiling(xs[k] - 0.5); x <= (int)Math.Floor(xs[k + 1] - 0.5); x++)
					Set(x, y, c);
		}
	}

	// linea de Bresenham con grosor (cuadrado de lado "width")
	public void Line(Color c, int x0, int y0, int x1, int y1, int width)
	{
		int dx = Math.Abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
		int dy = -Math.Abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
		int err = dx + dy;
		while (true)
		{
			for (int ox = 0; ox < width; ox++)
				for (int oy = 0; oy < width; oy++)
					Set(x0 + ox - width / 2, y0 + oy - width / 2, c);
			if (x0 == x1 && y0 == y1) break;
			int e2 = 2 * err;
			if (e2 >= dy) { err += dy; x0 += sx; }
			if (e2 <= dx) { err += dx; y0 += sy; }
		}
	}

	public void Ellipse(Color c, double cx, double cy, double rx, double ry)
	{
		for (int y = 0; y < Size; y++)
			for (int x = 0; x < Size; x++)
			{
				double nx = (x + 0.5 - cx) / rx, ny = (y + 0.5 - cy) / ry;
				if (nx * nx + ny * ny <= 1.0) Set(x, y, c);
			}
	}

	// cambia a "to" los pixeles de color "from" que cumplen la condicion (para sombrear zonas)
	public void Recolor(Color from, Color to, Func<int, int, bool> where)
	{
		for (int y = 0; y < Size; y++)
			for (int x = 0; x < Size; x++)
				if (Px[x, y].ToArgb() == from.ToArgb() && where(x, y)) Px[x, y] = to;
	}

	// distancia (en pixeles) al pixel mas cercano de un color dado
	public double DistanceTo(int x, int y, Color c)
	{
		double best = 999;
		for (int yy = 0; yy < Size; yy++)
			for (int xx = 0; xx < Size; xx++)
				if (Px[xx, yy].ToArgb() == c.ToArgb())
				{
					double d = Math.Sqrt((xx - x) * (xx - x) + (yy - y) * (yy - y));
					if (d < best) best = d;
				}
		return best;
	}

	// sombreado de volumen: los pixeles de "baseColor" con hueco arriba/izquierda se aclaran y los que
	// tienen hueco abajo/derecha se oscurecen (luz desde arriba a la izquierda). "other" = cuenta como hueco
	public void Shade(Color baseColor, Color light, Color dark, Func<Color, bool> other = null)
	{
		Func<int, int, bool> empty = (x, y) => !Filled(x, y) || (other != null && Px[x, y].ToArgb() != baseColor.ToArgb() && other(Px[x, y]));
		var lights = new List<Point>(); var darks = new List<Point>();
		for (int y = 0; y < Size; y++)
			for (int x = 0; x < Size; x++)
			{
				if (Px[x, y].ToArgb() != baseColor.ToArgb()) continue;
				bool top = empty(x, y - 1) || empty(x - 1, y);
				bool bottom = empty(x, y + 1) || empty(x + 1, y);
				if (bottom && !top) darks.Add(new Point(x, y));
				else if (top && !bottom) lights.Add(new Point(x, y));
			}
		foreach (var p in lights) Px[p.X, p.Y] = light;
		foreach (var p in darks) Px[p.X, p.Y] = dark;
	}

	// trazo grueso a lo largo de una curva de Bezier cuadratica, con radio que va de r0 a r1
	public void Curve(Color c, double x0, double y0, double cx, double cy, double x1, double y1, double r0, double r1)
	{
		for (int i = 0; i <= 60; i++)
		{
			double t = i / 60.0, u = 1 - t;
			double x = u * u * x0 + 2 * u * t * cx + t * t * x1;
			double y = u * u * y0 + 2 * u * t * cy + t * t * y1;
			double r = r0 + (r1 - r0) * t;
			Ellipse(c, x, y, r, r);
		}
	}

	// poligono de una flor/estrella: n petalos alrededor de (cx, cy)
	public void Petal(Color c, double cx, double cy, double angleDeg, double length, double width)
	{
		double a = angleDeg * Math.PI / 180, p = a + Math.PI / 2;
		double tx = cx + Math.Cos(a) * length, ty = cy + Math.Sin(a) * length;
		double mx = cx + Math.Cos(a) * length * 0.45, my = cy + Math.Sin(a) * length * 0.45;
		Polygon(c,
			(int)Math.Round(cx), (int)Math.Round(cy),
			(int)Math.Round(mx + Math.Cos(p) * width), (int)Math.Round(my + Math.Sin(p) * width),
			(int)Math.Round(tx), (int)Math.Round(ty),
			(int)Math.Round(mx - Math.Cos(p) * width), (int)Math.Round(my - Math.Sin(p) * width));
	}

	// distancia (en pixeles) al hueco transparente mas cercano: para oscurecer los bordes de una forma
	public double DistanceToEmpty(int x, int y)
	{
		double best = 999;
		for (int yy = -6; yy <= 6; yy++)
			for (int xx = -6; xx <= 6; xx++)
				if (!Filled(x + xx, y + yy))
				{
					double d = Math.Sqrt(xx * xx + yy * yy);
					if (d < best) best = d;
				}
		return best;
	}

	// contorno de 1 px alrededor de todo lo dibujado (vecinos en cruz)
	public void Outline(Color c)
	{
		var add = new List<Point>();
		for (int y = 0; y < Size; y++)
			for (int x = 0; x < Size; x++)
				if (!Filled(x, y) && (Filled(x - 1, y) || Filled(x + 1, y) || Filled(x, y - 1) || Filled(x, y + 1)))
					add.Add(new Point(x, y));
		foreach (var p in add) Px[p.X, p.Y] = c;
	}

	public Bitmap ToBitmap(int scale)
	{
		var b = new Bitmap(Size * scale, Size * scale, PixelFormat.Format32bppArgb);
		for (int y = 0; y < Size; y++)
			for (int x = 0; x < Size; x++)
				for (int sy = 0; sy < scale; sy++)
					for (int sx = 0; sx < scale; sx++)
						b.SetPixel(x * scale + sx, y * scale + sy, Px[x, y]);
		return b;
	}

	public void Save(string path, int scale)
	{
		using (var b = ToBitmap(scale)) b.Save(path, ImageFormat.Png);
	}

	public static Color Hex(string hex)
	{
		hex = hex.TrimStart('#');
		return Color.FromArgb(255, Convert.ToInt32(hex.Substring(0, 2), 16), Convert.ToInt32(hex.Substring(2, 2), 16), Convert.ToInt32(hex.Substring(4, 2), 16));
	}
}
