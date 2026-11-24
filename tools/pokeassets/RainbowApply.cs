using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;

// Genera, para cada aspecto de pokemon, una copia con el contorno arcoiris (RainbowOutline) y la
// anade a Tibia.dat como criatura nueva (al final de las criaturas; los sprites nuevos van al
// final de Tibia.spr). Los aspectos de 1 casilla pasan a 2x2 para que quepa el brillo.
// Escribe la tabla para el servidor (aspecto normal -> aspecto Premier) en un .lua.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,RainbowOutline.cs,RainbowApply.cs -ReferencedAssemblies System.Drawing
//                   [RainbowApply]::Run(dat, spr, carpetaMonstruos, salida.lua, $true)  # $true = prueba
public static class RainbowApply
{
	public class Group
	{
		public int Type, W, H, Exact, Layers, PX, PY, PZ, Phases, SpriteStart;
		public byte[] Anim; // datos de animacion (si phases > 1)
	}

	static int U16(byte[] d, int p) { return d[p] | (d[p + 1] << 8); }

	// atributos de la entrada (hasta 0xFF incluido) y sus grupos de fotogramas
	public static int ParseEntry(Dat dat, DatThing t, List<Group> groups)
	{
		var d = dat.Data;
		int p = t.Start;
		while (true)
		{
			byte a = d[p++];
			if (a == 0xFF) break;
			switch (a)
			{
				case 0: case 8: case 9: case 26: case 29: case 30: case 33: case 35: p += 2; break;
				case 22: case 25: p += 4; break;
				case 34: p += 6; p += 2 + U16(d, p); p += 4; break;
			}
		}
		int attrEnd = p;
		int count = 1;
		if (dat.IdleAnimations) count = d[p++];
		for (int g = 0; g < count; g++)
		{
			var gr = new Group();
			if (dat.IdleAnimations) gr.Type = d[p++];
			gr.W = d[p++]; gr.H = d[p++];
			gr.Exact = (gr.W > 1 || gr.H > 1) ? d[p++] : 32;
			gr.Layers = d[p++]; gr.PX = d[p++]; gr.PY = d[p++]; gr.PZ = d[p++]; gr.Phases = d[p++];
			if (gr.Phases > 1)
			{
				int n = 6 + gr.Phases * 8;
				gr.Anim = new byte[n];
				Array.Copy(d, p, gr.Anim, 0, n);
				p += n;
			}
			gr.SpriteStart = p;
			p += gr.W * gr.H * gr.Layers * gr.PX * gr.PY * gr.PZ * gr.Phases * 4;
			groups.Add(gr);
		}
		if (p != t.End) throw new Exception("entrada mal leida en " + t.Start);
		return attrEnd;
	}

