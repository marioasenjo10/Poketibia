using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

// Cambia el dibujo de UN objeto por un PNG de 32x32 (con transparencia).
// No pisa el sprite original (otros objetos pueden compartirlo): anade el dibujo nuevo al final
// de Tibia.spr y apunta a el solo las entradas de ese objeto en Tibia.dat. El servidor no cambia.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,SpriteSwap.cs -ReferencedAssemblies System.Drawing
//                   [SpriteSwap]::Run(dat, spr, otb, idServidor, png32, preview.png, $true)  # $true = solo comprobar
public static class SpriteSwap
{
	public static string Run(string datPath, string sprPath, string otbPath, int serverId, string pngPath, string previewPath, bool dryRun)
	{
		var log = new StringBuilder();
		var otb = Otb.Load(otbPath);
		OtbItem found = null;
		foreach (var it in otb.Items) if (it.ServerId == serverId) { found = it; break; }
		if (found == null) throw new Exception("El objeto " + serverId + " no esta en items.otb");
		int clientId = found.ClientId;

		var dat = Dat.Load(datPath);
		if (!dat.Items.ContainsKey(clientId)) throw new Exception("El id de cliente " + clientId + " no existe en Tibia.dat");
		var thing = dat.Items[clientId];
		log.AppendLine(string.Format("Objeto {0} -> id de cliente {1}: {2}x{3}, {4} sprites", serverId, clientId, thing.Width, thing.Height, thing.SpritePositions.Count));
		if (thing.Width != 1 || thing.Height != 1) throw new Exception("Solo objetos de 1x1 casillas");

		var spr = Spr.Load(sprPath);
		var px = LoadPixels(pngPath);
		var encoded = Spr.Encode(px);
		uint newId = (uint)(spr.Count + 1);

		// el dibujo antiguo (primer sprite) para la vista previa
		var old = spr.Decode(dat.SpriteAt(thing.SpritePositions[0]));
		if (previewPath != null) SavePreview(old, px, previewPath);

		if (dryRun)
		{
			log.AppendLine("Prueba OK (no se ha modificado nada). Sprite nuevo seria el " + newId);
			return log.ToString();
		}

		string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
		File.Copy(datPath, datPath + ".bak-" + stamp);
		File.Copy(sprPath, sprPath + ".bak-" + stamp);

		spr.Save(sprPath + ".new", new List<byte[]> { encoded });
		var data = (byte[])dat.Data.Clone();
		foreach (int pos in thing.SpritePositions)
			Array.Copy(BitConverter.GetBytes(newId), 0, data, pos, 4);
		File.WriteAllBytes(datPath + ".new", data);

		// validar antes de sustituir
		Dat.Load(datPath + ".new");
		var check = Spr.Load(sprPath + ".new");
		check.Decode(newId);

		File.Copy(datPath + ".new", datPath, true); File.Delete(datPath + ".new");
		File.Copy(sprPath + ".new", sprPath, true); File.Delete(sprPath + ".new");
		log.AppendLine("Guardado: sprite " + newId + ". Copias: *.bak-" + stamp);
		return log.ToString();
	}

	static byte[] LoadPixels(string path)
	{
		using (var src = new Bitmap(path))
		{
			if (src.Width != 32 || src.Height != 32) throw new Exception("El PNG debe medir 32x32");
			var px = new byte[32 * 32 * 4];
			for (int y = 0; y < 32; y++)
				for (int x = 0; x < 32; x++)
				{
					var c = src.GetPixel(x, y);
					int i = (y * 32 + x) * 4;
					// casi transparente -> transparente (el formato guarda tramos de pixeles vacios)
					if (c.A < 12) continue;
					px[i] = c.R; px[i + 1] = c.G; px[i + 2] = c.B; px[i + 3] = c.A;
				}
			return px;
		}
	}

	static void SavePreview(byte[] oldPx, byte[] newPx, string path)
	{
		const int s = 4;
		using (var bmp = new Bitmap(32 * s * 2 + 24, 32 * s + 16, PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(bmp)) g.Clear(Color.FromArgb(255, 38, 41, 48));
			Draw(bmp, oldPx, 8, 8, s);
			Draw(bmp, newPx, 16 + 32 * s, 8, s);
			bmp.Save(path, ImageFormat.Png);
		}
	}

	static void Draw(Bitmap bmp, byte[] px, int ox, int oy, int s)
	{
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				int i = (y * 32 + x) * 4, a = px[i + 3];
				if (a == 0) continue;
				for (int dy = 0; dy < s; dy++)
					for (int dx = 0; dx < s; dx++)
					{
						var bg = bmp.GetPixel(ox + x * s + dx, oy + y * s + dy);
						bmp.SetPixel(ox + x * s + dx, oy + y * s + dy, Color.FromArgb(255,
							(px[i] * a + bg.R * (255 - a)) / 255, (px[i + 1] * a + bg.G * (255 - a)) / 255, (px[i + 2] * a + bg.B * (255 - a)) / 255));
					}
			}
	}
}
