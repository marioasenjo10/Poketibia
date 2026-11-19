using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;

// Genera el minimapa del mundo entero (formato .otmm de OTClient) a partir del mapa del servidor (.otbm),
// para que el mapa grande del cliente (Ctrl+Tab) muestre todas las ciudades aunque no las hayas visitado.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,Minimap.cs -ReferencedAssemblies System.Drawing
//                   [WorldMap]::Run(otbm, items.otb, Tibia.dat, salida.otmm)

public static class WorldMap
{
	const byte NODE_START = 0xFE, NODE_END = 0xFF, ESCAPE = 0xFD;
	const int BLOCK = 64;
	const byte FLAG_SEEN = 1, FLAG_NOT_PATHABLE = 2, FLAG_NOT_WALKABLE = 4;

	static byte[] b;
	static int p;
	static byte[] buf = new byte[1 << 16];
	static int bufLen;

	static Dictionary<int, int> serverToClient;
	static Dat dat;
	static Dictionary<long, byte[]> blocks;
	static int tileCount, unknownItems;
	static StringBuilder towns;

	// lee los datos de un nodo (sin escapes) hasta el siguiente inicio/fin de nodo
	static void ReadData()
	{
		bufLen = 0;
		while (true)
		{
			byte c = b[p];
			if (c == NODE_START || c == NODE_END) return;
			if (c == ESCAPE) { p++; c = b[p]; }
			if (bufLen == buf.Length) Array.Resize(ref buf, buf.Length * 2);
			buf[bufLen++] = c;
			p++;
		}
	}

	// p justo despues de NODE_START
	static void SkipNode()
	{
		while (true)
		{
			byte c = b[p++];
			if (c == ESCAPE) { p++; continue; }
			if (c == NODE_START) { SkipNode(); continue; }
			if (c == NODE_END) return;
		}
	}

	static int U16(int i) { return buf[i] | (buf[i + 1] << 8); }

	public static string Run(string otbmPath, string otbPath, string datPath, string outPath)
	{
		var log = new StringBuilder();
		dat = Dat.Load(datPath);
		log.AppendLine(string.Format("Tibia.dat OK: {0} items", dat.ItemCount));
		var otb = Otb.Load(otbPath);
		serverToClient = new Dictionary<int, int>();
		foreach (var it in otb.Items)
			if (it.ServerId > 0 && it.ClientId > 0) serverToClient[it.ServerId] = it.ClientId;
		log.AppendLine(string.Format("items.otb OK: {0} items", serverToClient.Count));

		b = File.ReadAllBytes(otbmPath);
		blocks = new Dictionary<long, byte[]>();
		tileCount = 0; unknownItems = 0;
		towns = new StringBuilder();

		p = 4; // identificador
		if (b[p++] != NODE_START) throw new Exception("OTBM: falta el nodo raiz");
		ReadData();
		log.AppendLine(string.Format("Mapa: version {0}, {1}x{2}", BitConverter.ToUInt32(buf, 1), U16(5), U16(7)));
		while (b[p] == NODE_START)
		{
			p++;
			ReadData();
			if (buf[0] == 2) ReadMapData(); else SkipChildren();
		}
		if (b[p++] != NODE_END) throw new Exception("OTBM: fin de nodo raiz esperado en " + (p - 1));

		WriteOtmm(outPath);
		log.AppendLine(string.Format("Casillas: {0}, bloques: {1}, items sin dibujo: {2}", tileCount, blocks.Count, unknownItems));
		log.Append(towns.ToString());
		log.AppendLine("Guardado: " + outPath + " (" + new FileInfo(outPath).Length / 1024 + " KB)");
		return log.ToString();
	}

	// salta los hijos del nodo actual y su NODE_END
	static void SkipChildren()
	{
		while (b[p] == NODE_START) { p++; SkipNode(); }
		if (b[p++] != NODE_END) throw new Exception("OTBM: fin de nodo esperado en " + (p - 1));
	}

	static void ReadMapData()
	{
		while (b[p] == NODE_START)
		{
			p++;
			ReadData();
			byte type = buf[0];
			if (type == 4) ReadTileArea(U16(1), U16(3), buf[5]);
			else if (type == 12) ReadTowns();
			else SkipChildren();
		}
		if (b[p++] != NODE_END) throw new Exception("OTBM: fin de MAP_DATA esperado en " + (p - 1));
	}

	static void ReadTowns()
	{
		while (b[p] == NODE_START)
		{
			p++;
			ReadData();
			if (buf[0] == 13)
			{
				int len = U16(5);
				string name = Encoding.GetEncoding(28591).GetString(buf, 7, len);
				int q = 7 + len;
				towns.AppendLine(string.Format("  Ciudad {0}: {1} ({2}, {3}, {4})", BitConverter.ToUInt32(buf, 1), name, U16(q), U16(q + 2), buf[q + 4]));
			}
			SkipChildren();
		}
		if (b[p++] != NODE_END) throw new Exception("OTBM: fin de TOWNS esperado en " + (p - 1));
	}

