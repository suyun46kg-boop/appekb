$src = 'C:\Users\suyun\.cursor\projects\c-Users-suyun-suyun1-project2-ekbkyrgyzdar\assets\c__Users_suyun_AppData_Roaming_Cursor_User_workspaceStorage_cc579191f1ef26b30a8b9be7655a73bf_images_photo_2026-07-14_20-09-03-3537cae9-7091-4eed-b293-a4ce1427de28.png'
$destDir = 'C:\Users\suyun\suyun1\project2\ekbkyrgyzdar\assets\images\categories'
$canvasSize = 256
$padding = 18
$bgThreshold = 40

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CategoryIconTools
{
  public static void RemoveDarkBackground(Bitmap bmp, int threshold)
  {
    var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
    var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    int bytes = Math.Abs(data.Stride) * bmp.Height;
    byte[] px = new byte[bytes];
    Marshal.Copy(data.Scan0, px, 0, bytes);
    for (int i = 0; i < px.Length; i += 4)
    {
      byte b = px[i];
      byte g = px[i + 1];
      byte r = px[i + 2];
      if (r <= threshold && g <= threshold && b <= threshold)
      {
        px[i + 3] = 0;
      }
    }
    Marshal.Copy(px, 0, data.Scan0, bytes);
    bmp.UnlockBits(data);
  }

  public static Bitmap TrimAndCenter(Bitmap src, int canvasSize, int padding)
  {
    int minX = src.Width;
    int minY = src.Height;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < src.Height; y++)
    {
      for (int x = 0; x < src.Width; x++)
      {
        if (src.GetPixel(x, y).A > 12)
        {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX)
    {
      return (Bitmap)src.Clone();
    }

    int cw = maxX - minX + 1;
    int ch = maxY - minY + 1;
    var cropped = new Bitmap(cw, ch, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(cropped))
    {
      g.Clear(Color.Transparent);
      g.DrawImage(src, new Rectangle(0, 0, cw, ch), new Rectangle(minX, minY, cw, ch), GraphicsUnit.Pixel);
    }

    int inner = canvasSize - (padding * 2);
    float scale = Math.Min((float)inner / cw, (float)inner / ch);
    int dw = Math.Max(1, (int)Math.Round(cw * scale));
    int dh = Math.Max(1, (int)Math.Round(ch * scale));

    var result = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(result))
    {
      g.Clear(Color.Transparent);
      g.InterpolationMode = InterpolationMode.HighQualityBicubic;
      g.SmoothingMode = SmoothingMode.HighQuality;
      g.PixelOffsetMode = PixelOffsetMode.HighQuality;
      int ox = (canvasSize - dw) / 2;
      int oy = (canvasSize - dh) / 2;
      g.DrawImage(cropped, new Rectangle(ox, oy, dw, dh));
    }

    cropped.Dispose();
    return result;
  }
}
"@ -ReferencedAssemblies @([System.Drawing.Image].Assembly.Location)

$names = @(
  'category_apartment.png','category_job.png','category_border.png','category_auto.png',
  'category_ticket.png','category_services.png','category_sale.png','category_parttime.png'
)

New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$img = [System.Drawing.Image]::FromFile($src)
$cols = 4
$row1H = [int][math]::Floor($img.Height / 2)
$row2H = [int]$img.Height - $row1H
$cellW = [int]($img.Width / $cols)
$inset = 8
$idx = 0

for ($r = 0; $r -lt 2; $r++) {
  $y = if ($r -eq 0) { 0 } else { $row1H }
  $h = if ($r -eq 0) { $row1H } else { $row2H }
  for ($c = 0; $c -lt $cols; $c++) {
    $x = $c * $cellW
    $w = if ($c -eq ($cols - 1)) { [int]$img.Width - $x } else { $cellW }
    $rect = New-Object System.Drawing.Rectangle ($x + $inset), ($y + $inset), ($w - $inset * 2), ($h - $inset * 2)
    $bmp = New-Object System.Drawing.Bitmap $rect.Width, $rect.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $rect.Width, $rect.Height), $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    [CategoryIconTools]::RemoveDarkBackground($bmp, $bgThreshold)
    $final = [CategoryIconTools]::TrimAndCenter($bmp, $canvasSize, $padding)
    $bmp.Dispose()

    $out = Join-Path $destDir $names[$idx]
    $final.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $final.Dispose()
    Write-Output "Saved $out"
    $idx++
  }
}

$img.Dispose()
