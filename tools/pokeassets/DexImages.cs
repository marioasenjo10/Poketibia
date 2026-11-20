// Genera las imagenes de la pokedex (modules/game_pokedex/images) con System.Drawing.
// Uso (PowerShell): Add-Type -Path DexImages.cs -ReferencedAssemblies System.Drawing; [DexImages]::Run('<carpeta>')
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class DexImages
{
    static Bitmap NewBitmap(int w, int h)
    {
        return new Bitmap(w, h, PixelFormat.Format32bppArgb);
    }

    static Graphics NewGraphics(Bitmap b)
    {
        Graphics g = Graphics.FromImage(b);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.Clear(Color.Transparent);
        return g;
    }

    static GraphicsPath Rounded(RectangleF r, float rad)
    {
        GraphicsPath p = new GraphicsPath();
        float d = rad * 2;
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    static void Save(Bitmap b, string dir, string name)
    {
        b.Save(Path.Combine(dir, name), ImageFormat.Png);
    }

    static void Pokeball(string dir, string name, int s, Color top)
    {
        using (Bitmap b = NewBitmap(s, s))
        using (Graphics g = NewGraphics(b))
        {
            RectangleF r = new RectangleF(0.5f, 0.5f, s - 1.5f, s - 1.5f);
            using (SolidBrush red = new SolidBrush(top)) g.FillPie(red, r.X, r.Y, r.Width, r.Height, 180, 180);
            using (SolidBrush white = new SolidBrush(Color.FromArgb(240, 240, 240))) g.FillPie(white, r.X, r.Y, r.Width, r.Height, 0, 180);
            float band = Math.Max(1.2f, s / 9f);
            using (Pen p = new Pen(Color.FromArgb(25, 25, 25), band)) g.DrawLine(p, r.X, s / 2f - 0.5f, r.Right, s / 2f - 0.5f);
            using (Pen p = new Pen(Color.FromArgb(25, 25, 25), Math.Max(1f, s / 14f))) g.DrawEllipse(p, r);
            float c = s * 0.2f;
            RectangleF center = new RectangleF(s / 2f - c - 0.5f, s / 2f - c - 0.5f, c * 2, c * 2);
            using (SolidBrush white = new SolidBrush(Color.FromArgb(250, 250, 250))) g.FillEllipse(white, center);
            using (Pen p = new Pen(Color.FromArgb(25, 25, 25), Math.Max(1f, s / 14f))) g.DrawEllipse(p, center);
            Save(b, dir, name);
        }
    }

    static void RoundedBox(string dir, string name, int s, float rad, Color fill, Color border)
    {
        using (Bitmap b = NewBitmap(s, s))
        using (Graphics g = NewGraphics(b))
        using (GraphicsPath path = Rounded(new RectangleF(0.5f, 0.5f, s - 1.5f, s - 1.5f), rad))
        {
            using (SolidBrush brush = new SolidBrush(fill)) g.FillPath(brush, path);
            if (border.A > 0)
                using (Pen p = new Pen(border, 1f)) g.DrawPath(p, path);
            Save(b, dir, name);
        }
    }

    static PointF[] Star(float cx, float cy, float outer, float inner)
    {
        PointF[] pts = new PointF[8];
        for (int i = 0; i < 8; i++)
        {
            double a = (-90 + i * 45) * Math.PI / 180;
            float rr = (i % 2 == 0) ? outer : inner;
            pts[i] = new PointF(cx + (float)(Math.Cos(a) * rr), cy + (float)(Math.Sin(a) * rr));
        }
        return pts;
    }

    static void ShinyButton(string dir, string name, bool on, bool hover)
    {
        int s = 32;
        using (Bitmap b = NewBitmap(s, s))
        using (Graphics g = NewGraphics(b))
        {
            RectangleF r = new RectangleF(1, 1, s - 3, s - 3);
            if (on)
            {
                using (LinearGradientBrush brush = new LinearGradientBrush(r, Color.FromArgb(255, 226, 110), Color.FromArgb(226, 150, 20), 90f))
                    g.FillEllipse(brush, r);
                using (Pen p = new Pen(Color.FromArgb(255, 240, 180), 1.2f)) g.DrawEllipse(p, r);
                using (SolidBrush w = new SolidBrush(Color.White)) g.FillPolygon(w, Star(s / 2f - 0.5f, s / 2f - 0.5f, 10f, 3f));
            }
            else
            {
                using (SolidBrush brush = new SolidBrush(hover ? Color.FromArgb(48, 66, 96) : Color.FromArgb(28, 40, 60))) g.FillEllipse(brush, r);
                using (Pen p = new Pen(Color.FromArgb(214, 170, 60), 1.2f)) g.DrawEllipse(p, r);
                using (SolidBrush w = new SolidBrush(Color.FromArgb(255, 205, 70))) g.FillPolygon(w, Star(s / 2f - 0.5f, s / 2f - 0.5f, 10f, 3f));
            }
            Save(b, dir, name);
        }
    }

    static void SearchButton(string dir, string name, bool hover)
    {
        int s = 32;
        using (Bitmap b = NewBitmap(s, s))
        using (Graphics g = NewGraphics(b))
        {
            RectangleF r = new RectangleF(1, 1, s - 3, s - 3);
            using (SolidBrush brush = new SolidBrush(hover ? Color.FromArgb(48, 66, 96) : Color.FromArgb(28, 40, 60))) g.FillEllipse(brush, r);
            using (Pen p = new Pen(Color.FromArgb(90, 120, 160), 1.2f)) g.DrawEllipse(p, r);
            using (Pen p = new Pen(Color.White, 2.2f)) g.DrawEllipse(p, 9f, 9f, 11f, 11f);
            using (Pen p = new Pen(Color.White, 3f))
            {
                p.StartCap = LineCap.Round;
                p.EndCap = LineCap.Round;
                g.DrawLine(p, 19f, 19f, 23f, 23f);
            }
            Save(b, dir, name);
        }
    }

    static void Gradient(string dir, string name)
    {
        // esquinas izquierdas redondeadas (radio 6, dentro del borde de card.png); usar con image-border 8 por la izquierda
        int w = 256, h = 32;
        const float rad = 6f;
        const int ss = 4;
        using (Bitmap b = NewBitmap(w, h))
        {
            for (int x = 0; x < w; x++)
            {
                double t = 1.0 - x / (double)(w - 1);
                double a = 190 * Math.Pow(t, 1.4);
                for (int y = 0; y < h; y++)
                {
                    int inside = 0;
                    for (int sy = 0; sy < ss; sy++)
                        for (int sx = 0; sx < ss; sx++)
                        {
                            float px = x + (sx + 0.5f) / ss, py = y + (sy + 0.5f) / ss;
                            float cy = py < rad ? rad : (py > h - rad ? h - rad : py);
                            float dx = px < rad ? rad - px : 0, dy = py - cy;
                            if (dx * dx + dy * dy <= rad * rad) inside++;
                        }
                    b.SetPixel(x, y, Color.FromArgb((int)(a * inside / (ss * ss)), 255, 255, 255));
                }
            }
            Save(b, dir, name);
        }
    }

    static void Arrow(string dir, string name)
    {
        using (Bitmap b = NewBitmap(16, 16))
        using (Graphics g = NewGraphics(b))
        using (Pen p = new Pen(Color.FromArgb(150, 170, 200), 2.2f))
        {
            p.StartCap = LineCap.Round;
            p.EndCap = LineCap.Round;
            p.LineJoin = LineJoin.Round;
            g.DrawLines(p, new PointF[] { new PointF(5, 3), new PointF(11, 8), new PointF(5, 13) });
            Save(b, dir, name);
        }
    }

    static void Circle(string dir, string name, int s, Color fill, Color ring, float ringWidth)
    {
        using (Bitmap b = NewBitmap(s, s))
        using (Graphics g = NewGraphics(b))
        {
            float m = ringWidth / 2 + 0.5f;
            RectangleF r = new RectangleF(m, m, s - 2 * m - 0.5f, s - 2 * m - 0.5f);
            using (SolidBrush brush = new SolidBrush(fill)) g.FillEllipse(brush, r);
            if (ringWidth > 0)
                using (Pen p = new Pen(ring, ringWidth)) g.DrawEllipse(p, r);
            Save(b, dir, name);
        }
    }

    // chincheta de ciudad para el mapa grande
    static void Pin(string dir, string name, Color fill)
    {
        int w = 16, h = 22;
        using (Bitmap b = NewBitmap(w, h))
        using (Graphics g = NewGraphics(b))
        using (GraphicsPath path = new GraphicsPath())
        {
            float cx = w / 2f, r = 6.5f, cy = 7.5f;
            path.AddArc(cx - r, cy - r, r * 2, r * 2, 150, 240);
            path.AddLine(cx + r * (float)Math.Cos(Math.PI / 6), cy + r * 0.5f, cx, h - 1.5f);
            path.CloseFigure();
            using (SolidBrush shadow = new SolidBrush(Color.FromArgb(90, 0, 0, 0)))
                g.FillEllipse(shadow, cx - 4f, h - 3.5f, 8f, 3f);
            using (SolidBrush brush = new SolidBrush(fill)) g.FillPath(brush, path);
            using (Pen p = new Pen(Color.FromArgb(200, 255, 255, 255), 1.2f)) g.DrawPath(p, path);
            using (SolidBrush white = new SolidBrush(Color.White)) g.FillEllipse(white, cx - 2.5f, cy - 2.5f, 5f, 5f);
            Save(b, dir, name);
        }
    }

    public static void Run(string dir)
    {
        Directory.CreateDirectory(dir);
        Pokeball(dir, "pokeball.png", 14, Color.FromArgb(227, 53, 13));
        Pokeball(dir, "pokeball_big.png", 22, Color.FromArgb(227, 53, 13));
        RoundedBox(dir, "chip.png", 20, 8f, Color.White, Color.Transparent);
        RoundedBox(dir, "card.png", 32, 7f, Color.FromArgb(22, 33, 51), Color.FromArgb(40, 56, 82));
        RoundedBox(dir, "card_hover.png", 32, 7f, Color.FromArgb(28, 42, 64), Color.FromArgb(70, 110, 160));
        RoundedBox(dir, "card_active.png", 32, 7f, Color.FromArgb(34, 46, 66), Color.FromArgb(255, 196, 60));
        RoundedBox(dir, "panel.png", 32, 9f, Color.FromArgb(14, 21, 34), Color.FromArgb(38, 52, 76));
        Gradient(dir, "gradient.png");
        ShinyButton(dir, "shiny.png", false, false);
        ShinyButton(dir, "shiny_hover.png", false, true);
        ShinyButton(dir, "shiny_on.png", true, false);
        SearchButton(dir, "search.png", false);
        SearchButton(dir, "search_hover.png", true);
        Arrow(dir, "arrow.png");
        Circle(dir, "dot.png", 8, Color.White, Color.Transparent, 0);
        Circle(dir, "marker.png", 30, Color.FromArgb(215, 14, 21, 34), Color.FromArgb(255, 170, 40), 2f);
        Pin(dir, "pin.png", Color.FromArgb(232, 52, 52));
        Pin(dir, "pin_off.png", Color.FromArgb(120, 128, 142));
    }
}
