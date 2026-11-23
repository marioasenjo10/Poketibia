using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

// Fondos de la barra superior y de la barra de objetos de abajo: rectangulos redondeados con
// degradado, brillo interior y halo. Se usan como 9-slice (image-border) en los .otui.
// Uso (PowerShell): Add-Type -Path UiSkin.cs -ReferencedAssemblies System.Drawing
//                   [UiSkin]::Run(carpetaImagesDelCliente)
public static class UiSkin
{
	public static string Run(string imagesDir)
	{
		string bottom = Path.Combine(imagesDir, "bottombar");
		string top = Path.Combine(imagesDir, "topmenu");
		Directory.CreateDirectory(bottom);
		Directory.CreateDirectory(top);

		// barra de abajo: panel azul marino con borde azul brillante y halo
		Save(Panel(72, 72, 4, 14, Color.FromArgb(235, 16, 44, 86), Color.FromArgb(235, 7, 22, 48),
			Color.FromArgb(255, 47, 155, 255), 2, Color.FromArgb(90, 47, 155, 255)), bottom, "bar");

		// casilla: normal, raton encima y pulsada
		Save(Cell(Color.FromArgb(255, 30, 82, 148), Color.FromArgb(255, 11, 36, 78), Color.FromArgb(255, 60, 143, 230), 0), bottom, "cell");
		Save(Cell(Color.FromArgb(255, 44, 108, 186), Color.FromArgb(255, 15, 48, 100), Color.FromArgb(255, 143, 211, 255), 90), bottom, "cell_hover");
		Save(Cell(Color.FromArgb(255, 12, 38, 80), Color.FromArgb(255, 22, 64, 122), Color.FromArgb(255, 47, 127, 214), 0), bottom, "cell_pressed");

		// tecla (estilo tecla de teclado clara)
		Save(Keycap(), bottom, "keycap");

		// barra superior: pastilla oscura translucida
		Save(Panel(48, 48, 0, 14, Color.FromArgb(215, 14, 30, 58), Color.FromArgb(215, 7, 16, 32),
			Color.FromArgb(170, 59, 130, 214), 1, Color.Empty), top, "pill");

		// botones de arriba: raton encima, pulsado y activo (ventana abierta)
		Save(Glow(38, Color.FromArgb(50, 255, 255, 255), Color.FromArgb(14, 255, 255, 255), Color.FromArgb(70, 255, 255, 255), Color.Empty), top, "hover");
		Save(Glow(38, Color.FromArgb(60, 0, 0, 0), Color.FromArgb(30, 0, 0, 0), Color.FromArgb(110, 59, 130, 214), Color.Empty), top, "pressed");
		Save(Glow(38, Color.FromArgb(110, 47, 143, 255), Color.FromArgb(30, 47, 143, 255), Color.FromArgb(220, 108, 192, 255), Color.FromArgb(255, 143, 211, 255)), top, "on");
		return "ok";
	}

	static void Save(Bitmap bmp, string dir, string name)
	{
		using (bmp) bmp.Save(Path.Combine(dir, name + ".png"), ImageFormat.Png);
	}

	static GraphicsPath Round(RectangleF r, float radius)
	{
		float d = radius * 2;
		var p = new GraphicsPath();
		p.AddArc(r.X, r.Y, d, d, 180, 90);
		p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
		p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
		p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
		p.CloseFigure();
		return p;
	}

	static Graphics Canvas(Bitmap bmp)
	{
		var g = Graphics.FromImage(bmp);
		g.Clear(Color.Transparent);
		g.SmoothingMode = SmoothingMode.AntiAlias;
		g.PixelOffsetMode = PixelOffsetMode.HighQuality;
		g.CompositingQuality = CompositingQuality.HighQuality;
		return g;
	}

