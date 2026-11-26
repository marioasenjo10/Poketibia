using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

// Cadaver de un shiny con los colores de su dibujo vivo: compara pixel a pixel el outfit normal con el
// shiny (mismo dibujo recoloreado), saca la tabla color normal -> color shiny y la aplica al cadaver
// NORMAL. El resultado sustituye los sprites del cadaver shiny (anade sprites nuevos al final de
// Tibia.spr y apunta a ellos solo las entradas de ese objeto en Tibia.dat). El servidor no cambia.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,CorpseRecolor.cs -ReferencedAssemblies System.Drawing
//   [CorpseRecolor]::Run(dat, spr, otb, lookNormal, lookShiny, cadaverNormal, cadaverShiny, preview.png, $true)  # $true = solo comprobar
public static class CorpseRecolor
{
	public static string Run(string datPath, string sprPath, string otbPath, int lookNormal, int lookShiny,
		int corpseNormal, int corpseShiny, string previewPath, bool dryRun)
	{
		var log = new StringBuilder();
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);
		var otb = Otb.Load(otbPath);

		DatThing normal, shiny;
		if (!dat.Creatures.TryGetValue(lookNormal, out normal)) throw new Exception("No existe el outfit " + lookNormal);
		if (!dat.Creatures.TryGetValue(lookShiny, out shiny)) throw new Exception("No existe el outfit " + lookShiny);
		if (normal.SpritePositions.Count != shiny.SpritePositions.Count) throw new Exception("Los outfits no tienen el mismo numero de sprites");

		// votos: color normal -> (color shiny -> veces)
		var votes = new Dictionary<int, Dictionary<int, int>>();
		for (int s = 0; s < normal.SpritePositions.Count; s++)
		{
			uint a = dat.SpriteAt(normal.SpritePositions[s]), b = dat.SpriteAt(shiny.SpritePositions[s]);
			if (a == 0 || b == 0) continue;
			var pa = spr.Decode(a); var pb = spr.Decode(b);
			for (int i = 0; i < 32 * 32 * 4; i += 4)
			{
				if (pa[i + 3] == 0 || pb[i + 3] == 0) continue;
				int ka = Rgb(pa, i), kb = Rgb(pb, i);
				Dictionary<int, int> d;
				if (!votes.TryGetValue(ka, out d)) votes[ka] = d = new Dictionary<int, int>();
				int n; d.TryGetValue(kb, out n); d[kb] = n + 1;
			}
		}
		var map = new Dictionary<int, int>();
		foreach (var kv in votes)
		{
			int best = 0, bestN = -1;
			foreach (var c in kv.Value) if (c.Value > bestN) { best = c.Key; bestN = c.Value; }
			map[kv.Key] = best;
		}
		log.AppendLine("Colores en la tabla: " + map.Count);

		var thingNormal = dat.Items[ClientId(otb, corpseNormal)];
		var thingShiny = dat.Items[ClientId(otb, corpseShiny)];
		if (thingNormal.SpritePositions.Count != thingShiny.SpritePositions.Count) throw new Exception("Los cadaveres no tienen el mismo tamano");

		var data = (byte[])dat.Data.Clone();
		var added = new List<byte[]>();
		var newPixels = new List<byte[]>();
		int exact = 0, near = 0;
		for (int s = 0; s < thingNormal.SpritePositions.Count; s++)
		{
			uint sid = dat.SpriteAt(thingNormal.SpritePositions[s]);
			byte[] px = sid == 0 ? new byte[32 * 32 * 4] : spr.Decode(sid);
			var outPx = (byte[])px.Clone();
			for (int i = 0; i < 32 * 32 * 4; i += 4)
			{
				if (px[i + 3] == 0) continue;
				int k = Rgb(px, i), to;
				if (map.TryGetValue(k, out to)) { exact++; }
				else
				{
					// color que no sale en el outfit: el mas parecido de la tabla y su mismo desplazamiento
					int nearest = Nearest(map, k); near++;
					int t = map[nearest];
					to = Pack(Clamp(R(k) + R(t) - R(nearest)), Clamp(G(k) + G(t) - G(nearest)), Clamp(B(k) + B(t) - B(nearest)));
				}
				outPx[i] = (byte)R(to); outPx[i + 1] = (byte)G(to); outPx[i + 2] = (byte)B(to);
			}
			newPixels.Add(outPx);
			if (sid == 0) { Array.Copy(BitConverter.GetBytes(0u), 0, data, thingShiny.SpritePositions[s], 4); continue; }
			added.Add(Spr.Encode(outPx));
			uint newId = (uint)(spr.Count + added.Count);
			Array.Copy(BitConverter.GetBytes(newId), 0, data, thingShiny.SpritePositions[s], 4);
		}
		log.AppendLine(string.Format("Pixeles: {0} con color exacto, {1} aproximados. Sprites nuevos: {2}", exact, near, added.Count));
		if (!string.IsNullOrEmpty(previewPath)) SavePreview(thingNormal, newPixels, previewPath);

