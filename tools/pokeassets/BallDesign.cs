using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

// Rediseno de las pokeballs (sprites de 32x32 con transparencia suave).
// Mismo lenguaje para todas: contorno oscuro, luz arriba a la izquierda, brillo, sombra en el
// suelo y boton limpio; cada tipo con su sena (franjas, H, banda...). Se dibuja a 4x y se
// reduce, asi los bordes quedan suaves.
// Uso: [BallDesign]::Preview(carpeta)  -> una tira por tipo y estado para revisar
public static class BallDesign
{
	const int SS = 4;           // supermuestreo
	const int S = 32 * SS;      // lado del lienzo grande

	public class Style
	{
		public string Name;
		public Color Top, TopDark, Bottom, BottomDark, Band, Accent;
		public string Pattern;  // "", "stripes", "h", "spots", "premier"
	}

	public static readonly Style[] Styles = {
		new Style { Name = "pokeball", Top = C(232, 64, 58), TopDark = C(168, 34, 34), Bottom = C(244, 244, 247), BottomDark = C(196, 200, 210), Band = C(26, 28, 34), Pattern = "" },
		new Style { Name = "greatball", Top = C(50, 116, 214), TopDark = C(30, 72, 150), Bottom = C(244, 244, 247), BottomDark = C(196, 200, 210), Band = C(26, 28, 34), Accent = C(226, 58, 52), Pattern = "stripes" },
		new Style { Name = "superball", Top = C(226, 58, 52), TopDark = C(160, 32, 32), Bottom = C(244, 244, 247), BottomDark = C(196, 200, 210), Band = C(26, 28, 34), Accent = C(246, 196, 58), Pattern = "stripes" },
		new Style { Name = "ultraball", Top = C(62, 64, 76), TopDark = C(28, 29, 36), Bottom = C(244, 244, 247), BottomDark = C(196, 200, 210), Band = C(26, 28, 34), Accent = C(250, 206, 48), Pattern = "h" },
		new Style { Name = "premierball", Top = C(246, 246, 249), TopDark = C(200, 204, 214), Bottom = C(246, 246, 249), BottomDark = C(200, 204, 214), Band = C(214, 52, 52), Pattern = "premier" },
		new Style { Name = "safariball", Top = C(102, 168, 76), TopDark = C(58, 110, 48), Bottom = C(234, 220, 172), BottomDark = C(190, 172, 120), Band = C(40, 46, 30), Accent = C(52, 96, 42), Pattern = "spots" },
	};

	static Color C(int r, int g, int b) { return Color.FromArgb(255, r, g, b); }

	// ===== una bola =====
	// cx, cy, r en pixeles finales (0..32); lift = la tapa levantada (en uso)
	static void DrawBall(Graphics g, Style st, float cx, float cy, float r, bool shadow, float lift)
	{
		cx *= SS; cy *= SS; r *= SS; lift *= SS;
		float outline = Math.Max(SS * 0.9f, r * 0.12f);
		if (shadow)
			using (var b = new SolidBrush(Color.FromArgb(70, 0, 0, 0)))
				g.FillEllipse(b, cx - r * 0.85f, cy + r * 0.72f, r * 1.7f, r * 0.42f);

		var body = new RectangleF(cx - r, cy - r, r * 2, r * 2);
		var inner = RectangleF.Inflate(body, -outline, -outline);
		using (var dark = new SolidBrush(Color.FromArgb(255, 22, 24, 30)))
		{
			// mitad de abajo (con contorno)
			g.SetClip(new RectangleF(cx - r - 2, cy, r * 2 + 4, r + 2));
			g.FillEllipse(dark, body);
			using (var grad = new LinearGradientBrush(inner, st.Bottom, st.BottomDark, 60f))
				g.FillEllipse(grad, inner);
			g.ResetClip();

			// mitad de arriba (puede ir levantada)
			var st2 = g.Save();
			g.TranslateTransform(0, -lift);
			if (lift > 0)
				using (var gap = new SolidBrush(Color.FromArgb(255, 14, 15, 18)))
					g.FillRectangle(gap, cx - r * 0.8f, cy - r * 0.02f, r * 1.6f, lift + 1);
			g.SetClip(new RectangleF(cx - r - 2, cy - r - 2, r * 2 + 4, r + 2));
			g.FillEllipse(dark, body);
			using (var grad = new LinearGradientBrush(inner, st.Top, st.TopDark, 60f))
				g.FillEllipse(grad, inner);
			// los patrones (franjas, H, manchas) solo dentro de la bola
			using (var innerPath = new GraphicsPath())
			{
				innerPath.AddEllipse(inner);
				g.SetClip(innerPath, CombineMode.Intersect);
				DrawPattern(g, st, cx, cy, r, inner);
			}
			// brillo
			using (var shine = new SolidBrush(Color.FromArgb(150, 255, 255, 255)))
				g.FillEllipse(shine, cx - r * 0.62f, cy - r * 0.74f, r * 0.46f, r * 0.26f);
			g.ResetClip();
			g.Restore(st2);
		}

		// banda central
		float bandH = Math.Max(SS * 1.6f, r * 0.2f);
		using (var band = new SolidBrush(st.Band))
		{
			g.SetClip(new GraphicsPath(new[] { new PointF(0, 0) }, new byte[] { 0 }));
			g.ResetClip();
			using (var clip = new GraphicsPath())
			{
				clip.AddEllipse(body);
				g.SetClip(clip);
				g.FillRectangle(band, cx - r, cy - bandH / 2 - lift * 0.5f, r * 2, bandH);
				g.ResetClip();
			}
		}

		// boton
		float br = r * 0.3f;
		using (var ring = new SolidBrush(st.Band))
			g.FillEllipse(ring, cx - br, cy - br - lift * 0.5f, br * 2, br * 2);
		float bi = br * 0.68f;
		using (var btn = new SolidBrush(lift > 0 ? Color.FromArgb(255, 150, 156, 168) : Color.FromArgb(255, 250, 250, 252)))
			g.FillEllipse(btn, cx - bi, cy - bi - lift * 0.5f, bi * 2, bi * 2);
		float bc = bi * 0.45f;
		using (var dot = new SolidBrush(Color.FromArgb(255, 205, 210, 220)))
			g.FillEllipse(dot, cx - bc, cy - bc - lift * 0.5f, bc * 2, bc * 2);
	}