	static Bitmap Panel(int w, int h, int halo, float radius, Color fillTop, Color fillBottom, Color border, float borderWidth, Color haloColor)
	{
		var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(halo + 0.5f, halo + 0.5f, w - 2 * halo - 1, h - 2 * halo - 1);
			if (halo > 0)
				for (int i = halo; i >= 1; i--)
					using (var path = Round(new RectangleF(r.X - i, r.Y - i, r.Width + 2 * i, r.Height + 2 * i), radius + i))
					using (var pen = new Pen(Color.FromArgb(haloColor.A * (halo - i + 1) / (halo + 1) / 2, haloColor), 1.5f))
						g.DrawPath(pen, path);
			using (var path = Round(r, radius))
			{
				using (var brush = new LinearGradientBrush(r, fillTop, fillBottom, LinearGradientMode.Vertical))
					g.FillPath(brush, path);
				using (var pen = new Pen(border, borderWidth))
					g.DrawPath(pen, path);
			}
			// brillo interior arriba
			var inner = new RectangleF(r.X + borderWidth + 1, r.Y + borderWidth + 1, r.Width - 2 * borderWidth - 2, r.Height - 2 * borderWidth - 2);
			using (var path = Round(inner, Math.Max(2, radius - borderWidth - 1)))
			using (var pen = new Pen(Color.FromArgb(45, 255, 255, 255), 1))
			{
				g.SetClip(new RectangleF(0, 0, w, inner.Y + inner.Height / 2));
				g.DrawPath(pen, path);
				g.ResetClip();
			}
		}
		return bmp;
	}

	static Bitmap Cell(Color fillTop, Color fillBottom, Color border, int innerGlow)
	{
		const int size = 52;
		const float radius = 11;
		var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(1, 1, size - 2, size - 2);
			using (var path = Round(r, radius))
			{
				using (var brush = new LinearGradientBrush(r, fillTop, fillBottom, LinearGradientMode.Vertical))
					g.FillPath(brush, path);
				if (innerGlow > 0)
					for (int i = 1; i <= 4; i++)
						using (var inner = Round(new RectangleF(r.X + i, r.Y + i, r.Width - 2 * i, r.Height - 2 * i), radius - i))
						using (var pen = new Pen(Color.FromArgb(innerGlow * (5 - i) / 5, border), 1.5f))
							g.DrawPath(pen, inner);
				using (var pen = new Pen(border, 2))
					g.DrawPath(pen, path);
			}
			// reflejo en la mitad de arriba
			var gloss = new RectangleF(4, 3, size - 8, size / 2 - 4);
			using (var path = Round(gloss, 8))
			using (var brush = new LinearGradientBrush(gloss, Color.FromArgb(38, 255, 255, 255), Color.FromArgb(0, 255, 255, 255), LinearGradientMode.Vertical))
				g.FillPath(brush, path);
		}
		return bmp;
	}

	static Bitmap Keycap()
	{
		const int size = 18;
		var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var shadow = new RectangleF(0.5f, 1.5f, size - 1, size - 2);
			using (var path = Round(shadow, 4))
			using (var brush = new SolidBrush(Color.FromArgb(255, 60, 66, 78)))
				g.FillPath(brush, path);
			var face = new RectangleF(0.5f, 0.5f, size - 1, size - 3.5f);
			using (var path = Round(face, 4))
			{
				using (var brush = new LinearGradientBrush(face, Color.FromArgb(255, 250, 251, 252), Color.FromArgb(255, 200, 206, 215), LinearGradientMode.Vertical))
					g.FillPath(brush, path);
				using (var pen = new Pen(Color.FromArgb(255, 42, 48, 58), 1))
					g.DrawPath(pen, path);
			}
		}
		return bmp;
	}

	static Bitmap Glow(int size, Color fillTop, Color fillBottom, Color border, Color accent)
	{
		const float radius = 10;
		var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(0.5f, 0.5f, size - 1, size - 1);
			using (var path = Round(r, radius))
			{
				using (var brush = new LinearGradientBrush(r, fillTop, fillBottom, LinearGradientMode.Vertical))
					g.FillPath(brush, path);
				using (var pen = new Pen(border, 1))
					g.DrawPath(pen, path);
			}
			if (accent != Color.Empty)
			{
				// barrita brillante abajo para marcar la ventana abierta
				var bar = new RectangleF(size / 2f - 9, size - 4, 18, 3);
				using (var path = Round(bar, 1.5f))
				using (var brush = new SolidBrush(accent))
					g.FillPath(brush, path);
			}
		}
		return bmp;
	}
}
