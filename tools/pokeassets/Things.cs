using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

// Herramienta para los objetos de evolucion shiny:
// clona en Tibia.dat/Tibia.spr (cliente 10.98, sprites u32 + canal alfa) los dibujos de los items base
// con un toque brillante (tinte dorado, contorno y destellos) y apunta los items del items.otb a ellos.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs -ReferencedAssemblies System.Drawing
//                   [PokeAssets]::Run(dat, spr, otb, 46001, 46999, preview.png, $true)  # $true = solo comprobar

public class DatThing
{
	public int Start, End;
	public List<int> SpritePositions = new List<int>();
}

public class Dat
{
	public byte[] Data;
	public int ItemCount, CreatureCount, EffectCount, MissileCount;
	public Dictionary<int, DatThing> Items = new Dictionary<int, DatThing>();
	public int ItemsEnd;
	public bool IdleAnimations;

	int U16(int p) { return Data[p] | (Data[p + 1] << 8); }

	public static Dat Load(string path)
	{
		var data = File.ReadAllBytes(path);
		Exception last = null;
		foreach (var idle in new[] { true, false })
		{
			try { return Parse(data, idle); }
			catch (Exception e) { last = e; }
		}
		throw new Exception("No se pudo leer Tibia.dat: " + last.Message);
	}

	static Dat Parse(byte[] data, bool idle)
	{
		var d = new Dat { Data = data, IdleAnimations = idle };
		d.ItemCount = d.U16(4);
		d.CreatureCount = d.U16(6);
		d.EffectCount = d.U16(8);
		d.MissileCount = d.U16(10);
		int p = 12;
		try
		{
			for (int id = 100; id <= d.ItemCount; id++) d.Items[id] = d.ParseThing(ref p, false);
		}
		catch (Exception e) { throw new Exception("item " + (d.Items.Count + 100) + ": " + e.Message); }
		d.ItemsEnd = p;
		for (int id = 1; id <= d.CreatureCount; id++) d.ParseThing(ref p, true);
		for (int id = 1; id <= d.EffectCount; id++) d.ParseThing(ref p, false);
		for (int id = 1; id <= d.MissileCount; id++) d.ParseThing(ref p, false);
		if (p != data.Length) throw new Exception("tamano inesperado (" + p + " de " + data.Length + ")");
		return d;
	}

	DatThing ParseThing(ref int p, bool creature)
	{
		var t = new DatThing { Start = p };
		while (true)
		{
			byte a = Data[p++];
			if (a == 0xFF) break;
			switch (a)
			{
				case 0: case 8: case 9: case 26: case 29: case 30: case 33: case 35: p += 2; break; // u16
				case 22: case 25: p += 4; break; // luz, desplazamiento
				case 34: p += 6; p += 2 + U16(p); p += 4; break; // mercado
				case 0xFE: break; // "usable" de Object Builder, sin datos
				default: if (a >= 0x40) throw new Exception("atributo desconocido " + a + " en " + (p - 1)); break;
			}
			if (p >= Data.Length) throw new Exception("fin de archivo en atributos");
		}
		int groups = 1;
		bool hasGroups = creature && IdleAnimations;
		if (hasGroups) { groups = Data[p++]; if (groups < 1 || groups > 4) throw new Exception("grupos invalidos en " + p); }
		for (int g = 0; g < groups; g++)
		{
			if (hasGroups) p++;
			int w = Data[p++], h = Data[p++];
			if (w == 0 || h == 0) throw new Exception("tamano invalido " + w + "x" + h + " en " + p);
			if (w > 1 || h > 1) p++;
			int layers = Data[p++], px = Data[p++], py = Data[p++], pz = Data[p++], phases = Data[p++];
			if (layers == 0 || px == 0 || py == 0 || pz == 0 || phases == 0) throw new Exception("patrones invalidos " + layers + "/" + px + "/" + py + "/" + pz + "/" + phases + " en " + p);
			if (phases > 1) p += 6 + phases * 8;
			long total = (long)w * h * layers * px * py * pz * phases;
			if (p + total * 4 > Data.Length) throw new Exception("demasiados sprites (" + total + ") en " + p);
			for (int i = 0; i < total; i++) { t.SpritePositions.Add(p); p += 4; }
			if (p > Data.Length) throw new Exception("fin de archivo en sprites");
		}
		t.End = p;
		return t;
	}

	public uint SpriteAt(int pos) { return BitConverter.ToUInt32(Data, pos); }

