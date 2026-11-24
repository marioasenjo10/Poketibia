using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

// Paleta del mapa mas suave. Cambia el color de minimapa de cada objeto en Tibia.dat (el cliente
// lo usa al pintar lo que vas viendo) y Minimap.cs genera world.otmm y el mapa suavizado con esos
// mismos colores, asi todo el mapa (minimapa, mapa grande y lo explorado) se ve igual.
// El cliente solo admite su paleta de 216 colores (6 niveles por canal: 0,51,102,153,204,255):
// indice = r*36 + g*6 + b con r,g,b de 0 a 5.
// Uso (PowerShell): Add-Type -Path Otb.cs,Things.cs,MapColors.cs -ReferencedAssemblies System.Drawing
//                   [MapColors]::RemapDat(datPath, $true)   # $true = solo contar
public static class MapColors
{
	static int Idx(int r, int g, int b) { return r * 36 + g * 6 + b; }

	// color de Tibia -> color nuevo (los que no estan se quedan igual)
	public static readonly Dictionary<int, int> Remap = new Dictionary<int, int>
	{
		{ Idx(0, 4, 0), Idx(2, 4, 2) },   // hierba (0,204,0) -> verde suave (102,204,102)
		{ Idx(0, 2, 0), Idx(1, 3, 1) },   // bosque (0,102,0) -> (51,153,51)
		{ Idx(3, 5, 2), Idx(3, 4, 2) },   // verde claro (153,255,102) -> (153,204,102)
		{ Idx(5, 1, 0), Idx(4, 2, 2) },   // paredes rojo-naranja (255,51,0) -> tejado suave (204,102,102)
		{ Idx(5, 2, 0), Idx(4, 3, 2) },   // naranja (255,102,0) -> (204,153,102)
		{ Idx(3, 1, 0), Idx(3, 2, 2) },   // marron rojizo (153,51,0) -> (153,102,102)
		// escaleras / rampas: amarillo puro (255,255,0) -> dorado (255,204,0), que destaque sobre el
		// beige de los caminos. La segunda linea corrige el dat de la version anterior (204,204,102).
		{ Idx(5, 5, 0), Idx(5, 4, 0) },
		{ Idx(4, 4, 2), Idx(5, 4, 0) },
		{ Idx(3, 3, 3), Idx(4, 4, 3) },   // gris claro: caminos y suelos (153,153,153) -> beige (204,204,153)
		{ Idx(5, 5, 5), Idx(4, 4, 4) },   // nieve blanco puro (255,255,255) -> gris muy claro (204,204,204)
	};

	public static int Map(int color)
	{
		int n;
		return Remap.TryGetValue(color, out n) ? n : color;
	}

	public static string RemapDat(string datPath, bool dryRun)
	{
		var dat = Dat.Load(datPath);
		var data = (byte[])dat.Data.Clone();
		var changed = new Dictionary<int, int>();
		int total = 0;
		foreach (var t in dat.Items.Values)
		{
			if (t.MinimapColorPos <= 0) continue;
			int n = Map(t.MinimapColor);
			if (n == t.MinimapColor) continue;
			data[t.MinimapColorPos] = (byte)(n & 0xFF);
			data[t.MinimapColorPos + 1] = (byte)(n >> 8);
			int c;
			changed.TryGetValue(t.MinimapColor, out c);
			changed[t.MinimapColor] = c + 1;
			total++;
		}
		var sb = new StringBuilder();
		foreach (var kv in changed) sb.AppendLine(string.Format("color {0} -> {1}: {2} objetos", kv.Key, Map(kv.Key), kv.Value));
		sb.AppendLine("Total: " + total + " objetos");
		if (dryRun) { sb.AppendLine("Prueba OK (no se ha modificado nada)."); return sb.ToString(); }
		string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
		File.Copy(datPath, datPath + ".bak-" + stamp);
		File.WriteAllBytes(datPath + ".new", data);
		Dat.Load(datPath + ".new");
		File.Copy(datPath + ".new", datPath, true); File.Delete(datPath + ".new");
		sb.AppendLine("Guardado. Copia: " + datPath + ".bak-" + stamp);
		return sb.ToString();
	}
}