	static void DrawPattern(Graphics g, Style st, float cx, float cy, float r, RectangleF inner)
	{
		switch (st.Pattern)
		{
			case "stripes":
				using (var b = new SolidBrush(st.Accent))
				{
					// dos franjas a los lados, inclinadas hacia el centro
					var s1 = g.Save();
					g.TranslateTransform(cx - r * 0.55f, cy - r * 0.45f); g.RotateTransform(-35);
					g.FillRectangle(b, -r * 0.13f, -r * 0.7f, r * 0.26f, r * 1.2f);
					g.Restore(s1);
					var s2 = g.Save();
					g.TranslateTransform(cx + r * 0.55f, cy - r * 0.45f); g.RotateTransform(35);
					g.FillRectangle(b, -r * 0.13f, -r * 0.7f, r * 0.26f, r * 1.2f);
					g.Restore(s2);
				}
				break;
			case "h":
				using (var b = new SolidBrush(st.Accent))
				{
					g.FillRectangle(b, cx - r * 0.62f, cy - r, r * 0.3f, r);
					g.FillRectangle(b, cx + r * 0.32f, cy - r, r * 0.3f, r);
				}
				break;
			case "spots":
				using (var b = new SolidBrush(st.Accent))
				{
					g.FillEllipse(b, cx - r * 0.7f, cy - r * 0.55f, r * 0.38f, r * 0.3f);
					g.FillEllipse(b, cx - r * 0.1f, cy - r * 0.85f, r * 0.34f, r * 0.26f);
					g.FillEllipse(b, cx + r * 0.32f, cy - r * 0.5f, r * 0.36f, r * 0.3f);
					g.FillEllipse(b, cx - r * 0.25f, cy - r * 0.35f, r * 0.24f, r * 0.2f);
				}
				break;
		}
	}

	// ===== lienzos =====
	static Bitmap Canvas(Action<Graphics> draw)
	{
		var big = new Bitmap(S, S, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(big))
		{
			g.Clear(Color.Transparent);
			g.SmoothingMode = SmoothingMode.AntiAlias;
			g.PixelOffsetMode = PixelOffsetMode.HighQuality;
			draw(g);
		}
		var small = new Bitmap(32, 32, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(small))
		{
			g.Clear(Color.Transparent);
			g.InterpolationMode = InterpolationMode.HighQualityBicubic;
			g.PixelOffsetMode = PixelOffsetMode.HighQuality;
			g.DrawImage(big, new Rectangle(0, 0, 32, 32), new Rectangle(0, 0, S, S), GraphicsUnit.Pixel);
		}
		big.Dispose();
		return small;
	}