		if (dryRun)
		{
			log.AppendLine("Prueba OK (no se ha modificado nada).");
			return log.ToString();
		}
		string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
		File.Copy(datPath, datPath + ".bak-" + stamp);
		File.Copy(sprPath, sprPath + ".bak-" + stamp);
		spr.Save(sprPath + ".new", added);
		File.WriteAllBytes(datPath + ".new", data);
		Dat.Load(datPath + ".new");
		var check = Spr.Load(sprPath + ".new");
		check.Decode((uint)(spr.Count + added.Count));
		File.Copy(datPath + ".new", datPath, true); File.Delete(datPath + ".new");
		File.Copy(sprPath + ".new", sprPath, true); File.Delete(sprPath + ".new");
		log.AppendLine("Guardado. Copias: *.bak-" + stamp);
		return log.ToString();
	}

	static int ClientId(Otb otb, int serverId)
	{
		foreach (var it in otb.Items) if (it.ServerId == serverId) return it.ClientId;
		throw new Exception("El objeto " + serverId + " no esta en items.otb");
	}

	static int Rgb(byte[] p, int i) { return Pack(p[i], p[i + 1], p[i + 2]); }
	static int Pack(int r, int g, int b) { return (r << 16) | (g << 8) | b; }
	static int R(int c) { return (c >> 16) & 255; }
	static int G(int c) { return (c >> 8) & 255; }
	static int B(int c) { return c & 255; }
	static int Clamp(int v) { return v < 0 ? 0 : (v > 255 ? 255 : v); }

	static int Nearest(Dictionary<int, int> map, int k)
	{
		int best = 0; long bestD = long.MaxValue;
		foreach (var c in map.Keys)
		{
			long dr = R(c) - R(k), dg = G(c) - G(k), db = B(c) - B(k);
			long d = dr * dr * 3 + dg * dg * 4 + db * db * 2;
			if (d < bestD) { bestD = d; best = c; }
		}
		return best;
	}

	// vista previa del cadaver nuevo (casillas colocadas como las pinta el cliente), ampliado x3
	static void SavePreview(DatThing t, List<byte[]> sprites, string path)
	{
		int w = t.Width * 32, h = t.Height * 32, scale = 3;
		using (var bmp = new Bitmap(w * scale, h * scale, PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(bmp)) g.Clear(Color.FromArgb(255, 60, 90, 50));
			for (int hy = 0; hy < t.Height; hy++)
				for (int wx = 0; wx < t.Width; wx++)
				{
					int index = hy * t.Width + wx;
					if (index >= sprites.Count) continue;
					var px = sprites[index];
					int ox = (t.Width - 1 - wx) * 32, oy = (t.Height - 1 - hy) * 32;
					for (int py = 0; py < 32; py++)
						for (int pxx = 0; pxx < 32; pxx++)
						{
							int i = (py * 32 + pxx) * 4;
							if (px[i + 3] == 0) continue;
							var c = Color.FromArgb(255, px[i], px[i + 1], px[i + 2]);
							for (int sy = 0; sy < scale; sy++)
								for (int sx = 0; sx < scale; sx++)
									bmp.SetPixel((ox + pxx) * scale + sx, (oy + py) * scale + sy, c);
						}
				}
			bmp.Save(path, ImageFormat.Png);
		}
	}
}