	static void ReadTileArea(int baseX, int baseY, int z)
	{
		var items = new List<DatThing>();
		while (b[p] == NODE_START)
		{
			p++;
			ReadData();
			byte type = buf[0];
			if (type != 5 && type != 14) { SkipChildren(); continue; }
			int x = baseX + buf[1], y = baseY + buf[2];
			int q = type == 14 ? 7 : 3;
			items.Clear();
			while (q < bufLen)
			{
				byte attr = buf[q++];
				if (attr == 3) q += 4; // flags de la casilla
				else if (attr == 9) { AddItem(items, U16(q)); q += 2; }
				else break;
			}
			// items de la casilla (nodos hijos)
			while (b[p] == NODE_START)
			{
				p++;
				ReadData();
				if (buf[0] == 6 && bufLen >= 3) AddItem(items, U16(1));
				SkipChildren();
			}
			if (b[p++] != NODE_END) throw new Exception("OTBM: fin de casilla esperado en " + (p - 1));
			SetTile(x, y, z, items);
		}
		if (b[p++] != NODE_END) throw new Exception("OTBM: fin de TILE_AREA esperado en " + (p - 1));
	}

	static void AddItem(List<DatThing> items, int serverId)
	{
		int clientId;
		DatThing t;
		if (serverToClient.TryGetValue(serverId, out clientId) && dat.Items.TryGetValue(clientId, out t)) items.Add(t);
		else unknownItems++;
	}

	// mismo calculo que OTClient (Tile::getMinimapColorByte, isWalkable, isPathable, getGroundSpeed)
	static void SetTile(int x, int y, int z, List<DatThing> items)
	{
		byte color = 255;
		bool hasGround = false, notWalkable = false, notPathable = false;
		int speed = 100;
		for (int pr = 0; pr <= 3; pr++)
			foreach (var t in items)
				if (t.Priority == pr && t.MinimapColor != 0) color = (byte)t.MinimapColor;
		foreach (var t in items)
		{
			if (t.Priority == 0 && !hasGround) { hasGround = true; speed = t.GroundSpeed; }
			if (t.NotWalkable) notWalkable = true;
			if (t.NotPathable) notPathable = true;
		}
		byte flags = FLAG_SEEN;
		if (!hasGround || notWalkable) flags |= FLAG_NOT_WALKABLE;
		if (notPathable) flags |= FLAG_NOT_PATHABLE;

		long key = (long)z * 0x100000000L + (long)(x / BLOCK) * 0x10000L + (y / BLOCK);
		byte[] block;
		if (!blocks.TryGetValue(key, out block))
		{
			block = new byte[BLOCK * BLOCK * 3];
			for (int i = 0; i < BLOCK * BLOCK; i++) { block[i * 3 + 1] = 255; block[i * 3 + 2] = 10; }
			blocks[key] = block;
		}
		int idx = ((y % BLOCK) * BLOCK + (x % BLOCK)) * 3;
		block[idx] = flags;
		block[idx + 1] = color;
		block[idx + 2] = (byte)Math.Min(255, (int)Math.Ceiling(speed / 10.0));
		tileCount++;
	}

	static void WriteOtmm(string path)
	{
		using (var fs = new FileStream(path, FileMode.Create))
		using (var w = new BinaryWriter(fs))
		{
			var title = Encoding.ASCII.GetBytes("OTMM 1.0");
			w.Write(0x4D4D544Fu);
			w.Write((ushort)(4 + 2 + 2 + 4 + 2 + title.Length)); // inicio de los datos
			w.Write((ushort)1); // version
			w.Write(0u); // flags
			w.Write((ushort)title.Length);
			w.Write(title);
			var keys = new List<long>(blocks.Keys);
			keys.Sort();
			foreach (var key in keys)
			{
				int z = (int)(key >> 32), bx = (int)((key >> 16) & 0xFFFF), by = (int)(key & 0xFFFF);
				var data = Zlib(blocks[key]);
				if (data.Length > 65535) throw new Exception("bloque comprimido demasiado grande");
				w.Write((ushort)(bx * BLOCK));
				w.Write((ushort)(by * BLOCK));
				w.Write((byte)z);
				w.Write((ushort)data.Length);
				w.Write(data);
			}
			w.Write((ushort)65535);
			w.Write((ushort)65535);
			w.Write((byte)255);
		}
	}

	// formato zlib (lo que espera uncompress de OTClient): cabecera + deflate + adler32
	static byte[] Zlib(byte[] raw)
	{
		var ms = new MemoryStream();
		ms.WriteByte(0x78); ms.WriteByte(0x9C);
		using (var ds = new DeflateStream(ms, CompressionMode.Compress, true)) ds.Write(raw, 0, raw.Length);
		uint a = 1, s = 0;
		foreach (var c in raw) { a = (a + c) % 65521; s = (s + a) % 65521; }
		uint adler = (s << 16) | a;
		ms.WriteByte((byte)(adler >> 24)); ms.WriteByte((byte)(adler >> 16)); ms.WriteByte((byte)(adler >> 8)); ms.WriteByte((byte)adler);
		return ms.ToArray();
	}
}
