using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;

// Bici nueva: el jugador con SU traje (y sus colores) montado en una bici dibujada aqui.
// Se monta cada fotograma: parte de la bici que queda detras, jugador (subido para que vaya
// sentado, con sus piernas de andar como pedaleo) y parte de la bici que queda delante.
// Uso: [BikeDesign]::Preview(dat, spr, "1971,1973", salida.png)
public static class BikeDesign
{
	// ---------- colores de traje de Tibia (133 colores) ----------
	public static Color OutfitColor(int color)
	{
		if (color < 0 || color >= 133) color = 0;
		double h, s, v;
		if (color % 19 == 0) { h = 0; s = 0; v = 1 - color / 19 / 7.0; }
		else
		{
			h = (color % 19) / 18.0; s = 1; v = 1;
			switch (color / 19)
			{
				case 0: s = 0.25; v = 1; break;
				case 1: s = 0.25; v = 0.75; break;
				case 2: s = 0.5; v = 0.75; break;
				case 3: s = 0.667; v = 0.75; break;
				case 4: s = 1; v = 1; break;
				case 5: s = 1; v = 0.75; break;
				case 6: s = 1; v = 0.5; break;
			}
		}
		if (v == 0) return Color.Black;
		if (s == 0) { int g = (int)(v * 255); return Color.FromArgb(g, g, g); }
		double r, gg, b;
		if (h < 1 / 6.0) { r = v; b = v * (1 - s); gg = b + (v - b) * 6 * h; }
		else if (h < 2 / 6.0) { gg = v; b = v * (1 - s); r = gg - (v - b) * (6 * h - 1); }
		else if (h < 3 / 6.0) { gg = v; r = v * (1 - s); b = r + (v - r) * (6 * h - 2); }
		else if (h < 4 / 6.0) { b = v; r = v * (1 - s); gg = b - (v - r) * (6 * h - 3); }
		else if (h < 5 / 6.0) { b = v; gg = v * (1 - s); r = gg + (v - gg) * (6 * h - 4); }
		else { r = v; gg = v * (1 - s); b = r - (v - gg) * (6 * h - 5); }
		return Color.FromArgb((int)(r * 255), (int)(gg * 255), (int)(b * 255));
	}

	// capa base * color segun la mascara (amarillo cabeza, rojo cuerpo, verde piernas, azul pies)
	public static int[] Colorize(int[] baseLayer, int[] mask, int head, int body, int legs, int feet)
	{
		var res = (int[])baseLayer.Clone();
		var ch = OutfitColor(head); var cb = OutfitColor(body); var cl = OutfitColor(legs); var cf = OutfitColor(feet);
		for (int i = 0; i < res.Length; i++)
		{
			int m = mask[i];
			if (((m >> 24) & 255) == 0) continue;
			int r = (m >> 16) & 255, g = (m >> 8) & 255, b = m & 255;
			Color c;
			if (r > 128 && g > 128 && b < 128) c = ch;
			else if (r > 128 && g < 128 && b < 128) c = cb;
			else if (r < 128 && g > 128 && b < 128) c = cl;
			else if (r < 128 && g < 128 && b > 128) c = cf;
			else continue;
			int p = res[i];
			res[i] = (p & unchecked((int)0xFF000000)) | ((((p >> 16) & 255) * c.R / 255) << 16) | ((((p >> 8) & 255) * c.G / 255) << 8) | ((p & 255) * c.B / 255);
		}
		return res;
	}

	// ---------- dibujo de la bici ----------
	class Canvas
	{
		public int[] Px; public int W, H;
		public void Set(int x, int y, Color c)
		{
			if (x < 0 || y < 0 || x >= W || y >= H) return;
			Px[y * W + x] = (c.A << 24) | (c.R << 16) | (c.G << 8) | c.B;
		}
		public void Line(int x0, int y0, int x1, int y1, Color c)
		{
			int dx = Math.Abs(x1 - x0), dy = -Math.Abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, err = dx + dy;
			while (true)
			{
				Set(x0, y0, c);
				if (x0 == x1 && y0 == y1) break;
				int e2 = 2 * err;
				if (e2 >= dy) { err += dy; x0 += sx; }
				if (e2 <= dx) { err += dx; y0 += sy; }
			}
		}
		// tubo de 2 px: claro arriba, oscuro abajo
		public void Tube(int x0, int y0, int x1, int y1, Color light, Color dark)
		{
			Line(x0, y0 + 1, x1, y1 + 1, dark);
			Line(x0, y0, x1, y1, light);
		}
	}