	// Copia la entrada de un item cambiando sus sprites
	public byte[] CloneItem(int clientId, Func<uint, uint> mapSprite)
	{
		var t = Items[clientId];
		var b = new byte[t.End - t.Start];
		Array.Copy(Data, t.Start, b, 0, b.Length);
		foreach (var pos in t.SpritePositions)
		{
			uint n = mapSprite(SpriteAt(pos));
			Array.Copy(BitConverter.GetBytes(n), 0, b, pos - t.Start, 4);
		}
		return b;
	}

	public void Save(string path, List<byte[]> newItems)
	{
		using (var fs = new FileStream(path, FileMode.Create))
		{
			fs.Write(Data, 0, 4);
			fs.Write(BitConverter.GetBytes((ushort)(ItemCount + newItems.Count)), 0, 2);
			fs.Write(Data, 6, ItemsEnd - 6);
			foreach (var b in newItems) fs.Write(b, 0, b.Length);
			fs.Write(Data, ItemsEnd, Data.Length - ItemsEnd);
		}
	}
}

public class Spr
{
	public byte[] Data;
	public int Count;

	public static Spr Load(string path)
	{
		var s = new Spr { Data = File.ReadAllBytes(path) };
		s.Count = (int)BitConverter.ToUInt32(s.Data, 4);
		if (8 + (long)s.Count * 4 > s.Data.Length) throw new Exception("Tibia.spr: cabecera invalida");
		return s;
	}

	int Offset(uint id)
	{
		if (id < 1 || id > Count) return 0;
		return (int)BitConverter.ToUInt32(Data, 8 + ((int)id - 1) * 4);
	}

	public byte[] Decode(uint id)
	{
		var px = new byte[32 * 32 * 4];
		int off = Offset(id);
		if (off == 0) return px;
		int p = off + 3;
		int size = Data[p] | (Data[p + 1] << 8);
		p += 2;
		int end = p + size, w = 0;
		while (p < end && w < 1024)
		{
			int tr = Data[p] | (Data[p + 1] << 8);
			int co = Data[p + 2] | (Data[p + 3] << 8);
			p += 4;
			w += tr;
			if (w + co > 1024) throw new Exception("sprite " + id + " corrupto (o sin canal alfa)");
			for (int i = 0; i < co; i++, w++)
			{
				px[w * 4] = Data[p]; px[w * 4 + 1] = Data[p + 1]; px[w * 4 + 2] = Data[p + 2]; px[w * 4 + 3] = Data[p + 3];
				p += 4;
			}
		}
		if (p != end) throw new Exception("sprite " + id + " con tamano inesperado (o sin canal alfa)");
		return px;
	}

	public static byte[] Encode(byte[] px)
	{
		var body = new MemoryStream();
		int pos = 0;
		while (pos < 1024)
		{
			int tr = 0;
			while (pos < 1024 && px[pos * 4 + 3] == 0) { tr++; pos++; }
			if (pos >= 1024) break;
			int start = pos;
			while (pos < 1024 && px[pos * 4 + 3] != 0) pos++;
			int co = pos - start;
			body.Write(BitConverter.GetBytes((ushort)tr), 0, 2);
			body.Write(BitConverter.GetBytes((ushort)co), 0, 2);
			body.Write(px, start * 4, co * 4);
		}
		var b = body.ToArray();
		var res = new byte[5 + b.Length];
		res[0] = 0xFF; res[1] = 0x00; res[2] = 0xFF;
		res[3] = (byte)(b.Length & 0xFF); res[4] = (byte)(b.Length >> 8);
		Array.Copy(b, 0, res, 5, b.Length);
		return res;
	}

	public void Save(string path, List<byte[]> newSprites)
	{
		int n = newSprites.Count;
		int oldStart = 8 + Count * 4;
		long delta = n * 4L;
		using (var fs = new FileStream(path, FileMode.Create))
		using (var bw = new BinaryWriter(fs))
		{
			bw.Write(BitConverter.ToUInt32(Data, 0));
			bw.Write((uint)(Count + n));
			for (int i = 0; i < Count; i++)
			{
				uint o = BitConverter.ToUInt32(Data, 8 + i * 4);
				bw.Write(o == 0 ? 0u : (uint)(o + delta));
			}
			long pos = 8 + (long)(Count + n) * 4 + (Data.Length - oldStart);
			foreach (var s in newSprites) { bw.Write((uint)pos); pos += s.Length; }
			bw.Write(Data, oldStart, Data.Length - oldStart);
			foreach (var s in newSprites) bw.Write(s);
		}
	}
}

