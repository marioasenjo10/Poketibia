using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;

// Imagenes oficiales de los pokemon para la pokedex (modules/game_pokedex/artwork/<nombre en minusculas>.png).
// Lee los pokemon del servidor (monsters.xml), busca su numero en PokeAPI por nombre y descarga el
// "official-artwork" (o la version shiny), recorta lo transparente y lo deja en un PNG de 128x128.
// Uso (PowerShell): Add-Type -Path Artwork.cs -ReferencedAssemblies System.Drawing
//                   [Artwork]::Run(carpetaMonster, carpetaSalida)
// Las imagenes son propiedad de Nintendo / Game Freak / The Pokemon Company.

public static class Artwork
{
	const int Size = 128;
	const string SpeciesUrl = "https://pokeapi.co/api/v2/pokemon-species?limit=5000";
	const string ArtUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/";

	static string Key(string name)
	{
		var sb = new StringBuilder();
		foreach (char c in name.ToLowerInvariant())
			if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) sb.Append(c);
		return sb.ToString();
	}

	public static string Run(string monsterDir, string outDir)
	{
		ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
		var log = new StringBuilder();
		var web = new WebClient();
		web.Headers.Add("User-Agent", "Poketibia-pokedex-tool");

		// especies de PokeAPI: nombre normalizado -> numero nacional
		var species = new Dictionary<string, int>();
		string json = web.DownloadString(SpeciesUrl);
		foreach (Match m in Regex.Matches(json, "\"name\":\"([^\"]+)\",\"url\":\"[^\"]*/pokemon-species/(\\d+)/\""))
			species[Key(m.Groups[1].Value)] = int.Parse(m.Groups[2].Value);
		// nombres de algunos servidores que no coinciden con PokeAPI
		var alias = new Dictionary<string, string> {
			{ "nidoranfemale", "nidoranf" }, { "nidoranmale", "nidoranm" },
			{ "nidoran", "nidoranm" }, { "mrmine", "mrmime" }, { "farfetch", "farfetchd" },
		};

		// pokemon del servidor: nombre -> dexentry
		var monsters = new SortedDictionary<string, int>(StringComparer.OrdinalIgnoreCase);
		string listXml = File.ReadAllText(Path.Combine(monsterDir, "monsters.xml"));
		var dexRegex = new Regex("dexentry\\s*=\\s*\"(\\d+)\"", RegexOptions.IgnoreCase);
		foreach (Match m in Regex.Matches(listXml, "<monster\\s+name=\"([^\"]+)\"\\s+file=\"([^\"]+)\""))
		{
			string file = Path.Combine(monsterDir, m.Groups[2].Value.Replace('/', Path.DirectorySeparatorChar));
			if (!File.Exists(file)) continue;
			var d = dexRegex.Match(File.ReadAllText(file));
			if (!d.Success) continue;
			int dex = int.Parse(d.Groups[1].Value);
			if (dex > 0) monsters[m.Groups[1].Value] = dex;
		}

		Directory.CreateDirectory(outDir);
		int done = 0, cached = 0;
		var missing = new List<string>();
		foreach (var pair in monsters)
		{
			string name = pair.Key;
			bool shiny = name.StartsWith("Shiny ", StringComparison.OrdinalIgnoreCase);
			string baseName = shiny ? name.Substring(6) : name;
			string key = Key(baseName);
			string aliasKey;
			if (!species.ContainsKey(key) && alias.TryGetValue(key, out aliasKey)) key = aliasKey;
			int id;
			if (!species.TryGetValue(key, out id))
			{
				missing.Add(name + " (" + pair.Value + ")");
				continue;
			}
			string outPath = Path.Combine(outDir, name.ToLowerInvariant() + ".png");
			if (File.Exists(outPath)) { cached++; continue; }
			try
			{
				byte[] data = web.DownloadData(ArtUrl + (shiny ? "shiny/" : "") + id + ".png");
				using (var ms = new MemoryStream(data))
				using (var src = new Bitmap(ms))
				using (var final = Fit(src))
					final.Save(outPath, ImageFormat.Png);
				done++;
			}
			catch (WebException e)
			{
				missing.Add(name + " (#" + id + ": " + e.Message + ")");
			}
		}
		log.AppendLine("descargadas: " + done + ", ya estaban: " + cached + ", sin imagen: " + missing.Count);
		foreach (var m in missing) log.AppendLine("  - " + m);
		return log.ToString();
	}

	static Rectangle Bounds(Bitmap b)
	{
		int x0 = b.Width, y0 = b.Height, x1 = -1, y1 = -1;
		var data = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
		var row = new int[b.Width];
		for (int y = 0; y < b.Height; y++)
		{
			System.Runtime.InteropServices.Marshal.Copy(data.Scan0 + y * data.Stride, row, 0, b.Width);
			for (int x = 0; x < b.Width; x++)
			{
				if (((row[x] >> 24) & 255) < 8) continue;
				if (x < x0) x0 = x;
				if (x > x1) x1 = x;
				if (y < y0) y0 = y;
				if (y > y1) y1 = y;
			}
		}
		b.UnlockBits(data);
		return x1 < 0 ? new Rectangle(0, 0, b.Width, b.Height) : Rectangle.FromLTRB(x0, y0, x1 + 1, y1 + 1);
	}

	// recorta lo transparente y lo centra en Size x Size sin deformarlo
	static Bitmap Fit(Bitmap src)
	{
		var box = Bounds(src);
		float scale = Math.Min((float)Size / box.Width, (float)Size / box.Height);
		int w = Math.Max(1, (int)Math.Round(box.Width * scale)), h = Math.Max(1, (int)Math.Round(box.Height * scale));
		var final = new Bitmap(Size, Size, PixelFormat.Format32bppArgb);
		using (var g = Graphics.FromImage(final))
		using (var attrs = new ImageAttributes())
		{
			g.Clear(Color.Transparent);
			g.InterpolationMode = InterpolationMode.HighQualityBicubic;
			g.PixelOffsetMode = PixelOffsetMode.HighQuality;
			g.CompositingQuality = CompositingQuality.HighQuality;
			attrs.SetWrapMode(WrapMode.TileFlipXY);
			g.DrawImage(src, new Rectangle((Size - w) / 2, (Size - h) / 2, w, h), box.X, box.Y, box.Width, box.Height, GraphicsUnit.Pixel, attrs);
		}
		return final;
	}
}