	static Color Tire = Color.FromArgb(255, 34, 34, 40), TireHi = Color.FromArgb(255, 84, 84, 94),
		Rim = Color.FromArgb(255, 196, 200, 210), Spoke = Color.FromArgb(255, 140, 144, 156), Hub = Color.FromArgb(255, 225, 228, 236),
		Seat = Color.FromArgb(255, 44, 38, 38), Grip = Color.FromArgb(255, 30, 30, 34), Metal = Color.FromArgb(255, 176, 180, 190),
		MetalDark = Color.FromArgb(255, 110, 114, 124);

	// proyeccion del juego: lo alto se dibuja hacia arriba a la izquierda
	class Proj
	{
		public double OX, OY, UX, UY; // origen (suelo bajo los pedales) y direccion de la marcha
		public void P(double along, double side, double z, out int x, out int y)
		{
			double wx = along * UX - side * UY, wy = along * UY + side * UX;
			x = (int)Math.Round(OX + wx - z * Shear); y = (int)Math.Round(OY + wy - z);
		}
	}

	static void Tube3(Canvas c, Proj p, double a0, double s0, double z0, double a1, double s1, double z1, Color light, Color dark)
	{
		int x0, y0, x1, y1;
		p.P(a0, s0, z0, out x0, out y0); p.P(a1, s1, z1, out x1, out y1);
		c.Tube(x0, y0, x1, y1, light, dark);
	}

	static void Line3(Canvas c, Proj p, double a0, double s0, double z0, double a1, double s1, double z1, Color col)
	{
		int x0, y0, x1, y1;
		p.P(a0, s0, z0, out x0, out y0); p.P(a1, s1, z1, out x1, out y1);
		c.Line(x0, y0, x1, y1, col);
	}

	// rueda en el plano (marcha, altura): neumatico, llanta y 3 radios que giran
	static void Wheel(Canvas c, Proj p, double hubA, double r, int phase)
	{
		var done = new HashSet<int>();
		for (double rho = r + 0.4; rho >= r - 2.9; rho -= 0.35)
			for (double ang = 0; ang < Math.PI * 2; ang += 0.02)
			{
				int x, y;
				double sa = Math.Sin(ang);
				p.P(hubA + Math.Cos(ang) * rho, 0, r + sa * rho, out x, out y);
				int key = y * 1000 + x;
				if (done.Contains(key)) continue;
				done.Add(key);
				Color col = rho > r - 1.1 ? (sa > 0.35 ? TireHi : Tire) : rho > r - 2.0 ? Tire : Rim;
				c.Set(x, y, col);
			}
		double a0 = phase * Math.PI / 6;
		for (int k = 0; k < 3; k++)
		{
			double a = a0 + k * Math.PI / 3, rr = r - 2.6;
			Line3(c, p, hubA - Math.Cos(a) * rr, 0, r - Math.Sin(a) * rr, hubA + Math.Cos(a) * rr, 0, r + Math.Sin(a) * rr, Spoke);
		}
		int hx, hy; p.P(hubA, 0, r, out hx, out hy); c.Set(hx, hy, Hub);
	}

	const double R = 7, Base = 11;

	static void RearPart(Canvas c, Proj p, int phase, Color frame, Color frameDark)
	{
		Wheel(c, p, -Base, R, phase);
		Tube3(c, p, -Base, 0, R, 0, 0, 5, frame, frameDark);        // vaina
		Tube3(c, p, -Base, 0, R, -3, 0, 15, frame, frameDark);      // tirante
		Tube3(c, p, -3, 0, 15, 0, 0, 5, frame, frameDark);          // tubo del sillin
		// sillin
		Line3(c, p, -6, 0, 17, -1, 0, 17, Seat);
		Line3(c, p, -5, 0, 16, -2, 0, 16, Seat);
		// pedalier y bielas
		int phaseSign = phase % 2 == 0 ? 1 : -1;
		Line3(c, p, 0, 0, 5, 2 * phaseSign, 0, 5 - 2 * phaseSign, MetalDark);
		int x, y; p.P(0, 0, 5, out x, out y); c.Set(x, y, Metal); c.Set(x + 1, y, Metal);
	}

