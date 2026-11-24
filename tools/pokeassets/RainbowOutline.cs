using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

// Contorno arcoiris (como Poke Alliance) para los pokemon en Premier Ball. El cliente no puede
// aplicar efectos a una criatura, asi que se generan copias de los aspectos (outfits) con el
// contorno ya pintado: cada fotograma se reconstruye entero (2x2 casillas si es grande), se
// rodea la silueta con un brillo de 3 px en los colores del arcoiris (en diagonal) y se vuelve
// a partir en casillas.
// Uso: [RainbowOutline]::Preview(dat, spr, "981,928,1052", salida.png)
public static class RainbowOutline
{
	// fotograma completo (capa 0) de una criatura: ARGB de (w*32) x (h*32)
	public static int[] Compose(Dat dat, Spr spr, DatThing t, int x, int y, int z, int phase, int layer)
	{
		int W = t.Width * 32, H = t.Height * 32;
		var px = new int[W * H];
		for (int hy = 0; hy < t.Height; hy++)
			for (int wx = 0; wx < t.Width; wx++)
			{
				int index = ((((((phase * t.PatZ + z) * t.PatY + y) * t.PatX + x) * t.Layers + layer) * t.Height + hy) * t.Width + wx);
				if (index >= t.SpritePositions.Count) continue;
				uint sid = dat.SpriteAt(t.SpritePositions[index]);
				if (sid == 0) continue;
				var s = spr.Decode(sid);
				int ox = (t.Width - 1 - wx) * 32, oy = (t.Height - 1 - hy) * 32;
				for (int py = 0; py < 32; py++)
					for (int pxx = 0; pxx < 32; pxx++)
					{
						int i = (py * 32 + pxx) * 4;
						if (s[i + 3] == 0) continue;
						px[(oy + py) * W + ox + pxx] = (s[i + 3] << 24) | (s[i] << 16) | (s[i + 1] << 8) | s[i + 2];
					}
			}
		return px;
	}

	// un pokemon de 1x1 casilla se pasa a 2x2 (el dibujo abajo a la derecha, donde ya estaba) para
	// que el brillo quepa por arriba y por la izquierda
	public static int[] Expand(int[] px, int W, int H, out int nW, out int nH)
	{
		nW = Math.Max(W, 64); nH = Math.Max(H, 64);
		if (nW == W && nH == H) return px;
		var res = new int[nW * nH];
		for (int y = 0; y < H; y++)
			for (int x = 0; x < W; x++)
				res[(y + nH - H) * nW + x + nW - W] = px[y * W + x];
		return res;
	}

	// brillo de 3 px alrededor de la silueta (alfa > 60), arcoiris en diagonal
	public static int[] Outline(int[] px, int W, int H)
	{
		return Outline(px, W, H, null);
	}

	// caja de la silueta (alfa > 60) ampliada 3 px; con una caja comun a todos los fotogramas el
	// arcoiris no "baila" al andar
	public static int[] SilhouetteBox(int[] px, int W, int H)
	{
		int minX = W, minY = H, maxX = -1, maxY = -1;
		for (int i = 0; i < W * H; i++)
			if (((px[i] >> 24) & 255) > 60)
			{
				int x = i % W, y = i / W;
				if (x < minX) minX = x; if (x > maxX) maxX = x;
				if (y < minY) minY = y; if (y > maxY) maxY = y;
			}
		if (maxX < 0) return null;
		return new[] { minX - 3, minY - 3, maxX + 3, maxY + 3 };
	}

