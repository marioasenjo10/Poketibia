using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

// Convierte una ilustracion con fondo liso (p. ej. el cinturon pokemon sobre azul oscuro) en un
// icono cuadrado con fondo transparente para la barra de arriba del cliente.
// Quita el fondo rellenando desde los bordes (los pixeles parecidos al color de la esquina), asi
// no se borran los contornos oscuros del dibujo; suaviza el borde, recorta y escala.
// Uso (PowerShell): Add-Type -Path IconCut.cs -ReferencedAssemblies System.Drawing
//                   [IconCut]::Run('entrada.png', 'salida.png', 64)
public static class IconCut
{
	public static string Run(string src, string dst, int size)
	{
		using (var input = new Bitmap(src))
			return Cut(input, new Rectangle(0, 0, input.Width, input.Height), dst, size);
	}

	// recorta antes una zona (p. ej. el interior de un marco que no queremos)
	public static string RunCrop(string src, string dst, int size, int x, int y, int w, int h)
	{
		using (var input = new Bitmap(src))
			return Cut(input, new Rectangle(x, y, w, h), dst, size);
	}

	static string Cut(Bitmap input, Rectangle crop, string dst, int size)
	{
		using (var bmp = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(bmp))
				g.DrawImage(input, new Rectangle(0, 0, crop.Width, crop.Height), crop, GraphicsUnit.Pixel);
			int w = bmp.Width, h = bmp.Height;
			Color bg = bmp.GetPixel(w / 2, 2); // arriba en el centro: fondo aunque haya esquinas redondeadas
			var isBg = new bool[w, h];
			var queue = new Queue<Point>();
			for (int x = 0; x < w; x++) { queue.Enqueue(new Point(x, 0)); queue.Enqueue(new Point(x, h - 1)); }
			for (int y = 0; y < h; y++) { queue.Enqueue(new Point(0, y)); queue.Enqueue(new Point(w - 1, y)); }
			while (queue.Count > 0)
			{
				var p = queue.Dequeue();
				if (p.X < 0 || p.Y < 0 || p.X >= w || p.Y >= h || isBg[p.X, p.Y]) continue;
				if (Dist(bmp.GetPixel(p.X, p.Y), bg) > 22) continue;
				isBg[p.X, p.Y] = true;
				queue.Enqueue(new Point(p.X + 1, p.Y)); queue.Enqueue(new Point(p.X - 1, p.Y));
				queue.Enqueue(new Point(p.X, p.Y + 1)); queue.Enqueue(new Point(p.X, p.Y - 1));
			}
			// motas sueltas del fondo (grano/compresion): solo se quedan las zonas grandes del dibujo
			var label = new int[w, h];
			var sizes = new List<int> { 0 };
			for (int y0 = 0; y0 < h; y0++)
				for (int x0 = 0; x0 < w; x0++)
				{
					if (isBg[x0, y0] || label[x0, y0] != 0) continue;
					int id = sizes.Count, count = 0;
					var stack = new Stack<Point>();
					stack.Push(new Point(x0, y0));
					label[x0, y0] = id;
					while (stack.Count > 0)
					{
						var p = stack.Pop();
						count++;
						foreach (var n in new[] { new Point(p.X + 1, p.Y), new Point(p.X - 1, p.Y), new Point(p.X, p.Y + 1), new Point(p.X, p.Y - 1) })
						{
							if (n.X < 0 || n.Y < 0 || n.X >= w || n.Y >= h || isBg[n.X, n.Y] || label[n.X, n.Y] != 0) continue;
							label[n.X, n.Y] = id;
							stack.Push(n);
						}
					}
					sizes.Add(count);
				}
			int largest = 0;
			foreach (int c in sizes) largest = Math.Max(largest, c);
			for (int y = 0; y < h; y++)
				for (int x = 0; x < w; x++)
					if (!isBg[x, y] && sizes[label[x, y]] < largest / 50) isBg[x, y] = true;

			int minX = w, minY = h, maxX = 0, maxY = 0;
			for (int y = 0; y < h; y++)
				for (int x = 0; x < w; x++)
				{
					if (isBg[x, y]) { bmp.SetPixel(x, y, Color.Transparent); continue; }
					// borde: pixel del dibujo junto al fondo -> semitransparente para suavizar
					int near = 0;
					for (int dy = -1; dy <= 1; dy++)
						for (int dx = -1; dx <= 1; dx++)
						{
							int nx = x + dx, ny = y + dy;
							if (nx >= 0 && ny >= 0 && nx < w && ny < h && isBg[nx, ny]) near++;
						}
					if (near > 0)
					{
						var c = bmp.GetPixel(x, y);
						bmp.SetPixel(x, y, Color.FromArgb(Math.Max(60, 255 - near * 22), c));
					}
					if (x < minX) minX = x; if (y < minY) minY = y;
					if (x > maxX) maxX = x; if (y > maxY) maxY = y;
				}
			int bw = maxX - minX + 1, bh = maxY - minY + 1;
			int side = Math.Max(bw, bh);
			using (var output = new Bitmap(size, size, PixelFormat.Format32bppArgb))
			{
				using (var g = Graphics.FromImage(output))
				{
					g.Clear(Color.Transparent);
					g.InterpolationMode = InterpolationMode.HighQualityBicubic;
					g.PixelOffsetMode = PixelOffsetMode.HighQuality;
					g.SmoothingMode = SmoothingMode.AntiAlias;
					float scale = (float)size / side;
					float dw = bw * scale, dh = bh * scale;
					g.DrawImage(bmp, new RectangleF((size - dw) / 2, (size - dh) / 2, dw, dh),
						new RectangleF(minX, minY, bw, bh), GraphicsUnit.Pixel);
				}
				output.Save(dst, ImageFormat.Png);
			}
			return bw + "x" + bh;
		}
	}

	static int Dist(Color a, Color b)
	{
		return Math.Abs(a.R - b.R) + Math.Abs(a.G - b.G) + Math.Abs(a.B - b.B);
	}
}
