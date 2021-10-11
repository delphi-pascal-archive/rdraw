{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RUndo;

interface

uses
  Classes, {Contnrs, }RTypes, RCore, RIntf;

type
  TRUndoPoint = class
  private
    FSheet: TRSheet;
    FLayer: TRLayer;
  protected
    property Layer: TRLayer read FLayer;
    property Sheet: TRSheet read FSheet;
    procedure Restore; virtual; abstract;
    constructor Create(ASheet: TRSheet; ALayer: TRLayer);
  public
    procedure Recover;
  end;

  IUndoable = interface
  ['{829AEF35-B52E-49BF-9DD0-50BEC5721796}']
    function CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
      Aspects: TDataAspects): TRUndoPoint;
  end;

  TRUndoStack = class
  private
    FUndoList: TList;
    FDepth: Integer;
    FRecovering: Boolean;
    procedure SetDepth(Value: Integer);
  public
    property Depth: Integer read FDepth write SetDepth;
    property Recovering: Boolean read FRecovering;

    constructor Create;
    destructor Destroy; override;

    procedure Push(Point: TRUndoPoint);
    procedure Pop;
    procedure Clear;

    procedure HandleKbd(Event: TKbdEventID; var Key: Word; Shift: TShiftState);
  end;

  TRStreamableUndoPoint = class(TRUndoPoint)
  private
    FFigure: TRFigure;
    FStream: TStream;
    FAspects: TDataAspects;

  public
    constructor Create(AFigure: TRFigure; ASheet: TRSheet;
      ALayer: TRLayer; Aspects: TDataAspects);

    destructor Destroy; override;
    procedure Restore; override;
  end;

function UndoStack(Sheet: TRSheet): TRUndoStack;
function GetUndoPoint(Figure: TRFigure; Sheet: TRSheet; Layer: TRLayer;
  Aspects: TDataAspects): TRUndoPoint;

function CommonUndoStack: TRUndoStack;

implementation

uses Math;

const
  UndoDepth = 20;

var
  theUndoStack: TRUndoStack;

function GetUndoPoint(Figure: TRFigure; Sheet: TRSheet; Layer: TRLayer;
  Aspects: TDataAspects): TRUndoPoint;
var u: IUndoable;
    sp: IStreamPersist;
    st: IStreamable;
begin
  if Figure.GetInterface(IUndoable, u) then
    Result := u.CreateUndoPoint(Sheet, Layer, Aspects)
  else if Figure.GetInterface(IStreamPersist, sp) then
    Result := TRStreamableUndoPoint.Create(Figure, Sheet, Layer, Aspects)
  else if Figure.GetInterface(IStreamable, st) then
    Result := TRStreamableUndoPoint.Create(Figure, Sheet, Layer, Aspects)
  else if Figure is TRAgentDecorator then
    Result := GetUndoPoint(TRAgentDecorator(Figure).Decoree, Sheet, Layer, Aspects)
  else
    Result := nil;
end;

{----------------------------- TRUndoPoint ------------------------------------}

constructor TRUndoPoint.Create(ASheet: TRSheet; ALayer: TRLayer);
begin
  FSheet := ASheet;
  FLayer := ALayer;
end;

procedure TRUndoPoint.Recover;
begin
  if Self = nil then Exit;

  Assert(not InsideRBrackets);

  if Assigned(FSheet)and Assigned(FLayer)then
  begin
    FSheet.BeginDeal;
    FLayer.Deselect;
    // Restore;
    FSheet.EndDeal;
  end;

  Restore;

  if Assigned(FSheet) then
    FSheet.Dest.Refresh;
end;

{------------------------------- TUndoStack -----------------------------------}

constructor TRUndoStack.Create;
begin
  inherited;
  FDepth := UndoDepth;
  FUndoList := TList.Create;
end;

destructor TRUndoStack.Destroy;
var i: Integer;
begin
  for i  := 0 to FUndoList.Count - 1 do
    TObject(FUndoList[i]).Free;
  FUndoList.Free;
  inherited;
end;

procedure TRUndoStack.HandleKbd(Event: TKbdEventID; var Key: Word;
  Shift: TShiftState);
begin
  if (Event = evKeyDown)and
     (ssCtrl in Shift)and
     (Key in [Ord('Z'), Ord('z')])
  then
  begin
    Pop;
    Key := 0;
  end;
end;

procedure TRUndoStack.Clear;
begin
  FUndoList.Clear;
end;

procedure TRUndoStack.Push(Point: TRUndoPoint);
begin
  if Point = nil then Exit;

  if FRecovering then
  begin
    Point.Free;
    Exit;
  end;

  FUndoList.Add(Point);
  if FUndoList.Count > FDepth then
  begin
    TRUndoPoint(FUndoList.First).Free;
    FUndoList.Delete(0);
  end;
end;

procedure TRUndoStack.Pop;
begin
  if FUndoList.Count > 0 then
    try
      FRecovering := True;
      TRUndoPoint(FUndoList.Last).Recover;
    finally
      FRecovering := False;
      TRUndoPoint(FUndoList.Last).Free;
      FUndoList.Delete(FUndoList.Count-1);
    end;
end;

procedure TRUndoStack.SetDepth(Value: Integer);
begin
  if (Value <> FDepth)and(Value > 0) then
  begin
    FDepth := Value;
    while FUndoList.Count > FDepth do
      FUndoList.Delete(0);
  end;
end;

{------------------------------------------------------------------------------}

type THackSheet = class(TRSheet);

function UndoStack(Sheet: TRSheet): TRUndoStack;
begin
  Result := THackSheet(Sheet)._UndoStack as TRUndoStack; 
end;

function CommonUndoStack: TRUndoStack;
begin
  if theUndoStack = nil then
    theUndoStack := TRUndoStack.Create;

  Result := theUndoStack;
end;

{-------------------------- TRStreamableUndoPoint -----------------------------}

constructor TRStreamableUndoPoint.Create(AFigure: TRFigure; ASheet: TRSheet;
  ALayer: TRLayer; Aspects: TDataAspects);
var sp: IStreamPersist;
    st: IStreamable;
begin
  inherited Create(ASheet, ALayer);
  FFigure := AFigure;
  FStream := TMemoryStream.Create;
  FAspects := Aspects;

  if FFigure.GetInterface(IStreamable, st) then
    st.SaveDataToStream(FStream, Aspects)
  else if FFigure.GetInterface(IStreamPersist, sp) then
    sp.SaveToStream(FStream);
end;

destructor TRStreamableUndoPoint.Destroy;
begin
  FStream.Free;
  inherited;
end;

procedure TRStreamableUndoPoint.Restore;
var sp: IStreamPersist;
    st: IStreamable;
begin
  FStream.Position := 0;

  if FFigure.GetInterface(IStreamable, st) then
    st.LoadDataFromStream(FStream, FAspects)
  else if FFigure.GetInterface(IStreamPersist, sp) then
    sp.LoadFromStream(FStream)
end;

initialization
finalization
  theUndoStack.Free;
end.

