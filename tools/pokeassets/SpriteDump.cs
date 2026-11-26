using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

// Vuelca a PNG todos los dibujos de objetos, proyectiles y efectos (cada variante en fila:
// cantidades de un apilable, direcciones de un proyectil, fotogramas de un efecto).
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,SpriteDump.cs -ReferencedAssemblies System.Drawing
//                   [SpriteDump]::Run(dat, spr, otb, carpeta, "item:26662 missile:55 effect:734")
//   item:<id de servidor>, citem:<id de cliente>, missile:<id>, effect:<id>, creature:<looktype>
public static class SpriteDump
{
	public static string Run(string datPath, string sprPath, string otbPath, string outDir, string spec)
	{
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);
		Otb otb = otbPath != null ? Otb.Load(otbPath) : null;
		Directory.CreateDirectory(outDir);
		var log = new StringBuilder();
		foreach (var token in spec.Split(new[] { ' ', ',', ';', '\n' }, StringSplitOptions.RemoveEmptyEntries))
		{
			var kv = token.Split(':');
			string kind = kv[0];
			int id = int.Parse(kv[1]);
			DatThing t = null;
			string name = token.Replace(':', '_');
			if (kind == "item")
			{
				int clientId = -1;
				foreach (var it in otb.Items) if (it.ServerId == id) { clientId = it.ClientId; break; }
				if (clientId < 0 || !dat.Items.ContainsKey(clientId)) { log.AppendLine(token + ": no encontrado"); continue; }
				t = dat.Items[clientId];
				name += "_c" + clientId;
			}
			else if (kind == "citem") dat.Items.TryGetValue(id, out t);
			else if (kind == "missile") dat.Missiles.TryGetValue(id, out t);
			else if (kind == "effect") dat.Effects.TryGetValue(id, out t);
			else if (kind == "creature") dat.Creatures.TryGetValue(id, out t);
			if (t == null) { log.AppendLine(token + ": no encontrado"); continue; }
			int frames = t.PatX * t.PatY * t.PatZ * t.Phases;
			log.AppendLine(string.Format("{0}: {1}x{2} casillas, capas {3}, patrones {4}x{5}x{6}, fases {7} -> {8} dibujos",
				token, t.Width, t.Height, t.Layers, t.PatX, t.PatY, t.PatZ, t.Phases, frames));
			SaveStrip(dat, spr, t, Path.Combine(outDir, name + ".png"));
		}
		return log.ToString();
	}

	// una tira con todos los dibujos: orden fase > z > y > x (como los guarda el .dat)
	static void SaveStrip(Dat dat, Spr spr, DatThing t, string path)
	{
		int fw = t.Width * 32, fh = t.Height * 32;
		int frames = t.PatX * t.PatY * t.PatZ * t.Phases;
		using (var bmp = new Bitmap(Math.Max(1, frames * fw), fh, PixelFormat.Format32bppArgb))
		{
			int n = 0;
			for (int ph = 0; ph < t.Phases; ph++)
				for (int z = 0; z < t.PatZ; z++)
					for (int y = 0; y < t.PatY; y++)
						for (int x = 0; x < t.PatX; x++, n++)
							for (int l = 0; l < t.Layers; l++)
								for (int hy = 0; hy < t.Height; hy++)
									for (int wx = 0; wx < t.Width; wx++)
									{
										int index = ((((((ph * t.PatZ + z) * t.PatY + y) * t.PatX + x) * t.Layers + l) * t.Height + hy) * t.Width + wx);
										if (index >= t.SpritePositions.Count) continue;
										uint sid = dat.SpriteAt(t.SpritePositions[index]);
										if (sid == 0) continue;
										var px = spr.Decode(sid);
										int ox = n * fw + (t.Width - 1 - wx) * 32, oy = (t.Height - 1 - hy) * 32;
										for (int py = 0; py < 32; py++)
											for (int pxx = 0; pxx < 32; pxx++)
											{
												int i = (py * 32 + pxx) * 4, a = px[i + 3];
												if (a == 0) continue;
												bmp.SetPixel(ox + pxx, oy + py, Color.FromArgb(a, px[i], px[i + 1], px[i + 2]));
											}
									}
			bmp.Save(path, ImageFormat.Png);
		}
	}
}
