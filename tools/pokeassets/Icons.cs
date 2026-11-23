using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

// Recorta un icono de una lamina (topbuttons.png / topbuttons2.png): quita el fondo azul oscuro
// de su casilla (relleno desde los bordes, el contorno negro del dibujo lo protege), recorta lo
// transparente y lo escala a un PNG cuadrado.
// Uso (PowerShell): Add-Type -Path Icons.cs -ReferencedAssemblies System.Drawing
//                   [Icons]::Extract(lamina, salida, x0, y0, x1, y1, tamano)
public static class Icons
{
	static int maxBlue = 215;

	static bool IsBackground(Color c)
	{
		if (c.A < 40) return true;
		// azul marino del fondo de la casilla y lineas claras del borde de la casilla
		return c.R < 100 && c.B > c.R + 35 && c.B > c.G + 10 && c.B < maxBlue && c.G < 150;
	}

	public static string Extract(string sheet, string output, int x0, int y0, int x1, int y1, int size)
	{
		return Extract(sheet, output, x0, y0, x1, y1, size, 215);
	}

	// blueLimit: azul maximo que cuenta como fondo (bajarlo si el propio icono es azul)
	public static string Extract(string sheet, string output, int x0, int y0, int x1, int y1, int size, int blueLimit)
	{
		maxBlue = blueLimit;
		using (var src = new Bitmap(sheet))
		{
			int w = x1 - x0 + 1, h = y1 - y0 + 1;
			var region = new Bitmap(w, h, PixelFormat.Format32bppArgb);
			for (int y = 0; y < h; y++)
				for (int x = 0; x < w; x++)
					region.SetPixel(x, y, src.GetPixel(x0 + x, y0 + y));

			var removed = new bool[w, h];
			var queue = new Queue<Point>();
			Action<int, int> seed = (x, y) =>
			{
				if (!removed[x, y] && IsBackground(region.GetPixel(x, y)))
				{
					removed[x, y] = true;
					queue.Enqueue(new Point(x, y));
				}
			};
			for (int x = 0; x < w; x++) { seed(x, 0); seed(x, h - 1); }
			for (int y = 0; y < h; y++) { seed(0, y); seed(w - 1, y); }
			while (queue.Count > 0)
			{
				var p = queue.Dequeue();
				if (p.X > 0) seed(p.X - 1, p.Y);
				if (p.X < w - 1) seed(p.X + 1, p.Y);
				if (p.Y > 0) seed(p.X, p.Y - 1);
				if (p.Y < h - 1) seed(p.X, p.Y + 1);
			}

			// trozos sueltos que quedan (esquinas del borde de la casilla): se quitan los pequenos
			var label = new int[w, h];
			var sizes = new List<int> { 0 };
			for (int sy = 0; sy < h; sy++)
				for (int sx = 0; sx < w; sx++)
				{
					if (removed[sx, sy] || label[sx, sy] != 0) continue;
					int id = sizes.Count, count = 0;
					label[sx, sy] = id;
					queue.Enqueue(new Point(sx, sy));
					while (queue.Count > 0)
					{
						var p = queue.Dequeue();
						count++;
						for (int dy = -1; dy <= 1; dy++)
							for (int dx = -1; dx <= 1; dx++)
							{
								int nx = p.X + dx, ny = p.Y + dy;
								if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
								if (removed[nx, ny] || label[nx, ny] != 0) continue;
								label[nx, ny] = id;
								queue.Enqueue(new Point(nx, ny));
							}
					}
					sizes.Add(count);
				}
			int largest = 0;
			foreach (int s in sizes) largest = Math.Max(largest, s);
			int minSize = Math.Max(40, largest / 12);

			int minX = w, minY = h, maxX = -1, maxY = -1;
			for (int y = 0; y < h; y++)
				for (int x = 0; x < w; x++)
				{
					if (removed[x, y] || sizes[label[x, y]] < minSize)
					{
						region.SetPixel(x, y, Color.Transparent);
						continue;
					}
					if (x < minX) minX = x;
					if (y < minY) minY = y;
					if (x > maxX) maxX = x;
					if (y > maxY) maxY = y;
				}
			if (maxX < 0) return "vacio";

			int bw = maxX - minX + 1, bh = maxY - minY + 1;
			int side = Math.Max(bw, bh);
			using (var dst = new Bitmap(size, size, PixelFormat.Format32bppArgb))
			using (var g = Graphics.FromImage(dst))
			{
				g.Clear(Color.Transparent);
				g.InterpolationMode = InterpolationMode.HighQualityBicubic;
				g.PixelOffsetMode = PixelOffsetMode.HighQuality;
				g.SmoothingMode = SmoothingMode.HighQuality;
				g.CompositingQuality = CompositingQuality.HighQuality;
				float scale = (float)size / side;
				float dw = bw * scale, dh = bh * scale;
				g.DrawImage(region, new RectangleF((size - dw) / 2f, (size - dh) / 2f, dw, dh),
					new RectangleF(minX, minY, bw, bh), GraphicsUnit.Pixel);
				dst.Save(output, ImageFormat.Png);
			}
			region.Dispose();
			return string.Format("{0}x{1} en ({2},{3})", bw, bh, x0 + minX, y0 + minY);
		}
	}