public static class Glow
{
	static byte Clamp(double v) { return (byte)Math.Max(0, Math.Min(255, Math.Round(v))); }

	static void Put(byte[] px, int x, int y, int r, int g, int b, int a)
	{
		if (x < 0 || y < 0 || x > 31 || y > 31) return;
		int i = (y * 32 + x) * 4;
		px[i] = (byte)r; px[i + 1] = (byte)g; px[i + 2] = (byte)b; px[i + 3] = (byte)Math.Max(a, (int)px[i + 3]);
	}

	static void Star(byte[] px, int cx, int cy, int arm)
	{
		for (int k = arm; k >= 1; k--)
		{
			int a = k == 1 ? 235 : 150;
			int g = k == 1 ? 250 : 235;
			int b = k == 1 ? 190 : 140;
			Put(px, cx + k, cy, 255, g, b, a); Put(px, cx - k, cy, 255, g, b, a);
			Put(px, cx, cy + k, 255, g, b, a); Put(px, cx, cy - k, 255, g, b, a);
		}
		Put(px, cx, cy, 255, 255, 255, 255);
	}

	public static byte[] Apply(byte[] src)
	{
		var px = (byte[])src.Clone();
		int minX = 32, minY = 32, maxX = -1, maxY = -1;
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
				if (src[(y * 32 + x) * 4 + 3] >= 100)
				{
					if (x < minX) minX = x; if (x > maxX) maxX = x;
					if (y < minY) minY = y; if (y > maxY) maxY = y;
				}
		if (maxX < 0) return px; // sprite vacio

		// tinte dorado y algo mas de brillo
		for (int i = 0; i < 1024; i++)
		{
			if (src[i * 4 + 3] == 0) continue;
			px[i * 4] = Clamp((src[i * 4] * 0.72 + 255 * 0.28) * 1.06);
			px[i * 4 + 1] = Clamp((src[i * 4 + 1] * 0.72 + 215 * 0.28) * 1.06);
			px[i * 4 + 2] = Clamp((src[i * 4 + 2] * 0.72 + 70 * 0.28) * 1.06);
		}

		// contorno dorado (2 anillos con transparencia)
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				int i = (y * 32 + x) * 4;
				if (src[i + 3] != 0) continue;
				int dist = 3;
				for (int dy = -2; dy <= 2; dy++)
					for (int dx = -2; dx <= 2; dx++)
					{
						int nx = x + dx, ny = y + dy;
						if (nx < 0 || ny < 0 || nx > 31 || ny > 31) continue;
						if (src[(ny * 32 + nx) * 4 + 3] < 100) continue;
						int d = Math.Max(Math.Abs(dx), Math.Abs(dy));
						if (d < dist) dist = d;
					}
				if (dist == 1) { px[i] = 255; px[i + 1] = 205; px[i + 2] = 50; px[i + 3] = 215; }
				else if (dist == 2) { px[i] = 255; px[i + 1] = 225; px[i + 2] = 110; px[i + 3] = 85; }
			}

		// destellos
		Star(px, Math.Min(29, Math.Max(2, maxX)), Math.Min(29, Math.Max(2, minY)), 2);
		Star(px, Math.Min(30, Math.Max(1, minX)), Math.Min(30, Math.Max(1, maxY)), 1);
		return px;
	}
}