	public static int[] Compose(Dat dat, Spr spr, Group g, int x, int y, int z, int phase, int layer)
	{
		int W = g.W * 32, H = g.H * 32;
		var px = new int[W * H];
		for (int hy = 0; hy < g.H; hy++)
			for (int wx = 0; wx < g.W; wx++)
			{
				int index = ((((((phase * g.PZ + z) * g.PY + y) * g.PX + x) * g.Layers + layer) * g.H + hy) * g.W + wx);
				uint sid = dat.SpriteAt(g.SpriteStart + index * 4);
				if (sid == 0) continue;
				var s = spr.Decode(sid);
				int ox = (g.W - 1 - wx) * 32, oy = (g.H - 1 - hy) * 32;
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

	public static string Run(string datPath, string sprPath, string monsterDir, string luaPath, bool dryRun)
	{
		var log = new StringBuilder();
		if (!dryRun && File.Exists(luaPath)) throw new Exception(luaPath + " ya existe: el contorno ya se aplico (restaura las copias antes de repetir)");
		var dat = Dat.Load(datPath);
		var spr = Spr.Load(sprPath);

		// aspectos de los pokemon
		var looks = new SortedSet<int>();
		var rx = new System.Text.RegularExpressions.Regex("<look\\s+type=\"(\\d+)\"");
		foreach (var f in Directory.GetFiles(monsterDir, "*.xml"))
		{
			var m = rx.Match(File.ReadAllText(f));
			if (m.Success) looks.Add(int.Parse(m.Groups[1].Value));
		}

		var newSprites = new List<byte[]>();
		var known = new Dictionary<string, uint>();
		var entries = new List<byte[]>();
		var map = new List<int[]>();
		var sha = SHA1.Create();
		int nextId = dat.CreatureCount + 1, missing = 0;

		foreach (int look in looks)
		{
			DatThing t;
			if (!dat.Creatures.TryGetValue(look, out t)) { missing++; continue; }
			var groups = new List<Group>();
			int attrEnd = ParseEntry(dat, t, groups);

			// caja comun de la silueta (capa 0, todos los fotogramas), ya en el cuadro ampliado
			int[] box = null;
			foreach (var g in groups)
				for (int ph = 0; ph < g.Phases; ph++)
					for (int z = 0; z < g.PZ; z++)
						for (int y = 0; y < g.PY; y++)
							for (int x = 0; x < g.PX; x++)
							{
								int nW, nH;
								var px = RainbowOutline.Expand(Compose(dat, spr, g, x, y, z, ph, 0), g.W * 32, g.H * 32, out nW, out nH);
								var b = RainbowOutline.SilhouetteBox(px, nW, nH);
								if (b == null) continue;
								if (box == null) box = b;
								else { box[0] = Math.Min(box[0], b[0]); box[1] = Math.Min(box[1], b[1]); box[2] = Math.Max(box[2], b[2]); box[3] = Math.Max(box[3], b[3]); }
							}

			var ms = new MemoryStream();
			ms.Write(dat.Data, t.Start, attrEnd - t.Start);
			if (dat.IdleAnimations) ms.WriteByte((byte)groups.Count);
			foreach (var g in groups)
			{
				int nw = Math.Max(g.W, 2), nh = Math.Max(g.H, 2);
				if (dat.IdleAnimations) ms.WriteByte((byte)g.Type);
				ms.WriteByte((byte)nw); ms.WriteByte((byte)nh);
				ms.WriteByte((byte)Math.Max(g.Exact, 64));
				ms.WriteByte((byte)g.Layers); ms.WriteByte((byte)g.PX); ms.WriteByte((byte)g.PY); ms.WriteByte((byte)g.PZ); ms.WriteByte((byte)g.Phases);
				if (g.Anim != null) ms.Write(g.Anim, 0, g.Anim.Length);
				for (int ph = 0; ph < g.Phases; ph++)
					for (int z = 0; z < g.PZ; z++)
						for (int y = 0; y < g.PY; y++)
							for (int x = 0; x < g.PX; x++)
								for (int l = 0; l < g.Layers; l++)
								{
									int W, H;
									var px = RainbowOutline.Expand(Compose(dat, spr, g, x, y, z, ph, l), g.W * 32, g.H * 32, out W, out H);
									if (l == 0) px = RainbowOutline.Outline(px, W, H, box);
									for (int hy = 0; hy < nh; hy++)
										for (int wx = 0; wx < nw; wx++)
										{
											int ox = (nw - 1 - wx) * 32, oy = (nh - 1 - hy) * 32;
											var rgba = new byte[4096];
											bool any = false;
											for (int py = 0; py < 32; py++)
												for (int pxx = 0; pxx < 32; pxx++)
												{
													int c = px[(oy + py) * W + ox + pxx];
													int a = (c >> 24) & 255;
													if (a == 0) continue;
													any = true;
													int i = (py * 32 + pxx) * 4;
													rgba[i] = (byte)((c >> 16) & 255); rgba[i + 1] = (byte)((c >> 8) & 255);
													rgba[i + 2] = (byte)(c & 255); rgba[i + 3] = (byte)a;
												}
											uint sid = 0;
											if (any)
											{
												var enc = Spr.Encode(rgba);
												string key = Convert.ToBase64String(sha.ComputeHash(enc));
												if (!known.TryGetValue(key, out sid))
												{
													newSprites.Add(enc);
													sid = (uint)(spr.Count + newSprites.Count);
													known[key] = sid;
												}
											}
											ms.Write(BitConverter.GetBytes(sid), 0, 4);
										}
								}
			}
			entries.Add(ms.ToArray());
			map.Add(new[] { look, nextId++ });
		}

		long bytes = 0;
		foreach (var s in newSprites) bytes += s.Length + 4;
		log.AppendLine(string.Format("{0} aspectos ({1} no estan en el dat), criaturas nuevas {2}-{3}, {4} sprites nuevos (+{5} MB)",
			map.Count, missing, dat.CreatureCount + 1, nextId - 1, newSprites.Count, bytes / 1048576));
		if (dryRun) { log.AppendLine("Prueba OK (no se ha modificado nada)."); return log.ToString(); }

		// Tibia.dat: criaturas nuevas justo despues de la ultima criatura
		int creaturesEnd = dat.Creatures[dat.CreatureCount].End;
		var outDat = new MemoryStream();
		outDat.Write(dat.Data, 0, 6);
		outDat.Write(BitConverter.GetBytes((ushort)(dat.CreatureCount + entries.Count)), 0, 2);
		outDat.Write(dat.Data, 8, creaturesEnd - 8);
		foreach (var e in entries) outDat.Write(e, 0, e.Length);
		outDat.Write(dat.Data, creaturesEnd, dat.Data.Length - creaturesEnd);

		string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
		File.Copy(datPath, datPath + ".bak-" + stamp);
		File.Copy(sprPath, sprPath + ".bak-" + stamp);
		File.WriteAllBytes(datPath + ".new", outDat.ToArray());
		spr.Save(sprPath + ".new", newSprites);
		var checkDat = Dat.Load(datPath + ".new");
		if (checkDat.CreatureCount != dat.CreatureCount + entries.Count || checkDat.EffectCount != dat.EffectCount)
			throw new Exception("comprobacion del dat fallida");
		var check = Spr.Load(sprPath + ".new");
		for (int i = 1; i <= newSprites.Count; i++) check.Decode((uint)(spr.Count + i));
		File.Copy(datPath + ".new", datPath, true); File.Delete(datPath + ".new");
		File.Copy(sprPath + ".new", sprPath, true); File.Delete(sprPath + ".new");

		var lua = new StringBuilder();
		lua.AppendLine("-- Generado por tools/pokeassets/RainbowApply.cs: no editar a mano.");
		lua.AppendLine("-- Aspecto normal de cada pokemon -> su copia con contorno arcoiris (Premier Ball).");
		lua.AppendLine("premierLooks = {");
		foreach (var m in map) lua.AppendLine("\t[" + m[0] + "] = " + m[1] + ",");
		lua.AppendLine("}");
		lua.AppendLine();
		lua.AppendLine("premierLooksReverse = {}");
		lua.AppendLine("for normal, premier in pairs(premierLooks) do premierLooksReverse[premier] = normal end");
		File.WriteAllText(luaPath, lua.ToString(), new UTF8Encoding(false));
		log.AppendLine("Guardado. Copias: *.bak-" + stamp);
		return log.ToString();
	}
}
