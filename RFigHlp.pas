{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RFigHlp;

interface

uses
  Classes, Forms,
  RCore, RTypes, RGeom, RIntf, RUtils, RUndo;

type
  TRFigureHelper = class{(TRFigure)}
  public
    function GetName: string;
    function IsTransformable: Boolean;
    procedure PlaceInRect(const Rect: TRectF);
    function Transform(var Data: TTransformData): Boolean;
    function ContainingRect: TRectF;
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
    procedure Serialize(Stream: TStream);
    function Deserialize(Stream: TStream): TRFigure;
  end;

implementation

uses
  SysUtils, Menus;
   
{------------------------------ TRFigureHelper --------------------------------}

function TRFigureHelper.IsTransformable: Boolean;
var intf: IUnknown;
begin
  Result := Assigned(Self)and
            (   Self.GetInterface(ITransformable, intf) or
                Self.GetInterface(IRectangular,   intf)      );
end;

procedure TRFigureHelper.PlaceInRect(const Rect: TRectF);
var
  Transformable: ITransformable;
  Rectangular: IRectangular;
  OrgRect: TRectF;
  Data: TTransformData;
begin
  {------------------}
  if Self = nil then
    Exit
  else
  {------------------}
  if Self.GetInterface(IRectangular, Rectangular) then
    Rectangular.SetRect(Rect)
  else
  {------------------}
  if Self.GetInterface(ITransformable, Transformable) then
  begin
    OrgRect := Transformable.ContainingRect;

    InitTranslateData(Data, Rect.XMin - OrgRect.XMin, Rect.YMin - OrgRect.YMin);
    Transformable.Transform(Data);

    InitScaleData(Data, Rect.XMin, Rect.YMin,
      (Rect.XMax-Rect.XMin)/(OrgRect.XMax-OrgRect.XMin),
      (Rect.YMax-Rect.YMin)/(OrgRect.YMax-OrgRect.YMin) );

    Transformable.Transform(Data);
  end;
  {------------------}
end;

function TRFigureHelper.Transform(var Data: TTransformData): Boolean;
var
  Transformable: ITransformable;
  Rectangular: IRectangular;
  OrgRect, DestRect: TRectF;
begin
  Result := False;
  {------------------}
  if Self = nil then
    Exit
  {------------------}
  else if (Data.Operation in [opTranslate, opScale]) and
     Self.GetInterface(IRectangular, Rectangular) then
  begin
    OrgRect := Rectangular.GetRect;
    DestRect := OrgRect;
    with Data do
      case Operation of
        opScale: ScaleRectF(DestRect, Center.X, Center.Y, KX, KY);
        opTranslate: OffsetRectF(DestRect, DX, DY);
      end;
    Rectangular.SetRect(DestRect);
    Result := True;
  end
  else
  {------------------}
  if Self.GetInterface(ITransformable, Transformable) then
  begin
    Result := Transformable.Transform(Data);
  end;
  {------------------}
end;

function TRFigureHelper.ContainingRect: TRectF;
var Transformable: ITransformable;
    Rectangular: IRectangular;
begin
  {------------------}
  if Self = nil then
    Result := EmptyRectF
  {------------------}
  else if Self.GetInterface(IRectangular, Rectangular) then
  begin
    Result := Rectangular.GetRect;
    OrientRectF(Result);
  end
  {------------------}
  else if Self.GetInterface(ITransformable, Transformable) then
    Result := Transformable.ContainingRect
  {------------------}
  else
    Result := EmptyRectF;
  {------------------}
end;

function TRFigureHelper.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
var Transformable: ITransformable;
    Rectangular: IRectangular;
begin                                       
  if Self = nil then
    Result := False
  else if Self.GetInterface(IRectangular, Rectangular) then
    Result := Rectangular.HitTest(Layer, Pt)
  else if Self.GetInterface(ITransformable, Transformable) then
    Result := Transformable.HitTest(Layer, Pt)
  else
    Result := False;
end;

function TRFigureHelper.GetName: string;
var Named: INamedObject;
begin
  if Self.GetInterface(INamedObject, Named) then
    Result := Named.Name
  else
    Result := '';
end;

procedure TRFigureHelper.Serialize(Stream: TStream);
var
  ser: ISerializeable;
  str: IStreamable;
  spers: IStreamPersist;
  style: TRFigureStyle;
  vis: Boolean;
begin
  WriteSignatureToStream(Stream, CLASS_SIGNATURE);
  WriteStringToStream(Stream, ClassName);

  {-- Style & Visible ---}
  style := TRFigure(Self).Style;
  Stream.WriteBuffer(style, SizeOf(Style));
  vis := TRFigure(Self).Visible;
  Stream.WriteBuffer(vis, SizeOf(vis));
  {----------------------}
  if TRFigure(Self).Controller <> nil
    then WriteStringToStream(Stream, TRFigure(Self).Controller.ClassName)
    else WriteStringToStream(Stream, '');

  if TRFigure(Self).PopupMenu <> nil
    then WriteStringToStream(Stream, TRFigure(Self).PopupMenu.Name)
    else WriteStringToStream(Stream, '');
  {-----------------------}
  if Self.GetInterface(ISerializeable, ser) then
    ser.Serialize(Stream)
  {-----------------------}
  else if Self.GetInterface(IStreamable, str) then
    str.SaveDataToStream(Stream, daAll)
  {-----------------------}
  else if Self.GetInterface(IStreamPersist, spers) then
    spers.SaveToStream(Stream);
end;

function FindPopupMenu(const APopupMenuName: string): TPopupMenu; forward;

function TRFigureHelper.Deserialize(Stream: TStream): TRFigure;
var
  clsName, ctlrClsName, popupName: string;
  cls: TRFigureClass;
  ctlrCls: TRControllerClass;
  ser: ISerializeable;
  str: IStreamable;
  spers: IStreamPersist;
  popup: TPopupMenu;
  style: TRFigureStyle;
  vis: Boolean;
begin
  ReadSignatureFromStream(Stream, CLASS_SIGNATURE, 'Deserialization error');

  {------- Class -------------}
  clsName := ReadStringFromStream(Stream);
  cls := TRFigureClass( FindClass(clsName) );
  {----- Style & Visible -----}
  Stream.ReadBuffer(style, SizeOf(Style));
  Stream.ReadBuffer(vis, SizeOf(vis));
  {---- Controller class -----}
  ctlrClsName := ReadStringFromStream(Stream);

  if ctlrClsName <> ''
    then ctlrCls := TRControllerClass( FindClass(ctlrClsName) )
    else ctlrCls := nil;
  {---------------------------}

  if Assigned(Self)
    then Result := TRFigure(Self)
    else Result := cls.Create;

  if Result.ClassType <> cls then
    raise Exception.Create('Invalid stream data');

  Result.Style := style;
  Result.Visible := vis;

  if (Result.Controller = nil) and (ctlrCls <> nil) then
    Result.Controller := ctlrCls.Create;

  {---------------------------}

  popupName := ReadStringFromStream(Stream);
  popup := FindPopupMenu(popupName);
  if Result.PopupMenu = nil then Result.PopupMenu := popup; 

  {-----------------------}
  if Result.GetInterface(ISerializeable, ser) then
    ser.Deserialize(Stream)
  {-----------------------}
  else if Result.GetInterface(IStreamable, str) then
    str.LoadDataFromStream(Stream, daAll)
  {-----------------------}
  else if Result.GetInterface(IStreamPersist, spers) then
    spers.SaveToStream(Stream);
end;

function FindPopupMenu(const APopupMenuName: string): TPopupMenu;
begin
  Result := Application.MainForm.FindComponent(APopupMenuName) as TPopupMenu;
end;

end.
