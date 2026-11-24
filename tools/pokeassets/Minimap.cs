using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.IO.Compression;
using System.Runtime.InteropServices;
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
		var log = Load(otbmPath, otbPath, datPath);
		log.AppendLine("Casillas limpiadas (motas sueltas): " + Denoise());
		WriteOtmm(outPath);
		log.AppendLine("Guardado: " + outPath + " (" + new FileInfo(outPath).Length / 1024 + " KB)");
		return log.ToString();
	}

	// Quita el moteado: una casilla cuyo color casi no tienen sus 8 vecinas (flores, piedras,
	// puntitos) pasa al color que domina alrededor. No toca paredes, escaleras ni caminos (son
	// informacion) ni la transitabilidad: solo el color. Dos pasadas.
	static readonly HashSet<int> keepColors = new HashSet<int>
	{
		MapColors.Map(5 * 36 + 1 * 6 + 0), // paredes
		MapColors.Map(5 * 36 + 5 * 6 + 0), // escaleras / rampas (amarillo)
		MapColors.Map(3 * 36 + 3 * 6 + 3), // caminos
		MapColors.Map(5 * 36 + 2 * 6 + 0),
		MapColors.Map(3 * 36 + 1 * 6 + 0),
	};

	const int WATER = 1 * 36 + 2 * 6 + 3; // (51,102,153)

	static int Denoise()
	{
		int changedTotal = 0;
		var tally = new int[256];
		for (int pass = 0; pass < 2; pass++)
		{
			var changes = new List<KeyValuePair<long, byte>>();
			foreach (var kv in blocks)
			{
				int z = (int)(kv.Key >> 32), bx = (int)((kv.Key >> 16) & 0xFFFF), by = (int)(kv.Key & 0xFFFF);
				var block = kv.Value;
				for (int ly = 0; ly < BLOCK; ly++)
					for (int lx = 0; lx < BLOCK; lx++)
					{
						int idx = (ly * BLOCK + lx) * 3;
						if ((block[idx] & FLAG_SEEN) == 0) continue;
						byte c = block[idx + 1];
						if (c == 255) continue;
						bool keep = keepColors.Contains(c);
						int x = bx * BLOCK + lx, y = by * BLOCK + ly;
						int same = 0, best = -1, bestCount = 0;
						for (int dy = -1; dy <= 1; dy++)
							for (int dx = -1; dx <= 1; dx++)
							{
								if (dx == 0 && dy == 0) continue;
								byte n = ColorAt(x + dx, y + dy, z);
								if (n == 255) continue;
								if (n == c) { same++; continue; }
								int k = ++tally[n];
								if (k > bestCount) { bestCount = k; best = n; }
							}
						for (int dy = -1; dy <= 1; dy++)
							for (int dx = -1; dx <= 1; dx++)
							{
								byte n = ColorAt(x + dx, y + dy, z);
								if (n != 255) tally[n] = 0;
							}
						// normales: motas sueltas al color de alrededor. Paredes/caminos/escaleras solo si
						// estan solas en medio del agua (postes y barreras que en el mapa son puntitos)
						bool flip = keep
							? same == 0 && best == WATER && bestCount >= 6
							: same <= 1 && bestCount >= 5 && !keepColors.Contains(best);
						if (flip)
							changes.Add(new KeyValuePair<long, byte>((long)z * 0x10000000000L + (long)x * 0x100000L + y, (byte)best));
					}
			}
			foreach (var ch in changes)
			{
				int z = (int)(ch.Key / 0x10000000000L), x = (int)(ch.Key / 0x100000L % 0x100000L), y = (int)(ch.Key % 0x100000L);
				long key = (long)z * 0x100000000L + (long)(x / BLOCK) * 0x10000L + (y / BLOCK);
				blocks[key][((y % BLOCK) * BLOCK + (x % BLOCK)) * 3 + 1] = ch.Value;
			}
			changedTotal += changes.Count;
		}
		return changedTotal;
	}

	static StringBuilder Load(string otbmPath, string otbPath, string datPath)
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

		log.AppendLine(string.Format("Casillas: {0}, bloques: {1}, items sin dibujo: {2}", tileCount, blocks.Count, unknownItems));
		log.Append(towns.ToString());
		return log;
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

	// ===== Mapa grande suavizado (bordes redondeados en vez de cuadraditos, mismos colores) =====
	// Uso: [WorldMap]::RunSmooth(otbm, items.otb, Tibia.dat, carpetaSalida)
	// Crea <z>_<x>_<y>.png (CHUNK x CHUNK casillas, OUT_PX pixeles por casilla) e index.txt.
	const int CHUNK = 255;   // impar: el cliente centra la imagen en la casilla del medio
	const int SUPER = 8;     // se dibuja a 8 px por casilla, se redondea y se reduce a la mitad (antialias)
	const int OUT_PX = 4;
	const int RADIUS2 = 18;  // radio del redondeo (en pixeles a 8 px por casilla, al cuadrado)
	const int REACH = 4;     // parte entera del radio (menor que SUPER)

	static int[] offX, offY;
	static readonly int[] counts = new int[256];
	static readonly int[] palette = BuildPalette();

	static int[] BuildPalette()
	{
		var pal = new int[256];
		for (int c = 0; c < 256; c++)
		{
			int r = 0, g = 0, bl = 0;
			if (c > 0 && c < 216) { r = c / 36 % 6 * 51; g = c / 6 % 6 * 51; bl = c % 6 * 51; }
			pal[c] = (r << 16) | (g << 8) | bl;
			if (c == 255) pal[c] = 0x336699; // sin casillas: el mismo azul que el agua (y el fondo del minimapa), sin cortes
		}
		return pal;
	}

	public static string RunSmooth(string otbmPath, string otbPath, string datPath, string outDir)
	{
		var log = Load(otbmPath, otbPath, datPath);
		log.Append(WriteChunks(outDir));
		return log.ToString();
	}

	// lo mismo pero leyendo un .otmm ya generado (world.otmm del cliente): no hace falta el mapa del servidor
	public static string RunSmoothFromOtmm(string otmmPath, string outDir)
	{
		var data = File.ReadAllBytes(otmmPath);
		if (BitConverter.ToUInt32(data, 0) != 0x4D4D544Fu) throw new Exception("no es un archivo OTMM");
		blocks = new Dictionary<long, byte[]>();
		int q = BitConverter.ToUInt16(data, 4);
		while (true)
		{
			int x = BitConverter.ToUInt16(data, q), y = BitConverter.ToUInt16(data, q + 2), z = data[q + 4];
			if (x == 65535 && y == 65535 && z == 255) break;
			int len = BitConverter.ToUInt16(data, q + 5);
			q += 7;
			var raw = new byte[BLOCK * BLOCK * 3];
			using (var ms = new MemoryStream(data, q + 2, len - 6))
			using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
			{
				int read = 0, n;
				while (read < raw.Length && (n = ds.Read(raw, read, raw.Length - read)) > 0) read += n;
			}
			blocks[(long)z * 0x100000000L + (long)(x / BLOCK) * 0x10000L + (y / BLOCK)] = raw;
			q += len;
		}
		return "Bloques leidos: " + blocks.Count + Environment.NewLine + WriteChunks(outDir);
	}

	// cuantas casillas hay de cada color (para elegir la paleta): "indice rgb casillas" de mas a menos
	public static string Histogram(string otmmPath)
	{
		RunSmoothFromOtmmLoadOnly(otmmPath);
		var counts = new long[256];
		foreach (var block in blocks.Values)
			for (int i = 0; i < BLOCK * BLOCK; i++)
				if ((block[i * 3] & FLAG_SEEN) != 0) counts[block[i * 3 + 1]]++;
		var order = new List<int>();
		for (int c = 0; c < 256; c++) if (counts[c] > 0) order.Add(c);
		order.Sort((a, b2) => counts[b2].CompareTo(counts[a]));
		var sb = new StringBuilder();
		foreach (int c in order)
		{
			int rgb = palette[c];
			sb.AppendLine(string.Format("{0,3} ({1,3},{2,3},{3,3}) {4}", c, (rgb >> 16) & 255, (rgb >> 8) & 255, rgb & 255, counts[c]));
		}
		return sb.ToString();
	}

	// Vista previa de la paleta nueva + limpieza, a 1 pixel por casilla (piso z), a partir de un
	// world.otmm ya generado. remapear: aplica MapColors al vuelo (para probar antes de tocar el dat)
	public static string PreviewPalette(string otmmPath, string outPng, int z, bool remapear, int x0, int y0, int w, int h)
	{
		RunSmoothFromOtmmLoadOnly(otmmPath);
		if (remapear)
			foreach (var block in blocks.Values)
				for (int i = 0; i < BLOCK * BLOCK; i++)
					if (block[i * 3 + 1] != 255) block[i * 3 + 1] = (byte)MapColors.Map(block[i * 3 + 1]);
		int cleaned = Denoise();
		using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
		{
			for (int y = 0; y < h; y++)
				for (int x = 0; x < w; x++)
				{
					byte c = ColorAt(x0 + x, y0 + y, z);
					int rgb = c == 255 ? 0x101317 : palette[c];
					bmp.SetPixel(x, y, Color.FromArgb(255, (rgb >> 16) & 255, (rgb >> 8) & 255, rgb & 255));
				}
			bmp.Save(outPng, ImageFormat.Png);
		}
		return "limpiadas: " + cleaned;
	}

	// colores de las casillas aisladas en el agua (las 8 vecinas son agua): "indice casillas"
	public static string IsolatedInWater(string otmmPath)
	{
		RunSmoothFromOtmmLoadOnly(otmmPath);
		var counts = new long[256];
		foreach (var kv in blocks)
		{
			int z = (int)(kv.Key >> 32), bx = (int)((kv.Key >> 16) & 0xFFFF), by = (int)(kv.Key & 0xFFFF);
			for (int ly = 0; ly < BLOCK; ly++)
				for (int lx = 0; lx < BLOCK; lx++)
				{
					byte c = kv.Value[(ly * BLOCK + lx) * 3 + 1];
					if (c == 255 || c == 51) continue;
					int x = bx * BLOCK + lx, y = by * BLOCK + ly, water = 0;
					for (int dy = -1; dy <= 1; dy++)
						for (int dx = -1; dx <= 1; dx++)
							if ((dx != 0 || dy != 0) && ColorAt(x + dx, y + dy, z) == 51) water++;
					if (water >= 6) counts[c]++;
				}
		}
		var sb = new StringBuilder();
		for (int c = 0; c < 256; c++) if (counts[c] > 0) sb.AppendLine(c + " " + counts[c]);
		return sb.ToString();
	}

	static void RunSmoothFromOtmmLoadOnly(string otmmPath)
	{
		var data = File.ReadAllBytes(otmmPath);
		if (BitConverter.ToUInt32(data, 0) != 0x4D4D544Fu) throw new Exception("no es un archivo OTMM");
		blocks = new Dictionary<long, byte[]>();
		int q = BitConverter.ToUInt16(data, 4);
		while (true)
		{
			int x = BitConverter.ToUInt16(data, q), y = BitConverter.ToUInt16(data, q + 2), z = data[q + 4];
			if (x == 65535 && y == 65535 && z == 255) break;
			int len = BitConverter.ToUInt16(data, q + 5);
			q += 7;
			var raw = new byte[BLOCK * BLOCK * 3];
			using (var ms = new MemoryStream(data, q + 2, len - 6))
			using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
			{
				int read = 0, n;
				while (read < raw.Length && (n = ds.Read(raw, read, raw.Length - read)) > 0) read += n;
			}
			blocks[(long)z * 0x100000000L + (long)(x / BLOCK) * 0x10000L + (y / BLOCK)] = raw;
			q += len;
		}
	}

	static string WriteChunks(string outDir)
	{
		var ox = new List<int>();
		var oy = new List<int>();
		for (int dy = -REACH; dy <= REACH; dy++)
			for (int dx = -REACH; dx <= REACH; dx++)
				if (dx * dx + dy * dy <= RADIUS2) { ox.Add(dx); oy.Add(dy); }
		offX = ox.ToArray();
		offY = oy.ToArray();

		Directory.CreateDirectory(outDir);
		foreach (var old in Directory.GetFiles(outDir, "*.png")) File.Delete(old);
		var chunks = new SortedSet<long>();
		foreach (var key in blocks.Keys)
		{
			int z = (int)(key >> 32), bx = (int)((key >> 16) & 0xFFFF), by = (int)(key & 0xFFFF);
			for (int cx = bx * BLOCK / CHUNK; cx <= (bx * BLOCK + BLOCK - 1) / CHUNK; cx++)
				for (int cy = by * BLOCK / CHUNK; cy <= (by * BLOCK + BLOCK - 1) / CHUNK; cy++)
					chunks.Add((long)z * 0x100000000L + (long)cx * 0x10000L + cy);
		}
		var index = new StringBuilder();
		index.AppendLine("size " + CHUNK);
		int written = 0;
		long bytes = 0;
		foreach (var key in chunks)
		{
			int z = (int)(key >> 32), cx = (int)((key >> 16) & 0xFFFF), cy = (int)(key & 0xFFFF);
			int x0 = cx * CHUNK, y0 = cy * CHUNK;
			string file = Path.Combine(outDir, z + "_" + x0 + "_" + y0 + ".png");
			if (!RenderChunk(z, x0, y0, file)) continue;
			index.AppendLine(z + " " + x0 + " " + y0);
			bytes += new FileInfo(file).Length;
			written++;
		}
		File.WriteAllText(Path.Combine(outDir, "index.txt"), index.ToString());
		return string.Format("Mapa suavizado: {0} imagenes ({1} MB) en {2}", written, bytes / (1024 * 1024), outDir);
	}

	static byte ColorAt(int x, int y, int z)
	{
		if (x < 0 || y < 0) return 255;
		byte[] block;
		long key = (long)z * 0x100000000L + (long)(x / BLOCK) * 0x10000L + (y / BLOCK);
		if (!blocks.TryGetValue(key, out block)) return 255;
		int idx = ((y % BLOCK) * BLOCK + (x % BLOCK)) * 3;
		if ((block[idx] & FLAG_SEEN) == 0) return 255;
		return block[idx + 1];
	}

	static bool RenderChunk(int z, int x0, int y0, string path)
	{
		const int pad = 2;
		int tiles = CHUNK + pad * 2;
		var colors = new byte[tiles * tiles];
		bool any = false;
		for (int ty = 0; ty < tiles; ty++)
		{
			for (int tx = 0; tx < tiles; tx++)
			{
				byte c = ColorAt(x0 - pad + tx, y0 - pad + ty, z);
				colors[ty * tiles + tx] = c;
				if (c != 255 && tx >= pad && ty >= pad && tx < tiles - pad && ty < tiles - pad) any = true;
			}
		}
		if (!any) return false;

		// Scale2x tres veces (x8): convierte escalones en diagonales sin borrar arboles ni caminos finos
		byte[] fine = colors;
		int w = tiles;
		for (int pass = 0; pass < 3; pass++) { fine = Scale2x(fine, w); w *= 2; }

		int size = CHUNK * OUT_PX, ratio = SUPER / OUT_PX, area = ratio * ratio;
		var argb = new int[size * size];
		for (int y = 0; y < size; y++)
		{
			for (int x = 0; x < size; x++)
			{
				int r = 0, g = 0, bl = 0;
				for (int sy = 0; sy < ratio; sy++)
				{
					for (int sx = 0; sx < ratio; sx++)
					{
						int rgb = palette[Mode(colors, tiles, fine, w, pad * SUPER + x * ratio + sx, pad * SUPER + y * ratio + sy)];
						r += (rgb >> 16) & 255; g += (rgb >> 8) & 255; bl += rgb & 255;
					}
				}
				argb[y * size + x] = unchecked((int)0xFF000000) | ((r / area) << 16) | ((g / area) << 8) | (bl / area);
			}
		}
		using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
		{
			var data = bmp.LockBits(new Rectangle(0, 0, size, size), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
			for (int y = 0; y < size; y++) Marshal.Copy(argb, y * size, data.Scan0 + y * data.Stride, size);
			bmp.UnlockBits(data);
			bmp.Save(path, ImageFormat.Png);
		}
		return true;
	}

	static byte[] Scale2x(byte[] src, int w)
	{
		int w2 = w * 2;
		var dst = new byte[w2 * w2];
		for (int y = 0; y < w; y++)
		{
			for (int x = 0; x < w; x++)
			{
				byte p = src[y * w + x];
				byte a = y > 0 ? src[(y - 1) * w + x] : p;
				byte d = y < w - 1 ? src[(y + 1) * w + x] : p;
				byte c = x > 0 ? src[y * w + x - 1] : p;
				byte b = x < w - 1 ? src[y * w + x + 1] : p;
				int o = (y * 2) * w2 + x * 2;
				dst[o] = (c == a && c != d && a != b) ? a : p;
				dst[o + 1] = (a == b && a != c && b != d) ? b : p;
				dst[o + w2] = (d == c && d != b && c != a) ? c : p;
				dst[o + w2 + 1] = (b == d && b != a && d != c) ? d : p;
			}
		}
		return dst;
	}

	// color que mas se repite en un circulo alrededor del pixel (sobre la imagen x8): redondea esquinas
	static byte Mode(byte[] colors, int tiles, byte[] fine, int w, int sx, int sy)
	{
		int tx = sx / SUPER, ty = sy / SUPER;
		byte center = colors[ty * tiles + tx];
		bool uniform = true;
		for (int dy = -1; dy <= 1 && uniform; dy++)
			for (int dx = -1; dx <= 1; dx++)
				if (colors[(ty + dy) * tiles + tx + dx] != center) { uniform = false; break; }
		if (uniform) return center;
		center = fine[sy * w + sx];
		byte best = center;
		int bestCount = 0;
		for (int i = 0; i < offX.Length; i++)
		{
			byte c = fine[(sy + offY[i]) * w + sx + offX[i]];
			int n = ++counts[c];
			if (n > bestCount || (n == bestCount && c == center)) { best = c; bestCount = n; }
		}
		for (int i = 0; i < offX.Length; i++)
			counts[fine[(sy + offY[i]) * w + sx + offX[i]]] = 0;
		return best;
	}
}
