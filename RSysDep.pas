{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RSysDep;

interface

uses
{$IFDEF UNIX}
{$ELSE}
  Windows,
{$ENDIF}
  Classes,
  Graphics;

type
{$IFDEF UNIX}
  TClipRegion = TRect;
  TPoint = Classes.TPoint;
  TRect = Classes.TRect;
{$ELSE}
  TClipRegion = HRGN;
  TPoint = Windows.TPoint;
  TRect = Windows.TRect;
{$ENDIF}

{$IFDEF UNIX}
const
  VK_LEFT = 37;
  VK_RIGHT = 39;
  VK_UP = 38;
  VK_DOWN = 40;
  VK_ADD = 107;
  VK_DELETE = 46;
  VK_SUBTRACT = 109;
{$ELSE}
{$ENDIF}

function CreateClipRegion(R: TRect): TClipRegion;
procedure DeleteClipRegion(var Rgn: TClipRegion);
procedure SelectClipRegion(Canvas: TCanvas; Rgn: TClipRegion);

implementation

function CreateClipRegion(R: TRect): TClipRegion;
begin
{$IFDEF UNIX}
  Result := R;
{$ELSE}
  Result := CreateRectRgn(R.Left, R.Top, R.Right, R.Bottom);
{$ENDIF}
end;

procedure DeleteClipRegion(var Rgn: TClipRegion);
begin
{$IFDEF UNIX}
  // Do nothing
{$ELSE}
  if Rgn <> 0 then DeleteObject(Rgn);
  Rgn := 0;
{$ENDIF}
end;

procedure SelectClipRegion(Canvas: TCanvas; Rgn: TClipRegion);
begin
{$IFDEF UNIX}
  Canvas.ClipRect := Rgn;
  Canvas.Clipping := True;
{$ELSE}
  SelectClipRgn(Canvas.Handle, Rgn);
{$ENDIF}
end;

end.
