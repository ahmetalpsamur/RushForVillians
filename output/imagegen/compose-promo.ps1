Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path "$PSScriptRoot/../..").Path
$bmp = New-Object System.Drawing.Bitmap 1024,500
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$rect = New-Object System.Drawing.Rectangle 0,0,1024,500
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,([System.Drawing.Color]::FromArgb(10,12,28)),([System.Drawing.Color]::FromArgb(43,13,52)),25
$g.FillRectangle($bg,$rect)
function Glow($x,$y,$radius,$color){
  for($r=$radius;$r -gt 0;$r-=8){
    $b=New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(3,$color))
    $g.FillEllipse($b,($x-$r),($y-$r),($r*2),($r*2));$b.Dispose()
  }
}
Glow 800 255 260 ([System.Drawing.Color]::Magenta)
Glow 570 330 180 ([System.Drawing.Color]::DeepSkyBlue)
$line=New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(35,166,96,213)),1
for($y=395;$y -lt 500;$y+=22){$g.DrawLine($line,0,$y,1024,$y)}
for($x=-1000;$x -lt 2000;$x+=130){$g.DrawLine($line,720,330,$x,500)}
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,216,113))
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(242,236,255))
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(187,170,207))
$f1=New-Object System.Drawing.Font 'Georgia',64,([System.Drawing.FontStyle]::Bold),([System.Drawing.GraphicsUnit]::Pixel)
$f2=New-Object System.Drawing.Font 'Georgia',40,([System.Drawing.FontStyle]::Bold),([System.Drawing.GraphicsUnit]::Pixel)
$f3=New-Object System.Drawing.Font 'Segoe UI',25,([System.Drawing.FontStyle]::Regular),([System.Drawing.GraphicsUnit]::Pixel)
$f4=New-Object System.Drawing.Font 'Segoe UI',14,([System.Drawing.FontStyle]::Bold),([System.Drawing.GraphicsUnit]::Pixel)
$g.TextRenderingHint='AntiAliasGridFit'
$g.DrawString('RUSH',$f1,$gold,44,110)
$g.DrawString('FOR VILLAINS',$f2,$gold,47,184)
$g.FillRectangle($gold,50,254,68,3)
$g.DrawString('Every step is an adventure.',$f3,$white,47,284)
$g.DrawString('WALK. GROW. FIGHT.',$f4,$muted,49,330)
function Sprite($relative,$x,$bottom,$scale,$flip){
  $src=[System.Drawing.Bitmap]::FromFile((Join-Path $root $relative))
  $minX=$src.Width;$minY=$src.Height;$maxX=0;$maxY=0
  for($sy=0;$sy -lt $src.Height;$sy++){for($sx=0;$sx -lt $src.Width;$sx++){if($src.GetPixel($sx,$sy).A -gt 0){$minX=[Math]::Min($minX,$sx);$minY=[Math]::Min($minY,$sy);$maxX=[Math]::Max($maxX,$sx);$maxY=[Math]::Max($maxY,$sy)}}}
  $crop=$src.Clone([System.Drawing.Rectangle]::new($minX,$minY,$maxX-$minX+1,$maxY-$minY+1),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  if($flip){$crop.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)}
  $w=$crop.Width*$scale;$h=$crop.Height*$scale
  $shadow=New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110,0,0,0))
  $g.FillEllipse($shadow,$x-12,$bottom-9,$w+24,20)
  $g.InterpolationMode='NearestNeighbor';$g.PixelOffsetMode='Half'
  $g.DrawImage($crop,[System.Drawing.Rectangle]::new($x,$bottom-$h,$w,$h),0,0,$crop.Width,$crop.Height,[System.Drawing.GraphicsUnit]::Pixel)
  $src.Dispose();$crop.Dispose();$shadow.Dispose()
}
Sprite 'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Archer/Archer/Archer_Idle.gif' 455 350 8 $false
Sprite 'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Swordsman/Swordsman/Swordsman_Idle.gif' 555 420 10 $false
Sprite 'lib/All_Assets/Enemies/Characters(100x100 split)/Black Knight_A/Black Knight_A/Black Knight_A_Idle.gif' 770 420 10 $true
Sprite 'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Priest/Priest/Priest_Idle.gif' 900 335 8 $true
# Dynamic three-character arrangement inspired by the supplied reference:
# Pinky is elevated in the middle, Kupkuzu sits lower-left, and Mavili lower-right.
# Two face left and one faces right; lower legs disappear behind the canvas edge.
Sprite 'lib/Tutorial_Guy/Kupkuzu/Owlet_Monster_Idle_4.gif' 305 540 7 $true
Sprite 'lib/Tutorial_Guy/Pinky/Pink_Monster_Idle_4.gif' 405 515 7 $true
Sprite 'lib/Tutorial_Guy/Mavili/Dude_Monster_Idle_4.gif' 515 540 7 $false
$bmp.Save((Join-Path $PSScriptRoot 'rush-for-villains-game-assets-1024x500.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bmp.Dispose();$bg.Dispose()
