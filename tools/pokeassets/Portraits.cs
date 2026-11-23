using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Text.RegularExpressions;

// Retratos de los pokemon para la pokedex del cliente (modules/game_pokedex/portraits/<looktype>.png).
// Dibuja el outfit mirando al sur, recorta lo transparente, lo agranda con Scale2x (bordes suaves
// sin emborronar el pixel art) y lo deja centrado en un PNG de 128x128. Los outfits 1x1 se
// ajustan a una caja de 96px para que los pokemon pequeños no se vean artificialmente ampliados.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,Portraits.cs -ReferencedAssemblies System.Drawing
//                   [Portraits]::Run(dat, spr, carpetaMonster, carpetaSalida)

public static class Portraits
{
	const int Size = 128;

	public static string Run(string datPath, string sprPath, string monsterDir, string outDir)
	{
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);
		var looks = new SortedSet<int>();
		var lookRegex = new Regex("<look\\s+type\\s*=\\s*\"(\\d+)\"", RegexOptions.IgnoreCase);
		foreach (var file in Directory.GetFiles(monsterDir, "*.xml", SearchOption.AllDirectories))
		{
			var m = lookRegex.Match(File.ReadAllText(file));
			if (m.Success) looks.Add(int.Parse(m.Groups[1].Value));
		}
		Directory.CreateDirectory(outDir);
		int done = 0, skipped = 0;
		foreach (int look in looks)
		{
			DatThing t;
			if (look <= 0 || !dat.Creatures.TryGetValue(look, out t) || t.Width == 0) { skipped++; continue; }
			using (var frame = Compose(dat, spr, t))
			{
				var box = Bounds(frame);
				if (box.Width <= 0) { skipped++; continue; }
				var img = frame.Clone(box, PixelFormat.Format32bppArgb);
				while (Math.Max(img.Width, img.Height) < Size / 2)
				{
					var bigger = Scale2x(img);
					img.Dispose();
					img = bigger;
				}
				using (img)
				using (var final = Fit(img, t.Width <= 1 && t.Height <= 1 ? 96 : Size))
				{
					final.Save(Path.Combine(outDir, look + ".png"), ImageFormat.Png);
				}
			}
			done++;
		}
		return "retratos: " + done + " (sin dibujo: " + skipped + ")";
	}

	// outfit mirando al sur, capa 0, sin addons ni montura, primer frame
	static Bitmap Compose(Dat dat, Spr spr, DatThing t)
	{
		var bmp = new Bitmap(t.Width * 32, t.Height * 32, PixelFormat.Format32bppArgb);
		int x = t.PatX >= 4 ? 2 : 0;
		for (int hh = 0; hh < t.Height; hh++)
		{
			for (int ww = 0; ww < t.Width; ww++)
			{
				int index = ((((x * t.Layers) + 0) * t.Height + hh) * t.Width) + ww;
				if (index >= t.SpritePositions.Count) continue;
				var px = spr.Decode(dat.SpriteAt(t.SpritePositions[index]));
				int ox = (t.Width - 1 - ww) * 32, oy = (t.Height - 1 - hh) * 32;
				for (int i = 0; i < 1024; i++)
				{
					byte a = px[i * 4 + 3];
					if (a == 0) continue;
					bmp.SetPixel(ox + i % 32, oy + i / 32, Color.FromArgb(a, px[i * 4], px[i * 4 + 1], px[i * 4 + 2]));
				}
			}
		}
		return bmp;
	}

	static Rectangle Bounds(Bitmap bmp)
	{
		int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
		for (int y = 0; y < bmp.Height; y++)
		{
			for (int x = 0; x < bmp.Width; x++)
			{
				if (bmp.GetPixel(x, y).A == 0) continue;
				if (x < minX) minX = x;
				if (y < minY) minY = y;
				if (x > maxX) maxX = x;
				if (y > maxY) maxY = y;
			}
		}
		if (maxX < 0) return Rectangle.Empty;
		return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
	}

	static Bitmap Scale2x(Bitmap src)
	{
		int w = src.Width, h = src.Height;
		var c = new int[w, h];
		for (int y = 0; y < h; y++)
			for (int x = 0; x < w; x++)
				c[x, y] = src.GetPixel(x, y).ToArgb();
		var dst = new Bitmap(w * 2, h * 2, PixelFormat.Format32bppArgb);
		for (int y = 0; y < h; y++)
		{
			for (int x = 0; x < w; x++)
			{
				int p = c[x, y];
				int a = y > 0 ? c[x, y - 1] : p;
				int b = x < w - 1 ? c[x + 1, y] : p;
				int l = x > 0 ? c[x - 1, y] : p;
				int d = y < h - 1 ? c[x, y + 1] : p;
				int e0 = (l == a && l != d && a != b) ? a : p;
				int e1 = (a == b && a != l && b != d) ? b : p;
				int e2 = (d == l && d != b && l != a) ? l : p;
				int e3 = (b == d && b != a && d != l) ? d : p;
				dst.SetPixel(x * 2, y * 2, Color.FromArgb(e0));
				dst.SetPixel(x * 2 + 1, y * 2, Color.FromArgb(e1));
				dst.SetPixel(x * 2, y * 2 + 1, Color.FromArgb(e2));
				dst.SetPixel(x * 2 + 1, y * 2 + 1, Color.FromArgb(e3));
			}
		}
		return dst;
	}

	// centrado en un cuadrado de 128x128, ajustado al maximo de fitSize
	static Bitmap Fit(Bitmap src, int fitSize)
	{
		double scale = (double)fitSize / Math.Max(src.Width, src.Height);
		int w = Math.Max(1, (int)Math.Round(src.Width * scale));
		int h = Math.Max(1, (int)Math.Round(src.Height * scale));
		var dst = new Bitmap(Size, Size, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(dst))
		using (var attrs = new ImageAttributes())
		{
			g.InterpolationMode = InterpolationMode.NearestNeighbor;
			g.PixelOffsetMode = PixelOffsetMode.Half;
			g.CompositingQuality = CompositingQuality.HighQuality;
			attrs.SetWrapMode(WrapMode.TileFlipXY);
			var rect = new Rectangle((Size - w) / 2, (Size - h) / 2, w, h);
			g.DrawImage(src, rect, 0, 0, src.Width, src.Height, GraphicsUnit.Pixel, attrs);
		}
		return dst;
	}
}