	static void FrontPart(Canvas c, Proj p, int phase, Color frame, Color frameDark, bool withBar)
	{
		Wheel(c, p, Base, R, phase);
		Tube3(c, p, -3, 0, 15, 8, 0, 15, frame, frameDark);         // tubo superior
		Tube3(c, p, 0, 0, 5, 8, 0, 14, frame, frameDark);           // tubo diagonal
		Tube3(c, p, 8, 0, 16, Base, 0, R, frame, frameDark);        // horquilla
		if (withBar) Bar(c, p);
	}

	static void Bar(Canvas c, Proj p)
	{
		// de lado el manillar se ve casi de punta: mas corto para que no parezca una antena
		double h = p.UX != 0 ? 2 : 6;
		Line3(c, p, 8, 0, 16, 7, 0, 19, Metal);
		Line3(c, p, 7, -h, 19, 7, h, 19, Metal);
		Line3(c, p, 7, -h, 19, 7, -h + 1, 19, Grip);
		Line3(c, p, 7, h - 1, 19, 7, h, 19, Grip);
	}

	// dir 0 norte, 1 este, 2 sur, 3 oeste; front = lo que va por delante del jugador
	static void DrawBike(Canvas c, int dir, int phase, int ox, int oy, Color frame, Color frameDark, bool front)
	{
		var p = new Proj { OX = ox, OY = oy };
		switch (dir) { case 0: p.UY = -1; break; case 1: p.UX = 1; break; case 2: p.UY = 1; break; default: p.UX = -1; break; }
		if (dir == 1 || dir == 3)
		{
			// de lado: casi toda la bici detras del jugador; manillar delante (sus manos)
			if (!front) { RearPart(c, p, phase, frame, frameDark); FrontPart(c, p, phase, frame, frameDark, false); }
			else Bar(c, p);
		}
		else if (dir == 2)
		{
			// hacia el sur: la parte trasera queda detras, la delantera por delante
			if (!front) RearPart(c, p, phase, frame, frameDark);
			else FrontPart(c, p, phase, frame, frameDark, true);
		}
		else
		{
			// hacia el norte: la delantera (con el manillar) detras, la trasera delante
			if (!front) FrontPart(c, p, phase, frame, frameDark, true);
			else RearPart(c, p, phase, frame, frameDark);
		}
	}