	// posiciones de cada montón (x, y, radio), de atras hacia delante
	static readonly float[][][] Stacks = {
		new[] { new[] { 16f, 18f, 7f } },
		new[] { new[] { 12f, 16f, 6.5f }, new[] { 20.5f, 20f, 6.5f } },
		new[] { new[] { 11.5f, 15f, 6f }, new[] { 20.5f, 15f, 6f }, new[] { 16f, 22f, 6f } },
		new[] { new[] { 11f, 13.5f, 5.6f }, new[] { 20.5f, 13.5f, 5.6f }, new[] { 11f, 22f, 5.6f }, new[] { 20.5f, 22f, 5.6f } },
		new[] { new[] { 11f, 12f, 5.3f }, new[] { 21f, 12f, 5.3f }, new[] { 16f, 17f, 5.3f }, new[] { 10f, 23f, 5.3f }, new[] { 22f, 23f, 5.3f } },
		Pile(10, 4.6f), Pile(25, 4.2f), Pile(50, 3.9f),
	};

	// montones de 10/25/50: filas en piramide, de atras hacia delante
	static float[][] Pile(int n, float r)
	{
		var list = new List<float[]>();
		int[] rows = n == 10 ? new[] { 1, 2, 3, 4 } : n == 25 ? new[] { 2, 3, 4, 5, 5 } : new[] { 3, 4, 5, 6, 6, 6 };
		float step = r * 1.6f, rowStep = r * 1.15f;
		float y = 30 - r - (rows.Length - 1) * rowStep;
		foreach (int cnt in rows)
		{
			float x0 = 16 - (cnt - 1) * step / 2;
			for (int i = 0; i < cnt; i++) list.Add(new[] { x0 + i * step, y, r });
			y += rowStep;
		}
		return list.ToArray();
	}

	public static Bitmap StackSprite(Style st, int index)
	{
		return Canvas(g =>
		{
			foreach (var b in Stacks[index]) DrawBall(g, st, b[0], b[1], b[2], index < 5, 0);
			if (index >= 5)
				using (var sh = new SolidBrush(Color.FromArgb(60, 0, 0, 0)))
					g.FillEllipse(sh, 3 * SS, 28 * SS, 26 * SS, 3.5f * SS);
		});
	}

	public static Bitmap FilledSprite(Style st, bool inUse)
	{
		return Canvas(g => DrawBall(g, st, 16, 18, 7.5f, true, inUse ? 1.6f : 0));
	}

	// proyectil: patron (x, y) de 3x3, la estela sale hacia atras de la direccion
	public static Bitmap MissileSprite(Style st, int px, int py)
	{
		int dx = px - 1, dy = py - 1;
		return Canvas(g =>
		{
			if (dx != 0 || dy != 0)
			{
				float len = (float)Math.Sqrt(dx * dx + dy * dy);
				float ux = dx / len, uy = dy / len, nx = -uy, ny = ux;
				Color trail = st.Pattern == "premier" ? Color.FromArgb(255, 214, 52, 52)
					: st.Pattern == "h" ? st.Accent : st.Top;
				for (int k = -1; k <= 1; k++)
				{
					float ox = (16 + nx * k * 3.2f) * SS, oy = (16 + ny * k * 3.2f) * SS;
					float l = k == 0 ? 13 : 9;
					using (var pen = new Pen(Color.FromArgb(k == 0 ? 200 : 130, trail), SS * 1.4f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
						g.DrawLine(pen, ox - ux * 5 * SS, oy - uy * 5 * SS, ox - ux * l * SS, oy - uy * l * SS);
				}
			}
			DrawBall(g, st, 16, 16, 5.6f, false, 0);
		});
	}

	// ===== vista previa: una tira por tipo (8 montones | llena | en uso | 9 direcciones) =====
	public static string Preview(string outDir)
	{
		Directory.CreateDirectory(outDir);
		foreach (var st in Styles)
		{
			using (var strip = new Bitmap(32 * 19, 32, PixelFormat.Format32bppArgb))
			{
				using (var g = Graphics.FromImage(strip))
				{
					g.Clear(Color.Transparent);
					int x = 0;
					for (int i = 0; i < 8; i++, x += 32) using (var b = StackSprite(st, i)) g.DrawImage(b, x, 0);
					using (var b = FilledSprite(st, false)) g.DrawImage(b, x, 0); x += 32;
					using (var b = FilledSprite(st, true)) g.DrawImage(b, x, 0); x += 32;
					for (int py = 0; py < 3; py++)
						for (int px = 0; px < 3; px++, x += 32)
							using (var b = MissileSprite(st, px, py)) g.DrawImage(b, x, 0);
				}
				strip.Save(Path.Combine(outDir, st.Name + ".png"), ImageFormat.Png);
			}
		}
		return "ok";
	}
}