	// Recorta un icono redondo sobre fondo blanco o transparente: busca el circulo dentro de la zona, lo recorta con
	// una mascara circular suave y lo centra en un lienzo de lado 2*boxRadius (asi iconos de distinto
	// radio mantienen su tamano relativo) escalado a 'size'.
	public static string Circle(string sheet, string output, int x0, int y0, int x1, int y1, int boxRadius, int size)
	{
		using (var src = new Bitmap(sheet))
		{
			int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1;
			for (int y = y0; y <= y1; y++)
				for (int x = x0; x <= x1; x++)
				{
					var c = src.GetPixel(x, y);
					if (c.A < 128 || (c.R > 235 && c.G > 235 && c.B > 235)) continue;
					if (x < minX) minX = x;
					if (y < minY) minY = y;
					if (x > maxX) maxX = x;
					if (y > maxY) maxY = y;
				}
			if (maxX < 0) return "vacio";

			double cx = (minX + maxX) / 2.0, cy = (minY + maxY) / 2.0;
			double r = Math.Min(maxX - minX, maxY - minY) / 2.0 - 1.0;
			int side = boxRadius * 2;
			int ox = (int)Math.Round(cx) - boxRadius, oy = (int)Math.Round(cy) - boxRadius;
			using (var region = new Bitmap(side, side, PixelFormat.Format32bppArgb))
			{
				for (int y = 0; y < side; y++)
					for (int x = 0; x < side; x++)
					{
						int sx = ox + x, sy = oy + y;
						double d = Math.Sqrt((sx - cx) * (sx - cx) + (sy - cy) * (sy - cy));
						double a = Math.Max(0, Math.Min(1, r - d + 0.5));
						if (a <= 0 || sx < 0 || sy < 0 || sx >= src.Width || sy >= src.Height) { region.SetPixel(x, y, Color.Transparent); continue; }
						var c = src.GetPixel(sx, sy);
						region.SetPixel(x, y, Color.FromArgb((int)(a * c.A), c.R, c.G, c.B));
					}
				using (var dst = new Bitmap(size, size, PixelFormat.Format32bppArgb))
				using (var g = Graphics.FromImage(dst))
				{
					g.Clear(Color.Transparent);
					g.InterpolationMode = InterpolationMode.HighQualityBicubic;
					g.PixelOffsetMode = PixelOffsetMode.HighQuality;
					g.CompositingQuality = CompositingQuality.HighQuality;
					g.DrawImage(region, new Rectangle(0, 0, size, size), 0, 0, side, side, GraphicsUnit.Pixel);
					dst.Save(output, ImageFormat.Png);
				}
			}
			return string.Format("circulo r={0:0.#} en ({1:0.#},{2:0.#})", r, cx, cy);
		}
	}
}
