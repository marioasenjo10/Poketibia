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

	// Ventanas del panel derecho (minimapa, entrenador, vida, estado de combate, amigos...):
	// mismo azul marino que las barras, cabecera mas clara y botones redondeados.
	// Uso: [UiSkin]::RunMiniWindow(carpetaImagesDelCliente)
	public static string RunMiniWindow(string imagesDir)
	{
		string ui = Path.Combine(imagesDir, "ui");
		Directory.CreateDirectory(ui);
		Save(MiniWindow(264, 283, 23), ui, "miniwindow");
		Save(MiniButtons(), ui, "miniwindow_buttons");
		// fondo de la fila de pokemon (arriba a la izquierda)
		Save(Panel(32, 32, 0, 8, Color.FromArgb(225, 16, 44, 86), Color.FromArgb(225, 7, 22, 48),
			Color.FromArgb(255, 47, 155, 255), 1.5f, Color.Empty), ui, "pokebar");
		return "ok";
	}

	static Bitmap MiniWindow(int w, int h, int header)
	{
		const float radius = 7;
		var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(0.5f, 0.5f, w - 1, h - 1);
			using (var path = Round(r, radius))
			{
				// cuerpo
				using (var brush = new LinearGradientBrush(r, Color.FromArgb(232, 14, 32, 62), Color.FromArgb(232, 7, 18, 38), LinearGradientMode.Vertical))
					g.FillPath(brush, path);
				// cabecera
				g.SetClip(new RectangleF(0, 0, w, header - 1));
				var hr = new RectangleF(0, 0, w, header);
				using (var brush = new LinearGradientBrush(hr, Color.FromArgb(245, 34, 92, 164), Color.FromArgb(245, 16, 50, 100), LinearGradientMode.Vertical))
					g.FillPath(brush, path);
				// brillo en la mitad de arriba de la cabecera
				using (var brush = new LinearGradientBrush(new RectangleF(0, 0, w, header / 2f), Color.FromArgb(40, 255, 255, 255), Color.FromArgb(0, 255, 255, 255), LinearGradientMode.Vertical))
					g.FillRectangle(brush, 0, 0, w, header / 2f);
				g.ResetClip();
				// linea bajo la cabecera
				using (var pen = new Pen(Color.FromArgb(150, 47, 155, 255), 1))
					g.DrawLine(pen, 1, header - 0.5f, w - 2, header - 0.5f);
				using (var pen = new Pen(Color.FromArgb(220, 47, 155, 255), 1))
					g.DrawPath(pen, path);
			}
		}
		return bmp;
	}

	// 7 columnas x 3 filas (normal, raton encima, pulsado) de 14x14:
	// minimizar, restaurar, cerrar, subir, bajar y dos libres
	static Bitmap MiniButtons()
	{
		const int s = 14;
		var bmp = new Bitmap(s * 7, s * 3, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var states = new[] {
				new[] { Color.FromArgb(255, 30, 82, 148), Color.FromArgb(255, 11, 36, 78), Color.FromArgb(255, 60, 143, 230) },
				new[] { Color.FromArgb(255, 48, 116, 196), Color.FromArgb(255, 18, 56, 112), Color.FromArgb(255, 143, 211, 255) },
				new[] { Color.FromArgb(255, 10, 32, 70), Color.FromArgb(255, 22, 64, 122), Color.FromArgb(255, 47, 127, 214) },
			};
			for (int row = 0; row < 3; row++)
				for (int col = 0; col < 7; col++)
				{
					var r = new RectangleF(col * s + 0.5f, row * s + 0.5f, s - 1, s - 1);
					using (var path = Round(r, 3.5f))
					{
						using (var brush = new LinearGradientBrush(r, states[row][0], states[row][1], LinearGradientMode.Vertical))
							g.FillPath(brush, path);
						using (var pen = new Pen(states[row][2], 1))
							g.DrawPath(pen, path);
					}
					float cx = col * s + s / 2f, cy = row * s + s / 2f + (row == 2 ? 0.5f : 0);
					using (var pen = new Pen(Color.White, 1.6f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
					{
						switch (col)
						{
							case 0: g.DrawLine(pen, cx - 3.5f, cy, cx + 3.5f, cy); break;
							case 1: g.DrawLine(pen, cx - 3.5f, cy, cx + 3.5f, cy); g.DrawLine(pen, cx, cy - 3.5f, cx, cy + 3.5f); break;
							case 2: g.DrawLine(pen, cx - 3, cy - 3, cx + 3, cy + 3); g.DrawLine(pen, cx + 3, cy - 3, cx - 3, cy + 3); break;
							case 3: g.DrawLines(pen, new[] { new PointF(cx - 3.5f, cy + 1.5f), new PointF(cx, cy - 2), new PointF(cx + 3.5f, cy + 1.5f) }); break;
							case 4: g.DrawLines(pen, new[] { new PointF(cx - 3.5f, cy - 1.5f), new PointF(cx, cy + 2), new PointF(cx + 3.5f, cy - 1.5f) }); break;
						}
					}
				}
		}
		return bmp;
	}

	// ===================== Estilo moderno (plano) =====================
	// Cristal oscuro translucido, esquinas redondeadas, borde blanco muy tenue, sin brillos ni
	// halos. El azul solo como acento (raton encima / activo). Sustituye a todo lo anterior:
	// barra de abajo, barra de arriba, ventanas laterales, Pokebar, dialogos, botones, barras de
	// progreso, casillas de objetos y la barra de ataques (game_pokemonmoves/images).
	// Uso: [UiSkin]::RunModern(carpetaImagesDelCliente, carpetaImagesDeGamePokemonmoves)
	// gris oscuro neutro (deja destacar los iconos), plano, sin degradados ni brillos;
	// el azul solo como acento (raton encima / activo)
	static readonly Color Glass = Color.FromArgb(226, 17, 19, 23);
	static readonly Color GlassSolid = Color.FromArgb(246, 19, 21, 26);
	static readonly Color Header = Color.FromArgb(248, 27, 30, 36);
	static readonly Color Edge = Color.FromArgb(255, 44, 47, 55);
	static readonly Color Line = Color.FromArgb(255, 40, 43, 50);
	static readonly Color Accent = Color.FromArgb(255, 77, 166, 255);

	static Color A(int alpha, Color c) { return Color.FromArgb(alpha, c.R, c.G, c.B); }

	public static string RunModern(string imagesDir, string movesDir)
	{
		string bottom = Path.Combine(imagesDir, "bottombar");
		string top = Path.Combine(imagesDir, "topmenu");
		string ui = Path.Combine(imagesDir, "ui");

		// paneles
		Save(Flat(72, 72, 14, Glass, Edge), bottom, "bar");
		Save(Flat(48, 48, 14, Glass, Edge), top, "pill");
		Save(Flat(32, 32, 8, Glass, Edge), ui, "pokebar");
		Save(Flat(24, 24, 7, Glass, Edge), movesDir, "bar");
		Save(Flat(32, 32, 10, Glass, Edge), movesDir, "window");
		Save(Flat(24, 24, 7, GlassSolid, Edge), movesDir, "tooltip");
		Save(Flat(24, 24, 8, Color.FromArgb(255, 30, 33, 39), Color.FromArgb(255, 48, 51, 59)), movesDir, "box");

		// casillas: normal, raton encima (acento), pulsada. Solidas, un azul mas claro que el panel
		Color cellFill = Color.FromArgb(255, 38, 41, 48), cellEdge = Color.FromArgb(255, 60, 63, 72);
		Color hoverFill = Color.FromArgb(255, 48, 52, 61), hoverEdge = Accent;
		Color pressFill = Color.FromArgb(255, 28, 30, 36), pressEdge = A(200, Accent);
		Save(Flat(52, 52, 10, cellFill, cellEdge), bottom, "cell");
		Save(Flat(52, 52, 10, hoverFill, hoverEdge), bottom, "cell_hover");
		Save(Flat(52, 52, 10, pressFill, pressEdge), bottom, "cell_pressed");
		Save(Flat(38, 38, 7, cellFill, cellEdge), movesDir, "slot");
		Save(Flat(38, 38, 7, hoverFill, hoverEdge), movesDir, "slot_hover");
		Save(Flat(38, 38, 7, A(40, Accent), Accent), movesDir, "slot_active");
		Save(Flat(24, 24, 6, cellFill, cellEdge), movesDir, "button");
		Save(Flat(24, 24, 6, hoverFill, hoverEdge), movesDir, "button_hover");

		// teclas: pastilla oscura con texto claro
		Save(Flat(18, 18, 5, Color.FromArgb(255, 22, 24, 29), Color.FromArgb(255, 92, 96, 106)), bottom, "keycap");
		Save(Flat(12, 12, 3, Color.FromArgb(255, 22, 24, 29), Color.FromArgb(255, 92, 96, 106)), movesDir, "keycap");

		// botones de la barra de arriba
		Save(Flat(38, 38, 10, Color.FromArgb(255, 44, 47, 55), Color.Empty), top, "hover");
		Save(Flat(38, 38, 10, Color.FromArgb(255, 30, 32, 38), Color.Empty), top, "pressed");
		using (var on = Flat(38, 38, 10, Color.FromArgb(255, 40, 44, 54), A(140, Accent)))
		{
			using (var g = Canvas2(on))
			using (var path = Round(new RectangleF(38 / 2f - 8, 38 - 4, 16, 2.5f), 1.2f))
			using (var brush = new SolidBrush(Accent))
				g.FillPath(brush, path);
			on.Save(Path.Combine(top, "on.png"), ImageFormat.Png);
		}

		// ventanas laterales (cabecera de 23px separada por una linea) y dialogos (cabecera 27px)
		Save(Panel2(264, 283, 7, 23, Glass), ui, "miniwindow");
		Save(Panel2(256, 256, 6, 27, GlassSolid), ui, "window");
		Save(FlatButtons(), ui, "miniwindow_buttons");
		using (var close = FlatGlyphs(16, 2, false)) close.Save(Path.Combine(movesDir, "close.png"), ImageFormat.Png);
		using (var close = FlatGlyphs(16, 2, true)) close.Save(Path.Combine(movesDir, "close_hover.png"), ImageFormat.Png);

		// boton de dialogo: 3 estados de 22x23 (normal, raton encima, pulsado)
		var button = new Bitmap(22, 69, PixelFormat.Format32bppArgb);
		using (var g = Canvas2(button))
		{
			DrawFlat(g, new RectangleF(0.5f, 0.5f, 21, 22), 3, Color.FromArgb(255, 40, 43, 50), Color.FromArgb(255, 62, 65, 74));
			DrawFlat(g, new RectangleF(0.5f, 23.5f, 21, 22), 3, Color.FromArgb(255, 50, 54, 63), Accent);
			DrawFlat(g, new RectangleF(0.5f, 46.5f, 21, 22), 3, Color.FromArgb(255, 28, 30, 36), A(200, Accent));
		}
		Save(button, ui, "button");

		// barra de progreso: solo un marco fino, el centro transparente (el color va debajo)
		Save(Flat(80, 16, 2, Color.FromArgb(70, 0, 0, 0), Color.FromArgb(90, 0, 0, 0)), ui, "progressbar");
		// casilla de objeto (mochilas)
		Save(Flat(32, 32, 4, Color.FromArgb(255, 34, 37, 43), Color.FromArgb(255, 52, 55, 63)), ui, "item");

		// barras de vida / resistencia / nivel: pastilla redondeada con icono.
		// El relleno de color de OTClient es rectangular: la imagen pinta las esquinas de fuera
		// con el color del panel para que se vea redondo, y deja el centro transparente.
		string status = Path.Combine(imagesDir, "statusbar");
		Directory.CreateDirectory(status);
		Save(PillFrame(40, 18, Color.FromArgb(255, 17, 19, 23)), status, "pill");
		Save(Flat(40, 18, 9, Color.FromArgb(255, 30, 33, 39), Color.Empty), status, "track");
		// barra fina (ataques listos) y filas de la Pokebar
		Save(PillFrame(20, 8, Color.FromArgb(255, 17, 19, 23)), status, "thin_pill");
		Save(Flat(20, 6, 3, Color.FromArgb(255, 30, 33, 39), Color.Empty), status, "thin_track");
		// rellenos redondeados en blanco: el cliente los tine (UIPillBar) y les da el ancho del %
		Save(Flat(40, 18, 9, Color.White, Color.Empty), status, "pill_fill");
		Save(Flat(20, 6, 3, Color.White, Color.Empty), status, "thin_fill");
		// filas de la Pokebar: capsula redondeada (normal / raton encima / pokemon fuera) y
		// circulo del retrato. Las barras dentro usan esquinas con el color de la capsula.
		Color rowFill = Color.FromArgb(255, 38, 41, 48);
		Save(Flat(64, 52, 26, rowFill, Color.FromArgb(255, 58, 62, 71)), status, "row");
		Save(Flat(64, 52, 26, rowFill, Color.FromArgb(255, 100, 105, 118)), status, "row_hover");
		Save(Flat(64, 52, 26, rowFill, Accent), status, "row_active");
		Save(PillFrame(40, 18, rowFill), status, "pill_row");
		Save(PillFrame(20, 8, rowFill), status, "thin_pill_row");
		// marca "fuera" (punto azul con aro blanco) y botones de la cabecera de la Pokebar
		using (var dot = new Bitmap(14, 14, PixelFormat.Format32bppArgb))
		{
			using (var g = Canvas(dot))
			{
				using (var brush = new SolidBrush(Accent)) g.FillEllipse(brush, 1.5f, 1.5f, 11, 11);
				using (var pen = new Pen(Color.White, 1.6f)) g.DrawEllipse(pen, 1.5f, 1.5f, 11, 11);
			}
			dot.Save(Path.Combine(status, "out.png"), ImageFormat.Png);
		}
		// lista de Combate: capsula por criatura (normal / raton / objetivo / seguido)
		Save(Flat(48, 40, 20, rowFill, Color.FromArgb(255, 58, 62, 71)), status, "battle_row");
		Save(Flat(48, 40, 20, rowFill, Color.FromArgb(255, 100, 105, 118)), status, "battle_row_hover");
		Save(Flat(48, 40, 20, rowFill, Color.FromArgb(255, 226, 72, 64)), status, "battle_row_target");
		Save(Flat(48, 40, 20, rowFill, Color.FromArgb(255, 72, 200, 96)), status, "battle_row_follow");
		Save(PokeballGlyph(false), status, "ownmon_on");
		Save(PokeballGlyph(true), status, "ownmon_off");
		Save(LockGlyph(true), status, "lock");
		Save(LockGlyph(false), status, "unlock");
		Save(LayoutGlyph(true), status, "compact");
		Save(LayoutGlyph(false), status, "expand");
		using (var circle = new Bitmap(44, 44, PixelFormat.Format32bppArgb))
		{
			using (var g = Canvas(circle))
			using (var brush = new SolidBrush(Color.FromArgb(255, 46, 50, 58)))
				g.FillEllipse(brush, 0.5f, 0.5f, 43, 43);
			circle.Save(Path.Combine(status, "circle.png"), ImageFormat.Png);
		}
		// orbes de vida y nivel: fondo (disco + pista del anillo) y hoja con 101 anillos blancos
		// (0..100 %, 10 por fila, 84px cada uno); el cliente elige el recorte y lo tine de color
		Save(OrbBackground(84, 7), status, "orb_bg");
		Save(RingSheet(84, 7), status, "ring");
		Save(HeartIcon(18, Color.FromArgb(255, 92, 214, 112)), status, "heart_big");
		Save(StarIcon(18, Color.FromArgb(255, 245, 196, 72)), status, "star_big");
		// barras de desplazamiento: guia fina y tirador redondeado (13px de ancho como antes)
		Save(ScrollPiece(13, 20, true, 2, Color.FromArgb(255, 40, 43, 50)), ui, "scroll_track_v");
		Save(ScrollPiece(20, 13, false, 2, Color.FromArgb(255, 40, 43, 50)), ui, "scroll_track_h");
		Save(ScrollPiece(13, 16, true, 6, Color.FromArgb(255, 92, 97, 108)), ui, "scroll_thumb_v");
		Save(ScrollPiece(13, 16, true, 6, Color.FromArgb(255, 140, 146, 158)), ui, "scroll_thumb_v_hover");
		Save(ScrollPiece(13, 16, true, 6, Accent), ui, "scroll_thumb_v_pressed");
		Save(ScrollPiece(16, 13, false, 6, Color.FromArgb(255, 92, 97, 108)), ui, "scroll_thumb_h");
		Save(ScrollPiece(16, 13, false, 6, Color.FromArgb(255, 140, 146, 158)), ui, "scroll_thumb_h_hover");
		Save(ScrollPiece(16, 13, false, 6, Accent), ui, "scroll_thumb_h_pressed");

		// tienda de NPC: selector de pestanas, campo de busqueda y boton principal
		string shop = Path.Combine(imagesDir, "shop");
		Directory.CreateDirectory(shop);
		Save(Flat(32, 34, 10, Color.FromArgb(255, 24, 26, 31), Color.FromArgb(255, 44, 47, 55)), shop, "segment");
		Save(Flat(32, 28, 8, Color.FromArgb(255, 44, 104, 182), Color.Empty), shop, "tab_on");
		Save(Flat(32, 28, 8, Color.FromArgb(255, 34, 37, 44), Color.Empty), shop, "tab_hover");
		Save(Flat(32, 30, 8, Color.FromArgb(255, 24, 26, 31), Color.FromArgb(255, 52, 55, 63)), shop, "field");
		Save(Flat(32, 30, 8, Color.FromArgb(255, 24, 26, 31), A(220, Accent)), shop, "field_focus");
		Save(Flat(32, 32, 9, Color.FromArgb(255, 44, 104, 182), Color.Empty), shop, "primary");
		Save(Flat(32, 32, 9, Color.FromArgb(255, 58, 124, 208), Color.Empty), shop, "primary_hover");
		Save(Flat(32, 32, 9, Color.FromArgb(255, 34, 82, 146), Color.Empty), shop, "primary_pressed");
		Save(Flat(32, 32, 9, Color.FromArgb(255, 30, 33, 39), Color.Empty), shop, "primary_disabled");
		Save(Flat(32, 32, 9, Color.FromArgb(255, 38, 41, 48), Color.FromArgb(255, 60, 63, 72)), shop, "secondary");
		Save(Flat(32, 32, 9, Color.FromArgb(255, 48, 52, 61), Color.FromArgb(255, 92, 96, 108)), shop, "secondary_hover");
		Save(HeartIcon(14), status, "heart");
		Save(BoltIcon(14), status, "stamina");
		Save(StarIcon(14), status, "star");
		return "ok";
	}

	static Bitmap PillFrame(int w, int h, Color outside)
	{
		var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(0, 0, w, h);
			using (var path = Round(r, h / 2f))
			using (var region = new Region(new RectangleF(0, 0, w, h)))
			{
				region.Exclude(path);
				using (var brush = new SolidBrush(outside))
					g.FillRegion(brush, region);
			}
			using (var path = Round(new RectangleF(0.5f, 0.5f, w - 1, h - 1), h / 2f - 0.5f))
			using (var pen = new Pen(Color.FromArgb(90, 0, 0, 0), 1))
				g.DrawPath(pen, path);
		}
		return bmp;
	}

	static Bitmap OrbBackground(int size, float thick)
	{
		var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			float r = thick / 2f + 0.5f;
			using (var pen = new Pen(Color.FromArgb(255, 35, 38, 44), thick))
				g.DrawEllipse(pen, r, r, size - 2 * r, size - 2 * r);
			float inner = thick + 0.5f;
			using (var brush = new SolidBrush(Color.FromArgb(240, 21, 23, 27)))
				g.FillEllipse(brush, inner, inner, size - 2 * inner, size - 2 * inner);
			using (var pen = new Pen(Color.FromArgb(255, 44, 47, 55), 1))
				g.DrawEllipse(pen, 0.5f, 0.5f, size - 1, size - 1);
		}
		return bmp;
	}

	static Bitmap RingSheet(int size, float thick)
	{
		const int cols = 10;
		var bmp = new Bitmap(size * cols, size * 11, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		using (var pen = new Pen(Color.White, thick) { StartCap = LineCap.Round, EndCap = LineCap.Round })
		{
			float r = thick / 2f + 0.5f;
			for (int p = 1; p <= 100; p++)
			{
				int x = (p % cols) * size, y = (p / cols) * size;
				var rect = new RectangleF(x + r, y + r, size - 2 * r, size - 2 * r);
				if (p == 100)
					using (var full = new Pen(Color.White, thick)) g.DrawEllipse(full, rect);
				else
					g.DrawArc(pen, rect, -90, 360f * p / 100f);
			}
		}
		return bmp;
	}

	// pokeball pequena para el filtro "mi Pokemon" de Combate; tachada = oculto
	static Bitmap PokeballGlyph(bool crossed)
	{
		var bmp = new Bitmap(14, 14, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(1.5f, 1.5f, 11, 11);
			using (var top = new SolidBrush(Color.FromArgb(255, 226, 64, 64)))
				g.FillPie(top, r.X, r.Y, r.Width, r.Height, 180, 180);
			using (var bottom = new SolidBrush(Color.FromArgb(255, 236, 236, 240)))
				g.FillPie(bottom, r.X, r.Y, r.Width, r.Height, 0, 180);
			using (var pen = new Pen(Color.FromArgb(255, 20, 20, 24), 1.2f))
			{
				g.DrawEllipse(pen, r);
				g.DrawLine(pen, r.Left, 7, r.Right, 7);
			}
			using (var dot = new SolidBrush(Color.White))
				g.FillEllipse(dot, 5.5f, 5.5f, 3, 3);
			if (crossed)
			{
				using (var shade = new SolidBrush(Color.FromArgb(150, 17, 19, 23)))
					g.FillEllipse(shade, r);
				using (var pen = new Pen(Color.FromArgb(255, 230, 230, 235), 1.6f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
					g.DrawLine(pen, 2, 12, 12, 2);
			}
		}
		return bmp;
	}

	// pastilla centrada de "thick" px dentro de una pieza de w x h (vertical u horizontal)
	static Bitmap ScrollPiece(int w, int h, bool vertical, float thick, Color color)
	{
		var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			RectangleF r = vertical
				? new RectangleF((w - thick) / 2f, 1, thick, h - 2)
				: new RectangleF(1, (h - thick) / 2f, w - 2, thick);
			using (var path = Round(r, thick / 2f - 0.01f))
			using (var brush = new SolidBrush(color))
				g.FillPath(brush, path);
		}
		return bmp;
	}

	static Bitmap LockGlyph(bool closed)
	{
		var bmp = new Bitmap(14, 14, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		using (var pen = new Pen(Color.FromArgb(220, 255, 255, 255), 1.4f))
		using (var brush = new SolidBrush(Color.FromArgb(220, 255, 255, 255)))
		{
			// arco del candado (abierto: desplazado a la derecha)
			float x = closed ? 4f : 6.5f;
			g.DrawArc(pen, x, 1.5f, 6, 7, 180, 180);
			g.DrawLine(pen, x, 5f, x, closed ? 7f : 5f);
			g.DrawLine(pen, x + 6, 5f, x + 6, 7f);
			using (var path = Round(new RectangleF(2.5f, 6.5f, 9, 6.5f), 1.5f))
				g.FillPath(brush, path);
		}
		return bmp;
	}

	// compacto: rejilla de 4 cuadrados; normal: lista de 3 lineas
	static Bitmap LayoutGlyph(bool compact)
	{
		var bmp = new Bitmap(14, 14, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		using (var brush = new SolidBrush(Color.FromArgb(220, 255, 255, 255)))
		{
			if (compact)
			{
				foreach (var p in new[] { new PointF(2, 2), new PointF(8, 2), new PointF(2, 8), new PointF(8, 8) })
					using (var path = Round(new RectangleF(p.X, p.Y, 4.5f, 4.5f), 1)) g.FillPath(brush, path);
			}
			else
			{
				for (int i = 0; i < 3; i++)
					using (var path = Round(new RectangleF(2, 2.5f + i * 4, 10, 2), 1)) g.FillPath(brush, path);
			}
		}
		return bmp;
	}

	static Bitmap HeartIcon(int s) { return HeartIcon(s, Color.FromArgb(255, 222, 255, 222)); }

	static Bitmap HeartIcon(int s, Color color)
	{
		var bmp = new Bitmap(s, s, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		using (var path = new GraphicsPath())
		{
			float w = s - 2, x = 1, y = 2;
			path.AddBezier(x + w / 2, y + w * 0.95f, x - w * 0.05f, y + w * 0.5f, x + w * 0.05f, y - w * 0.1f, x + w / 2, y + w * 0.22f);
			path.AddBezier(x + w / 2, y + w * 0.22f, x + w * 0.95f, y - w * 0.1f, x + w * 1.05f, y + w * 0.5f, x + w / 2, y + w * 0.95f);
			using (var brush = new SolidBrush(color))
				g.FillPath(brush, path);
		}
		return bmp;
	}

	static Bitmap BoltIcon(int s)
	{
		var bmp = new Bitmap(s, s, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		using (var brush = new SolidBrush(Color.FromArgb(255, 222, 236, 255)))
			g.FillPolygon(brush, new[] { new PointF(s * 0.62f, 0.5f), new PointF(s * 0.18f, s * 0.58f), new PointF(s * 0.47f, s * 0.58f),
				new PointF(s * 0.36f, s - 0.5f), new PointF(s * 0.84f, s * 0.38f), new PointF(s * 0.54f, s * 0.38f) });
		return bmp;
	}

	static Bitmap StarIcon(int s) { return StarIcon(s, Color.FromArgb(255, 255, 238, 170)); }

	static Bitmap StarIcon(int s, Color color)
	{
		var bmp = new Bitmap(s, s, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var pts = new PointF[10];
			float c = s / 2f;
			for (int i = 0; i < 10; i++)
			{
				double a = -Math.PI / 2 + i * Math.PI / 5;
				float r = (i % 2 == 0) ? s / 2f - 0.5f : s * 0.21f;
				pts[i] = new PointF(c + (float)(Math.Cos(a) * r), c + 0.6f + (float)(Math.Sin(a) * r));
			}
			using (var brush = new SolidBrush(color))
				g.FillPolygon(brush, pts);
		}
		return bmp;
	}

	static Graphics Canvas2(Bitmap bmp)
	{
		var g = Graphics.FromImage(bmp);
		g.SmoothingMode = SmoothingMode.AntiAlias;
		g.PixelOffsetMode = PixelOffsetMode.HighQuality;
		g.CompositingQuality = CompositingQuality.HighQuality;
		return g;
	}

	static void DrawFlat(Graphics g, RectangleF r, float radius, Color fill, Color border)
	{
		using (var path = Round(r, radius))
		{
			if (fill != Color.Empty)
				using (var brush = new SolidBrush(fill))
					g.FillPath(brush, path);
			if (border != Color.Empty)
				using (var pen = new Pen(border, 1))
					g.DrawPath(pen, path);
		}
	}

	static Bitmap Flat(int w, int h, float radius, Color fill, Color border)
	{
		var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
			DrawFlat(g, new RectangleF(0.5f, 0.5f, w - 1, h - 1), radius, fill, border);
		return bmp;
	}

	static Bitmap Panel2(int w, int h, float radius, int header, Color fill)
	{
		var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
		using (var g = Canvas(bmp))
		{
			var r = new RectangleF(0.5f, 0.5f, w - 1, h - 1);
			using (var path = Round(r, radius))
			{
				using (var brush = new SolidBrush(fill))
					g.FillPath(brush, path);
				// cabecera: el mismo azul un poco mas claro, plano
				g.SetClip(new RectangleF(0, 0, w, header));
				using (var brush = new SolidBrush(Header))
					g.FillPath(brush, path);
				g.ResetClip();
				using (var pen = new Pen(Line, 1))
					g.DrawLine(pen, 1, header - 0.5f, w - 2, header - 0.5f);
				using (var pen = new Pen(Edge, 1))
					g.DrawPath(pen, path);
			}
		}
		return bmp;
	}

	// botones de las ventanas laterales: solo el simbolo; con el raton encima, un fondo suave
	static Bitmap FlatButtons()
	{
		const int s = 14;
		var bmp = new Bitmap(s * 7, s * 3, PixelFormat.Format32bppArgb);
		using (var g = Canvas2(bmp))
		{
			int[] bgAlpha = { 0, 34, 18 };
			int[] glyphAlpha = { 150, 255, 210 };
			for (int row = 0; row < 3; row++)
				for (int col = 0; col < 7; col++)
				{
					if (bgAlpha[row] > 0)
						DrawFlat(g, new RectangleF(col * s + 0.5f, row * s + 0.5f, s - 1, s - 1), 4, Color.FromArgb(bgAlpha[row], 255, 255, 255), Color.Empty);
					float cx = col * s + s / 2f, cy = row * s + s / 2f;
					using (var pen = new Pen(Color.FromArgb(glyphAlpha[row], 255, 255, 255), 1.4f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
					{
						switch (col)
						{
							case 0: g.DrawLine(pen, cx - 3, cy, cx + 3, cy); break;
							case 1: g.DrawLine(pen, cx - 3, cy, cx + 3, cy); g.DrawLine(pen, cx, cy - 3, cx, cy + 3); break;
							case 2: g.DrawLine(pen, cx - 2.6f, cy - 2.6f, cx + 2.6f, cy + 2.6f); g.DrawLine(pen, cx + 2.6f, cy - 2.6f, cx - 2.6f, cy + 2.6f); break;
							case 3: g.DrawLines(pen, new[] { new PointF(cx - 3, cy + 1.5f), new PointF(cx, cy - 1.5f), new PointF(cx + 3, cy + 1.5f) }); break;
							case 4: g.DrawLines(pen, new[] { new PointF(cx - 3, cy - 1.5f), new PointF(cx, cy + 1.5f), new PointF(cx + 3, cy - 1.5f) }); break;
						}
					}
				}
		}
		return bmp;
	}

	static Bitmap FlatGlyphs(int s, int col, bool hover)
	{
		var bmp = new Bitmap(s, s, PixelFormat.Format32bppArgb);
		using (var g = Canvas2(bmp))
		{
			if (hover)
				DrawFlat(g, new RectangleF(0.5f, 0.5f, s - 1, s - 1), 4, Color.FromArgb(34, 255, 255, 255), Color.Empty);
			float c = s / 2f;
			using (var pen = new Pen(Color.FromArgb(hover ? 255 : 170, 255, 255, 255), 1.5f) { StartCap = LineCap.Round, EndCap = LineCap.Round })
			{
				g.DrawLine(pen, c - 3.5f, c - 3.5f, c + 3.5f, c + 3.5f);
				g.DrawLine(pen, c + 3.5f, c - 3.5f, c - 3.5f, c + 3.5f);
			}
		}
		return bmp;
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
			// brillo interior arriba: solo en las esquinas de arriba (dentro del image-border), si llega
			// a la zona central que se estira se ve como una raya a media altura
			var inner = new RectangleF(r.X + borderWidth + 1, r.Y + borderWidth + 1, r.Width - 2 * borderWidth - 2, r.Height - 2 * borderWidth - 2);
			using (var path = Round(inner, Math.Max(2, radius - borderWidth - 1)))
			using (var pen = new Pen(Color.FromArgb(45, 255, 255, 255), 1))
			{
				g.SetClip(new RectangleF(0, 0, w, halo + radius));
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
