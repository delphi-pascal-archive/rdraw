{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RUtils;

interface

uses
  Classes, Graphics,
  RCore, RTypes;

type
  TFigurePredicate = function(Figure: TRFigure): Boolean of object;

  function IsServant(Figure: TRFigure): Boolean;

  function FindSelectionObject(Sheet: TRSheet; ClassFilter: array of TClass): TRFigure; overload;
  function FindSelectionObject(Sheet: TRSheet; Filter: TFigurePredicate): TRFigure; overload;
  function PrimarySelectionObject(Sheet: TRSheet): TRFigure; overload;

  function GetPopupInfo(Sender: TObject{TMenuItem}): TRPopupInfo;

  procedure UndoablyDuplicateSelection(const Shift: TPointF);

  {----------------------------------------------------------------------------}

  function ReadStringFromStream(Stream: TStream): string;
  procedure WriteStringToStream(Stream: TStream; const S: string);

  procedure ReadSignatureFromStream(Stream: TStream; Signature: Integer; const ErrorMsg: string);
  procedure WriteSignatureToStream(Stream: TStream; Signature: Integer);

  procedure ReadGraphicsFromStream(Stream: TStream; AGraphic: TGraphic);
  procedure WriteGraphicsToStream(Stream: TStream; AGraphic: TGraphic);

implementation

uses
  SysUtils, Menus,
  RFigHlp, RGroup, RUndo, RTool;

type
  EWrongSignature = class(Exception);

{------------------------------------------------------------------------------}

function GetPopupInfo(Sender: TObject{TMenuItem}): TRPopupInfo;
var menu: TPopupMenu;
begin
  menu := (Sender as TMenuItem).GetParentMenu as TPopupMenu;
  Result := menu.PopupComponent as TRPopupInfo;
end;

function IsServant(Figure: TRFigure): Boolean;
begin
  Result := fsServant in Figure.Style;
end;

procedure UndoablyDuplicateSelection(const Shift: TPointF);
const Mode: array[Boolean]of TRSelectMode = (smNormal, smPlus);
var data: TTransformData;
    stm: TStream;
    fig, newFig: TRFigure;
    grp: TRMaster; 
    i: Integer;
begin
  if InputSheet = nil then Exit;

  InputSheet.BeginDeal;
  try
    fig := PrimarySelectionObject(InputSheet);
    if fig = nil then Exit;

    stm := TMemoryStream.Create;
    try
      TRFigureHelper(fig).Serialize(stm);
      stm.Position := 0;
      newFig := TRFigureHelper(nil).Deserialize(stm);

      UndoStack(InputSheet).Push(
        TRCreationUndoPoint.Create(newFig, InputSheet, InputSheet.ActiveLayer)
      );

      if fig is TRSelectionGroup then
      begin
        TRSelectionGroup(fig).Sort; 
        grp := TRSelectionGroup(fig).Figures[0].Master;
        for i := 0 to TRSelectionGroup(newFig).Count-1 do
          grp.Add(TRSelectionGroup(newFig)[i]);
      end
      else
      begin
        grp := fig.Master;
        grp.Add(newFig);
      end;

    finally
      stm.Free;
    end;

    InitTranslateData(data, Shift.X, Shift.Y);
    TRFigureHelper(newFig).Transform(Data);

    if fig is TRSelectionGroup then
    begin
      for i := 0 to TRSelectionGroup(newFig).Count-1 do
        TRSelectionGroup(newFig)[i].SelectProgramly(
          InputSheet.ActiveLayer, Mode[i <> 0]
        );
      TRSelectionGroup(newFig).Free; 
    end
    else
    begin
      newFig.SelectProgramly(InputSheet.ActiveLayer);
    end;

    InputSheet.Redraw := True;
  finally
    InputSheet.EndDeal;
  end;
end;

function FindSelectionObject(Sheet: TRSheet; ClassFilter: array of TClass): TRFigure;
var sel: TRFigure;

  function Filter(Obj: TObject): Boolean;
  var i: Integer;
  begin
    Result := False;
    for i := 0 to Length(ClassFilter)-1 do
      if Obj.InheritsFrom(ClassFilter[i]) then
      begin
        Result := True;
        Break;
      end;
  end;

begin
  Result := nil;
  if not Assigned(Sheet) then Exit;
  sel := Sheet.GetCurrentAgent;
  if not Assigned(sel) then Exit;

  repeat
    if Filter(sel) then
    begin
      Result := sel;
      Break;
    end;
    if sel is TRAgentDecorator
      then sel := TRAgentDecorator(sel).Decoree
      else Break;
  until False;
end;

function FindSelectionObject(Sheet: TRSheet; Filter: TFigurePredicate): TRFigure;
var sel: TRFigure;
begin
  Result := nil;

  sel := Sheet.GetCurrentAgent;
  repeat
  
    if Assigned(sel) and Filter(sel) then
    begin
      Result := sel;
      Break;
    end;
    if sel is TRAgentDecorator
      then sel := TRAgentDecorator(sel).Decoree
      else Break;
      
  until False;
end;

type
    TDummy = class
    public
      class function IsNotAgentDecorator(Figure: TRFigure): Boolean; register;
    end;

    class function TDummy.IsNotAgentDecorator(Figure: TRFigure): Boolean; register;
    begin
      Result := not (Figure is TRAgentDecorator);
    end;

function PrimarySelectionObject(Sheet: TRSheet): TRFigure;
begin
  Result := FindSelectionObject(Sheet, TDummy.IsNotAgentDecorator);
end;

function ReadStringFromStream(Stream: TStream): string;
var L: Integer;
begin
  L := 0;
  Stream.ReadBuffer(L, SizeOf(L));
  SetLength(Result, L);
  if L > 0 then Stream.ReadBuffer(Result[1], L);
end;

procedure WriteStringToStream(Stream: TStream; const S: string);
var L: Integer;
    str: string;
begin
  L := Length(S);
  str := S;
  Stream.WriteBuffer(L, SizeOf(L));
  if L > 0 then Stream.WriteBuffer(str[1], L);
end;

procedure ReadSignatureFromStream(Stream: TStream; Signature: Integer;
  const ErrorMsg: string);
var n: Integer;
begin
  n := 0;
  Stream.ReadBuffer(n, SizeOf(n));
  if n <> Signature then raise EWrongSignature.Create(ErrorMsg);
end;

procedure WriteSignatureToStream(Stream: TStream; Signature: Integer);
begin
  Stream.WriteBuffer(Signature, SizeOf(Signature));
end;

procedure ReadGraphicsFromStream(Stream: TStream; AGraphic: TGraphic);
var tmpStream: TStream;
    n: Int64;
begin
  if AGraphic is TBitmap then
    AGraphic.LoadFromStream(Stream)
  else
  begin
    {JPEGImage reads until end of Stream}
    tmpStream := TMemoryStream.Create;
    try
      n := 0;
      Stream.ReadBuffer(n, SizeOf(n));
      tmpStream.CopyFrom(Stream, n);
      tmpStream.Position := 0;
      AGraphic.LoadFromStream(tmpStream);
    finally
      tmpStream.Free;
    end;
  end;
end;

procedure WriteGraphicsToStream(Stream: TStream; AGraphic: TGraphic);
var tmpStream: TStream;
    n: Int64;
begin
  if AGraphic is TBitmap then
    AGraphic.SaveToStream(Stream)
  else
  begin
    tmpStream := TMemoryStream.Create;
    try
      AGraphic.SaveToStream(tmpStream);
      tmpStream.Position := 0; 
      n := tmpStream.Size;
      Stream.WriteBuffer(n, SizeOf(n));
      Stream.CopyFrom(tmpStream, n);
    finally
      tmpStream.Free;
    end;
  end;
end;

end.
