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
}
