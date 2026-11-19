using System;
using System.Collections.Generic;
using System.IO;

// Lectura/escritura de items.otb (TFS). Solo soporta el formato plano: nodo raiz + nodos item sin hijos.
public class OtbItem
{
	public byte Group;
	public uint Flags;
	public List<KeyValuePair<byte, byte[]>> Attrs = new List<KeyValuePair<byte, byte[]>>();

	public const byte ATTR_SERVERID = 0x10;
	public const byte ATTR_CLIENTID = 0x11;

	byte[] Get(byte attr)
	{
		foreach (var a in Attrs) if (a.Key == attr) return a.Value;
		return null;
	}

	void Set(byte attr, byte[] value)
	{
		for (int i = 0; i < Attrs.Count; i++)
			if (Attrs[i].Key == attr) { Attrs[i] = new KeyValuePair<byte, byte[]>(attr, value); return; }
		Attrs.Add(new KeyValuePair<byte, byte[]>(attr, value));
	}

	public int ServerId
	{
		get { var v = Get(ATTR_SERVERID); return v == null ? -1 : BitConverter.ToUInt16(v, 0); }
		set { Set(ATTR_SERVERID, BitConverter.GetBytes((ushort)value)); }
	}

	public int ClientId
	{
		get { var v = Get(ATTR_CLIENTID); return v == null ? -1 : BitConverter.ToUInt16(v, 0); }
		set { Set(ATTR_CLIENTID, BitConverter.GetBytes((ushort)value)); }
	}

	public OtbItem Clone()
	{
		var c = new OtbItem { Group = Group, Flags = Flags };
		foreach (var a in Attrs) c.Attrs.Add(new KeyValuePair<byte, byte[]>(a.Key, (byte[])a.Value.Clone()));
		return c;
	}

	public byte[] Serialize()
	{
		var ms = new MemoryStream();
		ms.WriteByte(Group);
		ms.Write(BitConverter.GetBytes(Flags), 0, 4);
		foreach (var a in Attrs)
		{
			ms.WriteByte(a.Key);
			ms.Write(BitConverter.GetBytes((ushort)a.Value.Length), 0, 2);
			ms.Write(a.Value, 0, a.Value.Length);
		}
		return ms.ToArray();
	}

	public static OtbItem Parse(byte[] d)
	{
		var it = new OtbItem();
		it.Group = d[0];
		it.Flags = BitConverter.ToUInt32(d, 1);
		int p = 5;
		while (p < d.Length)
		{
			byte attr = d[p];
			int len = BitConverter.ToUInt16(d, p + 1);
			var v = new byte[len];
			Array.Copy(d, p + 3, v, 0, len);
			it.Attrs.Add(new KeyValuePair<byte, byte[]>(attr, v));
			p += 3 + len;
		}
		return it;
	}
}

public class Otb
{
	const byte NODE_START = 0xFE, NODE_END = 0xFF, ESCAPE = 0xFD;

	public byte[] Identifier = new byte[4];
	public byte[] RootData; // contenido (sin escapar) del nodo raiz: tipo + flags + atributos de version
	public List<OtbItem> Items = new List<OtbItem>();

	public static Otb Load(string path)
	{
		var b = File.ReadAllBytes(path);
		var otb = new Otb();
		Array.Copy(b, 0, otb.Identifier, 0, 4);
		int p = 4;
		if (b[p++] != NODE_START) throw new Exception("OTB: falta el nodo raiz");
		otb.RootData = ReadData(b, ref p);
		while (b[p] == NODE_START)
		{
			p++;
			var data = ReadData(b, ref p);
			if (b[p] == NODE_START) throw new Exception("OTB: nodo item con hijos (no soportado)");
			if (b[p++] != NODE_END) throw new Exception("OTB: fin de nodo item esperado");
			otb.Items.Add(OtbItem.Parse(data));
		}
		if (b[p++] != NODE_END) throw new Exception("OTB: fin de nodo raiz esperado");
		return otb;
	}

	static byte[] ReadData(byte[] b, ref int p)
	{
		var ms = new MemoryStream();
		while (true)
		{
			byte c = b[p];
			if (c == NODE_START || c == NODE_END) return ms.ToArray();
			if (c == ESCAPE) { p++; c = b[p]; }
			ms.WriteByte(c);
			p++;
		}
	}

	static void WriteData(Stream s, byte[] d)
	{
		foreach (var c in d)
		{
			if (c == NODE_START || c == NODE_END || c == ESCAPE) s.WriteByte(ESCAPE);
			s.WriteByte(c);
		}
	}

	public void Save(string path)
	{
		using (var fs = new FileStream(path, FileMode.Create))
		{
			fs.Write(Identifier, 0, 4);
			fs.WriteByte(NODE_START);
			WriteData(fs, RootData);
			foreach (var it in Items)
			{
				fs.WriteByte(NODE_START);
				WriteData(fs, it.Serialize());
				fs.WriteByte(NODE_END);
			}
			fs.WriteByte(NODE_END);
		}
	}

	public OtbItem FindByServerId(int id)
	{
		foreach (var it in Items) if (it.ServerId == id) return it;
		return null;
	}

	public int MaxServerId()
	{
		int m = 0;
		foreach (var it in Items) if (it.ServerId > m) m = it.ServerId;
		return m;
	}
}
