using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

// Aplica Remaster (bordes suavizados y, si se pide, contorno) a los sprites de unos objetos y
// proyectiles concretos del cliente. No pisa los sprites originales: anade los nuevos al final
// de Tibia.spr y apunta solo esas entradas de Tibia.dat a ellos (un sprite compartido se
// convierte una sola vez). El servidor no cambia.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,Remaster.cs,RemasterApply.cs -ReferencedAssemblies System.Drawing
//                   [RemasterApply]::Run(dat, spr, otb, "item:26662 item:26661", "missile:55", $true)  # $true = prueba
//   conContorno: objetos (item:<id de servidor>) -> suavizado + contorno
//   sinContorno: proyectiles (missile:<id>) u objetos -> solo suavizado
public static class RemasterApply
{
	public static string Run(string datPath, string sprPath, string otbPath, string conContorno, string sinContorno, bool dryRun)
	{
		var log = new StringBuilder();
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);
		var otb = Otb.Load(otbPath);
		var data = (byte[])dat.Data.Clone();
		var newSprites = new List<byte[]>();
		var mapOutline = new Dictionary<uint, uint>();
		var mapPlain = new Dictionary<uint, uint>();
		int things = 0, positions = 0;

		foreach (var pass in new[] { new { spec = conContorno, outline = true }, new { spec = sinContorno, outline = false } })
		{
			if (string.IsNullOrEmpty(pass.spec)) continue;
			var map = pass.outline ? mapOutline : mapPlain;
			foreach (var token in pass.spec.Split(new[] { ' ', ',', ';' }, StringSplitOptions.RemoveEmptyEntries))
			{
				var kv = token.Split(':');
				int id = int.Parse(kv[1]);
				DatThing t = null;
				if (kv[0] == "item")
				{
					foreach (var it in otb.Items)
						if (it.ServerId == id) { dat.Items.TryGetValue(it.ClientId, out t); break; }
				}
				else if (kv[0] == "missile") dat.Missiles.TryGetValue(id, out t);
				else if (kv[0] == "effect") dat.Effects.TryGetValue(id, out t);
				if (t == null) { log.AppendLine(token + ": no encontrado"); continue; }
				things++;
				foreach (int pos in t.SpritePositions)
				{
					uint old = dat.SpriteAt(pos);
					if (old == 0) continue;
					uint n;
					if (!map.TryGetValue(old, out n))
					{
						var px = ToArgb(spr.Decode(old));
						var outPx = Remaster.Sprite(px);
						if (pass.outline) outPx = Remaster.Outline(outPx);
						newSprites.Add(Spr.Encode(ToRgba(outPx)));
						n = (uint)(spr.Count + newSprites.Count);
						map[old] = n;
					}
					Array.Copy(BitConverter.GetBytes(n), 0, data, pos, 4);
					positions++;
				}
			}
		}
		log.AppendLine(string.Format("{0} objetos/proyectiles, {1} posiciones, {2} sprites nuevos ({3}-{4})",
			things, positions, newSprites.Count, spr.Count + 1, spr.Count + newSprites.Count));
		if (dryRun) { log.AppendLine("Prueba OK (no se ha modificado nada)."); return log.ToString(); }

		string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
		File.Copy(datPath, datPath + ".bak-" + stamp);
		File.Copy(sprPath, sprPath + ".bak-" + stamp);
		spr.Save(sprPath + ".new", newSprites);
		File.WriteAllBytes(datPath + ".new", data);
		Dat.Load(datPath + ".new");
		var check = Spr.Load(sprPath + ".new");
		for (int i = 1; i <= newSprites.Count; i++) check.Decode((uint)(spr.Count + i));
		File.Copy(datPath + ".new", datPath, true); File.Delete(datPath + ".new");
		File.Copy(sprPath + ".new", sprPath, true); File.Delete(sprPath + ".new");
		log.AppendLine("Guardado. Copias: *.bak-" + stamp);
		return log.ToString();
	}

	static int[] ToArgb(byte[] rgba)
	{
		var res = new int[1024];
		for (int i = 0; i < 1024; i++)
			res[i] = (rgba[i * 4 + 3] << 24) | (rgba[i * 4] << 16) | (rgba[i * 4 + 1] << 8) | rgba[i * 4 + 2];
		return res;
	}

	static byte[] ToRgba(int[] argb)
	{
		var res = new byte[4096];
		for (int i = 0; i < 1024; i++)
		{
			int c = argb[i];
			res[i * 4] = (byte)((c >> 16) & 255); res[i * 4 + 1] = (byte)((c >> 8) & 255);
			res[i * 4 + 2] = (byte)(c & 255); res[i * 4 + 3] = (byte)((c >> 24) & 255);
		}
		return res;
	}
}