	static void Blend(int[] dst, int[] src)
	{
		for (int i = 0; i < dst.Length; i++)
		{
			int s = src[i], a = (s >> 24) & 255;
			if (a == 0) continue;
			if (a == 255) { dst[i] = s; continue; }
			int d = dst[i], da = (d >> 24) & 255;
			int oa = a + da * (255 - a) / 255;
			if (oa == 0) continue;
			Func<int, int> ch = sh => ((((s >> sh) & 255) * a + ((d >> sh) & 255) * da * (255 - a) / 255) / oa);
			dst[i] = (oa << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
		}
	}

	public static int OffX = 0, OffY = 0;
	public static double Shear = 0.45;

	static int[] Shift(int[] px, int W, int H, int dx, int dy)
	{
		var res = new int[W * H];
		for (int y = 0; y < H; y++)
			for (int x = 0; x < W; x++)
			{
				int sx = x - dx, sy = y - dy;
				if (sx < 0 || sy < 0 || sx >= W || sy >= H) continue;
				res[y * W + x] = px[sy * W + sx];
			}
		return res;
	}

	// un fotograma de jugador en bici (64x64): capa base y mascara de colores por separado
	public static void Frame(Dat dat, Spr spr, RainbowApply.Group g, int dir, int phase, int bikePhase, Color frame, out int[] layer0, out int[] layer1)
	{
		int W, H;
		var body = RainbowOutline.Expand(RainbowApply.Compose(dat, spr, g, Math.Min(dir, g.PX - 1), 0, 0, phase, 0), g.W * 32, g.H * 32, out W, out H);
		var mask = g.Layers > 1 ? RainbowOutline.Expand(RainbowApply.Compose(dat, spr, g, Math.Min(dir, g.PX - 1), 0, 0, phase, 1), g.W * 32, g.H * 32, out W, out H) : new int[W * H];
		// pies del jugador: fila mas baja con pixeles
		int maxY = 0;
		for (int i = 0; i < W * H; i++) if (((body[i] >> 24) & 255) > 60) maxY = Math.Max(maxY, i / W);
		int sumX = 0, n = 0;
		for (int y = maxY - 2; y <= maxY; y++)
			for (int x = 0; x < W; x++)
				if (((body[y * W + x] >> 24) & 255) > 60) { sumX += x; n++; }
		int fx = n > 0 ? sumX / n : W / 2, fy = maxY;
		// sentado: el jugador sube 5 (en el juego, arriba a la izquierda)
		const int lift = 5;
		body = Shift(body, W, H, -lift, -lift);
		mask = Shift(mask, W, H, -lift, -lift);
		// de frente/espaldas la bici va bajo la cadera (arriba a la izquierda de los pies)
		int cx = fx + OffX - ((dir == 0 || dir == 2) ? 5 : 0), gy = fy + OffY - ((dir == 0 || dir == 2) ? 2 : 0);
		var frameDark = Color.FromArgb(255, frame.R * 6 / 10, frame.G * 6 / 10, frame.B * 6 / 10);
		// se dibuja en un lienzo mayor (la bici puede salirse por la derecha/abajo) y luego todo
		// se desplaza lo justo hacia arriba/izquierda para que quepa en 2x2 casillas
		int BW = W + 32, BH = H + 32;
		var big = new int[BW * BH]; var bigMask = new int[BW * BH];
		for (int y = 0; y < H; y++) { Array.Copy(body, y * W, big, y * BW, W); Array.Copy(mask, y * W, bigMask, y * BW, W); }
		var back = new Canvas { Px = new int[BW * BH], W = BW, H = BH };
		var fore = new Canvas { Px = new int[BW * BH], W = BW, H = BH };
		DrawBike(back, dir, bikePhase, cx, gy, frame, frameDark, false);
		DrawBike(fore, dir, bikePhase, cx, gy, frame, frameDark, true);
		var all = back.Px;
		Blend(all, big);
		Blend(all, fore.Px);
		var allMask = new int[BW * BH];
		for (int i = 0; i < BW * BH; i++)
			if (((fore.Px[i] >> 24) & 255) == 0) allMask[i] = bigMask[i];
		int mx = 0, my = 0;
		for (int i = 0; i < BW * BH; i++)
			if (((all[i] >> 24) & 255) != 0) { mx = Math.Max(mx, i % BW); my = Math.Max(my, i / BW); }
		int dx = Math.Max(0, mx - (W - 1)), dy = Math.Max(0, my - (H - 1));
		LastShift = new[] { dx, dy };
		layer0 = new int[W * H]; layer1 = new int[W * H];
		for (int y = 0; y < H; y++)
			for (int x = 0; x < W; x++)
			{
				layer0[y * W + x] = all[(y + dy) * BW + x + dx];
				layer1[y * W + x] = allMask[(y + dy) * BW + x + dx];
			}
	}

	public static int[] LastShift;

	public static string Preview(string datPath, string sprPath, string looks, string colors, string outPath)
	{
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);
		var ids = new List<int>();
		foreach (var s in looks.Split(',')) ids.Add(int.Parse(s.Trim()));
		var col = colors.Split(',');
		int head = int.Parse(col[0]), bodyC = int.Parse(col[1]), legs = int.Parse(col[2]), feet = int.Parse(col[3]);
		const int sc = 3, cell = 64 * sc + 6;
		int cols = 8;
		using (var bmp = new Bitmap(cols * cell, ids.Count * cell, PixelFormat.Format32bppArgb))
		using (var g = Graphics.FromImage(bmp))
		{
			g.Clear(Color.FromArgb(255, 112, 112, 104));
			g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
			g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.Half;
			for (int r = 0; r < ids.Count; r++)
			{
				var t = dat.Creatures[ids[r]];
				var groups = new List<RainbowApply.Group>();
				RainbowApply.ParseEntry(dat, t, groups);
				var walk = groups[groups.Count - 1];
				for (int k = 0; k < cols; k++)
				{
					int dir = new[] { 2, 2, 1, 1, 3, 3, 0, 0 }[k];
					int ph = (k % 2) % walk.Phases;
					int[] l0, l1;
					Frame(dat, spr, walk, dir, ph, k % 2, OutfitColor(bodyC), out l0, out l1);
					var px = Colorize(l0, l1, head, bodyC, legs, feet);
					using (var b = new Bitmap(64, 64, PixelFormat.Format32bppArgb))
					{
						for (int y = 0; y < 64; y++) for (int x = 0; x < 64; x++) b.SetPixel(x, y, Color.FromArgb(px[y * 64 + x]));
						g.DrawImage(b, k * cell + 3, r * cell + 3, 64 * sc, 64 * sc);
					}
				}
			}
			bmp.Save(outPath, ImageFormat.Png);
		}
		return "ok";
	}
}