	public static int[] Outline(int[] px, int W, int H, int[] box)
	{
		var dist = new int[W * H];
		var queue = new Queue<int>();
		for (int i = 0; i < W * H; i++)
		{
			if (((px[i] >> 24) & 255) > 60) { dist[i] = 0; queue.Enqueue(i); }
			else dist[i] = 99;
		}
		while (queue.Count > 0)
		{
			int i = queue.Dequeue(), x = i % W, y = i / W, d = dist[i];
			if (d >= 3) continue;
			for (int dy = -1; dy <= 1; dy++)
				for (int dx = -1; dx <= 1; dx++)
				{
					int nx = x + dx, ny = y + dy;
					if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
					int j = ny * W + nx;
					int nd = d + 1;
					if (nd < dist[j]) { dist[j] = nd; queue.Enqueue(j); }
				}
		}
		// el arcoiris se reparte sobre la silueta (no sobre el cuadro): todos llevan todos los colores
		int minX = W, minY = H, maxX = 0, maxY = 0;
		if (box != null) { minX = box[0]; minY = box[1]; maxX = box[2]; maxY = box[3]; }
		else
			for (int i = 0; i < W * H; i++)
				if (dist[i] <= 3)
				{
					int x = i % W, y = i / W;
					if (x < minX) minX = x; if (x > maxX) maxX = x;
					if (y < minY) minY = y; if (y > maxY) maxY = y;
				}
		double span = Math.Max(1, (maxX - minX) + (maxY - minY));
		var res = (int[])px.Clone();
		int[] alphaByDist = { 0, 255, 170, 80 };
		for (int y = 0; y < H; y++)
			for (int x = 0; x < W; x++)
			{
				int i = y * W + x, d = dist[i];
				if (d < 1 || d > 3) continue;
				Color c = Hue(((x - minX) + (y - minY)) / span * 1.1, 0.55);
				int a = alphaByDist[d];
				// mezclar por debajo de lo que ya hubiera (sombras semitransparentes del sprite)
				int ea = (px[i] >> 24) & 255;
				if (ea >= a) continue;
				res[i] = (a << 24) | (c.R << 16) | (c.G << 8) | c.B;
			}
		return res;
	}

	static Color Hue(double h, double s)
	{
		h = (h % 1.0 + 1.0) % 1.0 * 6;
		int i = (int)h;
		double f = h - i, v = 1.0, p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f));
		double r, g, b;
		switch (i)
		{
			case 0: r = v; g = t; b = p; break;
			case 1: r = q; g = v; b = p; break;
			case 2: r = p; g = v; b = t; break;
			case 3: r = p; g = q; b = v; break;
			case 4: r = t; g = p; b = v; break;
			default: r = v; g = p; b = q; break;
		}
		return Color.FromArgb(255, (int)(r * 255), (int)(g * 255), (int)(b * 255));
	}

	// vista previa: por cada aspecto, mirando al sur (quieto y andando), original y con contorno
	public static string Preview(string datPath, string sprPath, string looks, string outPath)
	{
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);
		var ids = new List<int>();
		foreach (var s in looks.Split(',')) ids.Add(int.Parse(s.Trim()));
		const int cell = 64, scale = 3;
		using (var bmp = new Bitmap(4 * cell * scale + 50, ids.Count * cell * scale + 10, PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(bmp)) g.Clear(Color.FromArgb(255, 74, 96, 66));
			int row = 0;
			foreach (int id in ids)
			{
				DatThing t;
				if (!dat.Creatures.TryGetValue(id, out t)) continue;
				int south = Math.Min(2, t.PatX - 1);
				for (int k = 0; k < 4; k++)
				{
					int phase = k % 2 == 0 ? 0 : Math.Min(1, t.Phases - 1);
					var px = Compose(dat, spr, t, south, 0, 0, phase, 0);
					int W = t.Width * 32, H = t.Height * 32;
					if (k >= 2)
					{
						px = Expand(px, W, H, out W, out H);
						px = Outline(px, W, H);
					}
					int ox = 5 + k * cell * scale + (k >= 2 ? 30 : 0), oy = 5 + row * cell * scale + (cell - H) * scale;
					for (int y = 0; y < H; y++)
						for (int x = 0; x < W; x++)
						{
							int c = px[y * W + x], a = (c >> 24) & 255;
							if (a == 0) continue;
							for (int sy = 0; sy < scale; sy++)
								for (int sx = 0; sx < scale; sx++)
								{
									var bg = bmp.GetPixel(ox + x * scale + sx, oy + y * scale + sy);
									bmp.SetPixel(ox + x * scale + sx, oy + y * scale + sy, Color.FromArgb(255,
										(((c >> 16) & 255) * a + bg.R * (255 - a)) / 255,
										(((c >> 8) & 255) * a + bg.G * (255 - a)) / 255,
										((c & 255) * a + bg.B * (255 - a)) / 255));
								}
						}
				}
				row++;
			}
			bmp.Save(outPath, ImageFormat.Png);
		}
		return "ok";
	}
}
