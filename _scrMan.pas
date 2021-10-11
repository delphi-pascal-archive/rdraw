unit _scrMan;

interface

uses
  Controls, StdCtrls, Forms, RCore, RTypes, RGeom;

type
  TScrollManager = class
  private
    FVertScrollBar: TScrollBar;
    FHorzScrollBar: TScrollBar;

    FFullViewPort: TRectF;

    FSheet: TRSheet;
    FLayer: TRLayer;

    procedure ZoomChangedHandler(Layer: TRLayer);
    procedure SetScroll(sb: TScrollBar; x0, x1, xx0, xx1: Double);
    procedure ScrollHandler(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
  public
    constructor Create(Sheet: TRSheet; Layer: TRLayer;
      HorzSB, VertSB: TScrollBar; const FullViewPort: TRectF);
  end;

implementation

{------------------------------ TScrollManager --------------------------------}

constructor TScrollManager.Create(Sheet: TRSheet; Layer: TRLayer;
      HorzSB, VertSB: TScrollBar; const FullViewPort: TRectF);
begin
  FSheet := Sheet;
  FLayer := Layer;

  FFullViewPort := FullViewPort;
  FVertScrollBar := VertSB;
  FHorzScrollBar := HorzSB;

  FLayer.OnZoomChanged := ZoomChangedHandler;
  FVertScrollBar.OnScroll := ScrollHandler;
  FHorzScrollBar.OnScroll := ScrollHandler;
end;

procedure TScrollManager.SetScroll(sb: TScrollBar; x0, x1, xx0, xx1: Double);
begin
  sb.PageSize := Round( (x1 -  x0)/(xx1 - xx0)*sb.Max );
  sb.Position := Round( (x0 - xx0)/(xx1 - xx0)*sb.Max);

  if sb.Kind = sbVertical then
    sb.Position := sb.Max - sb.PageSize - sb.Position;

  sb.Enabled := sb.PageSize < sb.Max;
end;

procedure TScrollManager.ZoomChangedHandler(Layer: TRLayer);
var VP, FullVP: TRectF;
begin
  FullVP := FFullViewPort;
  VP := Layer.ViewPort;

  SetScroll(FHorzScrollBar, VP.XMin, VP.XMax, FullVP.XMin, FullVP.XMax);
  SetScroll(FVertScrollBar, VP.YMin, VP.YMax, FullVP.YMin, FullVP.YMax);
end;

procedure TScrollManager.ScrollHandler(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
var
  sb: TScrollBar;
  Pos: Integer;
  VP, FullVP: TRectF;
  Delta: Double;
begin
  sb := Sender as TScrollBar;
  FullVP := FFullViewPort;

//  if ScrollPos + sb.PageSize > sb.Max + 1 then ScrollPos := - sb.PageSize + sb.Max + 1;

  Pos := ScrollPos;
  VP := FLayer.ViewPort;
  if sb.Kind = sbVertical then
    Pos := sb.Max - sb.PageSize - Pos;

  case sb.Kind of
    sbHorizontal:
    begin
      Delta := Pos/sb.Max*(FullVP.XMax - FullVP.XMin) + FullVP.XMin - VP.XMin;
      OffsetRectF(VP, Delta, 0);
    end;
    sbVertical:
    begin
      Delta := Pos/sb.Max*(FullVP.YMax - FullVP.YMin) + FullVP.YMin - VP.YMin;
      OffsetRectF(VP, 0, Delta);
    end;
  end;

  FLayer.ViewPort := VP;
  FSheet.Dest.Refresh;
end;

end.