public static class PokeAssets
{
	public static string Run(string datPath, string sprPath, string otbPath, int fromId, int toId, string previewPath, bool dryRun)
	{
		var log = new StringBuilder();
		var dat = Dat.Load(datPath);
		log.AppendLine(string.Format("Tibia.dat OK: {0} items (animaciones idle: {1})", dat.ItemCount, dat.IdleAnimations));
		var spr = Spr.Load(sprPath);
		log.AppendLine(string.Format("Tibia.spr: {0} sprites", spr.Count));
		var otb = Otb.Load(otbPath);

		var outside = new HashSet<int>();
		foreach (var it in otb.Items)
			if (it.ServerId < fromId || it.ServerId > toId) outside.Add(it.ClientId);

		var todo = new List<OtbItem>();
		foreach (var it in otb.Items)
			if (it.ServerId >= fromId && it.ServerId <= toId && outside.Contains(it.ClientId)) todo.Add(it);
		todo.Sort((a, b) => a.ServerId.CompareTo(b.ServerId));
		log.AppendLine(string.Format("Objetos a los que dar dibujo propio: {0}", todo.Count));
		if (todo.Count == 0) return log.ToString();

		var spriteMap = new Dictionary<uint, uint>();
		var newSprites = new List<byte[]>();
		var newItems = new List<byte[]>();
		var preview = new List<KeyValuePair<byte[], byte[]>>();
		Func<uint, uint> map = delegate (uint id)
		{
			if (id == 0) return 0;
			uint n;
			if (spriteMap.TryGetValue(id, out n)) return n;
			var src = spr.Decode(id);
			var glow = Glow.Apply(src);
			newSprites.Add(Spr.Encode(glow));
			n = (uint)(spr.Count + newSprites.Count);
			spriteMap[id] = n;
			if (preview.Count < 48) preview.Add(new KeyValuePair<byte[], byte[]>(src, glow));
			return n;
		};

		int nextClient = dat.ItemCount + 1;
		foreach (var it in todo)
		{
			if (!dat.Items.ContainsKey(it.ClientId)) throw new Exception("El item " + it.ServerId + " apunta al dibujo " + it.ClientId + ", que no existe en Tibia.dat");
			newItems.Add(dat.CloneItem(it.ClientId, map));
			it.ClientId = nextClient++;
		}

		// comprobacion: los sprites nuevos se leen igual que se escribieron
		foreach (var s in newSprites)
		{
			var tmp = new Spr { Data = new byte[8 + 4 + s.Length], Count = 1 };
			Array.Copy(BitConverter.GetBytes(12u), 0, tmp.Data, 8, 4);
			Array.Copy(s, 0, tmp.Data, 12, s.Length);
			tmp.Decode(1);
		}
		log.AppendLine(string.Format("Dibujos nuevos: {0} items (ids {1}-{2}), {3} sprites", newItems.Count, dat.ItemCount + 1, nextClient - 1, newSprites.Count));

		if (previewPath != null) SavePreview(preview, previewPath);

		if (dryRun)
		{
			log.AppendLine("Prueba OK (no se ha modificado nada).");
			return log.ToString();
		}

		foreach (var f in new[] { datPath, sprPath, otbPath })
			if (!File.Exists(f + ".bak")) File.Copy(f, f + ".bak");

		dat.Save(datPath + ".new", newItems);
		spr.Save(sprPath + ".new", newSprites);
		Dat.Load(datPath + ".new"); // vuelve a leer el dat completo para validar
		otb.Save(otbPath + ".new");
		Otb.Load(otbPath + ".new");

		File.Copy(datPath + ".new", datPath, true); File.Delete(datPath + ".new");
		File.Copy(sprPath + ".new", sprPath, true); File.Delete(sprPath + ".new");
		File.Copy(otbPath + ".new", otbPath, true); File.Delete(otbPath + ".new");
		log.AppendLine("Guardado. Copias de seguridad: *.bak");
		return log.ToString();
	}

	static void SavePreview(List<KeyValuePair<byte[], byte[]>> list, string path)
	{
		const int scale = 2, cell = 32 * scale, cols = 8;
		int rows = (list.Count + cols - 1) / cols;
		using (var bmp = new Bitmap(cols * (cell * 2 + 8), Math.Max(1, rows) * (cell + 8), PixelFormat.Format32bppArgb))
		{
			using (var g = Graphics.FromImage(bmp)) g.Clear(Color.FromArgb(255, 40, 44, 52));
			for (int k = 0; k < list.Count; k++)
			{
				int ox = (k % cols) * (cell * 2 + 8) + 4, oy = (k / cols) * (cell + 8) + 4;
				Draw(bmp, list[k].Key, ox, oy, scale);
				Draw(bmp, list[k].Value, ox + cell, oy, scale);
			}
			bmp.Save(path, ImageFormat.Png);
		}
	}

	static void Draw(Bitmap bmp, byte[] px, int ox, int oy, int scale)
	{
		for (int y = 0; y < 32; y++)
			for (int x = 0; x < 32; x++)
			{
				int i = (y * 32 + x) * 4;
				int a = px[i + 3];
				if (a == 0) continue;
				for (int sy = 0; sy < scale; sy++)
					for (int sx = 0; sx < scale; sx++)
					{
						var bg = bmp.GetPixel(ox + x * scale + sx, oy + y * scale + sy);
						int r = (px[i] * a + bg.R * (255 - a)) / 255;
						int gg = (px[i + 1] * a + bg.G * (255 - a)) / 255;
						int b = (px[i + 2] * a + bg.B * (255 - a)) / 255;
						bmp.SetPixel(ox + x * scale + sx, oy + y * scale + sy, Color.FromArgb(255, r, gg, b));
					}
			}
	}
}
