{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RGroup;

interface

uses
  RCore, RTypes, RIntf, RUndo, Contnrs,
  Classes, Controls;
type

  TRGroupOrderData = class;

  TOrderOperation = (opBringToFront, opSendToBack, opForwardOne, opBackOne, opChangeless);

  TRGroup = class(TRMaster, ITransformable, IUndoable, ISerializeable)
  private
    FFigures: TList;
    FOwnsFigures: Boolean;

    function GetCount: Integer;
    function GetFigures(I: Integer): TRFigure;
    procedure SetFigures(I: Integer; AValue: TRFigure);
  protected
    procedure Draw(Layer: TRLayer); override;

    procedure MoveFigure(I, Pos: Integer);
    function GetFigureOrderNumber(Figure: TRFigure): Integer;

    {ITransformable}
    function Transform(var Data: TTransformData): Boolean;

    procedure InternalAdd(Figure: TRFigure); override;
    procedure InternalRemove(Figure: TRFigure); override;
    procedure UndoablyDeleteFigure(Layer: TRLayer; Figure: TRFigure); override;

    {IUndoable}
    function CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
      Aspects: TDataAspects): TRUndoPoint; virtual;

    function GetDeleteable: Boolean; override;
  public
    property Figures[I: Integer]: TRFigure read GetFigures write SetFigures; default;
    property Count: Integer read GetCount;

    constructor CreateEx(AOwnsFigures: Boolean);
    constructor Create; override;
    destructor Destroy; override;

    function OwnsFigures: Boolean; override;
    function Contains(Figure: TRFigure): Boolean; override;

    {ITransformable}
    function ContainingRect: TRectF; virtual;
    function HitTest(Layer: TRLayer; const Pt: TPointF): Boolean; virtual;

    {IStreamableEx}
    procedure Serialize(Stream: TStream);
    procedure Deserialize(Stream: TStream);

    procedure BringToFront(Figure: TRFigure);
    procedure SendToBack(Figure: TRFigure);
    procedure ForwardOne(Figure: TRFigure);
    procedure BackOne(Figure: TRFigure);
    procedure UndoablyChangeOrder(Layer: TRLayer; Figure: TRFigure; Op: TOrderOperation);

    procedure Clear;

    function CreateOrderData: TRGroupOrderData;
  end;

  TRBaseGroupController = class(TRControllerEx)
  public
    function Group: TRGroup;
    function Supports(AObject: TObject): Boolean; override;
  end;

  TRSelectionGroup = class(TRGroup)
  public
    constructor Create; override;
    procedure UndoablyDelete(Layer: TRLayer); override;
    procedure Sort; virtual; abstract; 
  end;

  TRGroupOrderData = class
  public
    procedure RestoreOrder; virtual; abstract;
  end;

implementation

uses
  SysUtils, RGeom, RFigHlp, RUtils;

type

  TRGroupUndoPoint = class(TRUndoPoint)
  private
    FGroup: TRGroup;
    FUndoPoints: TObjectList;
  public
    constructor Create(AGroup: TRGroup; ASheet: TRSheet; ALayer: TRLayer; Aspects: TDataAspects);
    destructor Destroy; override;
    procedure Restore; override;
  end;

  TRGroupOrderDataImpl = class(TRGroupOrderData)
  private
    FGroup: TRGroup;
    FList: TList;
  public
    constructor Create(Group: TRGroup);
    procedure RestoreOrder; override;
    destructor Destroy; override;
  end;

  TRDeleteUndoPoint = class(TRUndoPoint)
  private
    FGroup: TRGroup;
    FList: TList;
    FOrderData: TRGroupOrderData;
  public
    constructor Create(ALayer: TRLayer; Group: TRGroup);
    procedure Add(Figure: TRFigure);
    procedure Restore; override;
    destructor Destroy; override;
  end;

  TRGroupOrderUndoPoint = class(TRUndoPoint)
  private
    FOrderData: TRGroupOrderData;
  public
    constructor Create(ALayer: TRLayer; Group: TRGroup);
    procedure Restore; override;
    destructor Destroy; override;
  end;

{-------------------------------- TRGroup -------------------------------------}

constructor TRGroup.CreateEx(AOwnsFigures: Boolean);
begin
  inherited Create;
  FOwnsFigures := AOwnsFigures;
  FFigures := TList.Create;
end;

constructor TRGroup.Create;
begin
  CreateEx(True); 
end;

destructor TRGroup.Destroy;
begin
  Clear;
  FFigures.Free;
  inherited;
end;

function TRGroup.GetCount: Integer;
begin
  Result := FFigures.Count
end;

function TRGroup.GetFigures(I: Integer): TRFigure;
begin
  Result := TRFigure(FFigures[I]);
end;

procedure TRGroup.SetFigures(I: Integer; AValue: TRFigure);
begin
  FFigures[I] := AValue;
end;

procedure TRGroup.InternalAdd(Figure: TRFigure);
begin
  if FFigures.IndexOf(Figure) = -1 then
    //FFigures.Add(Figure);
    FFigures.Insert(0, Figure);
end;

procedure TRGroup.InternalRemove(Figure: TRFigure);
begin
  FFigures.Remove(Figure);
end;

procedure TRGroup.Draw(Layer: TRLayer);
var i: Integer;
begin
  for i := Count-1 downto 0 do Layer.Draw(Figures[i]);
end;

procedure TRGroup.UndoablyDeleteFigure(Layer: TRLayer; Figure: TRFigure);
var u: TRDeleteUndoPoint;
begin
  u := TRDeleteUndoPoint.Create(Layer, Self);
  u.Add(Figure); // calls Remove(Figure);
  UndoStack(Layer.Sheet).Push(u);
end;

procedure TRGroup.MoveFigure(I, Pos: Integer);
begin
  with FFigures do
    if (I > -1)and(I < Count)and(Pos > -1)and(Pos < Count) then Move(I, Pos);
end;

procedure TRGroup.BringToFront(Figure: TRFigure);
begin
  MoveFigure(FFigures.IndexOf(Figure), 0);
end;

procedure TRGroup.SendToBack(Figure: TRFigure);
begin
  MoveFigure(FFigures.IndexOf(Figure), Count-1);
end;

procedure TRGroup.BackOne(Figure: TRFigure);
var i: Integer;
begin
  i := FFigures.IndexOf(Figure);
  MoveFigure(i, i+1);
end;

procedure TRGroup.ForwardOne(Figure: TRFigure);
var i: Integer;
begin
  i := FFigures.IndexOf(Figure);
  MoveFigure(i, i-1);
end;

procedure TRGroup.UndoablyChangeOrder(Layer: TRLayer; Figure: TRFigure; Op: TOrderOperation);
begin
  if Op = opChangeless then Exit;
  
  UndoStack(Layer.Sheet).Push(TRGroupOrderUndoPoint.Create(Layer, Self));
  case Op of
    opBringToFront: BringToFront(Figure);
    opSendToBack: SendToBack(Figure);
    opForwardOne: ForwardOne(Figure);
    opBackOne: BackOne(Figure);
  end;
end;

procedure TRGroup.Clear;
var i: Integer;
begin
  if OwnsFigures then
    for i := Count-1 downto 0 do Figures[i].Free;

  FFigures.Clear;
end;

function TRGroup.ContainingRect: TRectF;
var i, i0: Integer;
begin
  Result := EmptyRectF;
  if Count > 0 then
  begin
    i0 := Count; 
    for i := 0 to Count-1 do
      if Figures[i].Visible then
      begin
        i0 := i;
        Break;
      end;

    Result := TRFigureHelper(Figures[i0]).ContainingRect;

    for i := i0+1 to Count-1 do
      if Figures[i].Visible then
        Result := UnionRectF(Result, TRFigureHelper(Figures[i]).ContainingRect);

  end;
end;

function TRGroup.Transform(var Data: TTransformData): Boolean;
var i: Integer;
begin
  Result := True;
  for i := 0 to Count-1 do
    TRFigureHelper(Figures[i]).Transform(Data);
end;

function TRGroup.CreateOrderData: TRGroupOrderData;
begin
  Result := TRGroupOrderDataImpl.Create(Self);
end;

function TRGroup.HitTest(Layer: TRLayer; const Pt: TPointF): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to Count-1 do
    if Layer.HitTest(Figures[i], Pt) then
    begin
      Result := True;
      Break;
    end;
end;

function TRGroup.OwnsFigures: Boolean;
begin
  Result := FOwnsFigures;
end;

function TRGroup.Contains(Figure: TRFigure): Boolean;
begin
  Result := FFigures.IndexOf(Figure) > -1;
end;

function TRGroup.GetDeleteable: Boolean;
var i: Integer; 
begin
  Result := inherited GetDeleteable;
  for i := 0 to Count-1 do
    if not Figures[i].Deleteable then
    begin
      Result := False;
      Break;
    end;
end;

function TRGroup.CreateUndoPoint(ASheet: TRSheet; ALayer: TRLayer;
  Aspects: TDataAspects): TRUndoPoint;
begin
  Result := TRGroupUndoPoint.Create(Self, ASheet, ALayer, Aspects);
end;

procedure TRGroup.Serialize(Stream: TStream);
var i, N: Integer;
begin
  WriteSignatureToStream(Stream, GROUP_SIGNATURE);

  N := Count;
  Stream.WriteBuffer(N, SizeOf(N));
  Stream.WriteBuffer(FOwnsFigures, SizeOf(FOwnsFigures));

  //for i := 0 to Count-1 do
  for i := Count-1 downto 0 do
  begin
    TRFigureHelper(Figures[i]).Serialize(Stream);
  end;

  WriteSignatureToStream(Stream, GROUP_SIGNATURE);
end;

procedure TRGroup.Deserialize(Stream: TStream);
var i, N: Integer;
    fig: TRFigure;
begin
  ReadSignatureFromStream(Stream, GROUP_SIGNATURE, 'Group loading error');

  Stream.ReadBuffer(N, SizeOf(N));
  Stream.ReadBuffer(FOwnsFigures, SizeOf(FOwnsFigures));

  {!}Clear;

  for i := 0 to N-1 do
  begin
    fig := TRFigureHelper(nil).Deserialize(Stream);
    Add(fig);
  end;

  ReadSignatureFromStream(Stream, GROUP_SIGNATURE, 'Group loading error');
end;

function TRGroup.GetFigureOrderNumber(Figure: TRFigure): Integer;
begin
  Result := FFigures.IndexOf(Figure);
end;

{------------------------ TRBaseGroupController -------------------------------}

function TRBaseGroupController.Group: TRGroup;
begin
  Result := Controllee as TRGroup;
end;

function TRBaseGroupController.Supports(AObject: TObject): Boolean;
begin
  Result := AObject is TRGroup;
end;

{------------------------------ TRDeleteUndoPoint -----------------------------}

constructor TRDeleteUndoPoint.Create(ALayer: TRLayer; Group: TRGroup);
begin
  inherited Create(ALayer.Sheet, ALayer);
  FGroup := Group;
  FList := TList.Create;
  FOrderData := TRGroupOrderDataImpl.Create(FGroup);
end;

destructor TRDeleteUndoPoint.Destroy;
var i: Integer;
begin
  inherited;
  FOrderData.Free;
  for i := 0 to FList.Count-1 do TRFigure(FList[i]).Free;
  FList.Free;
end;

procedure TRDeleteUndoPoint.Add(Figure: TRFigure);
begin
  FList.Add(Figure);
  FGroup.Remove(Figure);
end;

procedure TRDeleteUndoPoint.Restore;
const Mode: array[Boolean]of TRSelectMode = (smNormal, smPlus);
var Figure: TRFigure;
    i: Integer;
begin
  for i := 0 to FList.Count-1 do
  begin
    Figure := TRFigure(FList[i]);
    FList[i] := nil;
    FGroup.Add(Figure);
  end;
  FOrderData.RestoreOrder;
end;

{------------------------------ TRSelectionGroup ------------------------------}

constructor TRSelectionGroup.Create;
begin
  inherited CreateEx(False);
  Style := Style + [fsServant];
end;

procedure TRSelectionGroup.UndoablyDelete(Layer: TRLayer);
var i: Integer;
    up: TRDeleteUndoPoint;
begin
  if not Deleteable then Exit; 

  up := TRDeleteUndoPoint.Create(Layer, Figures[0].Master as TRGroup);
  for i := 0 to Count-1 do up.Add(Figures[I]);
  UndoStack(Layer.Sheet).Push(up);
  Clear;
end;

{----------------------------- TRGroupUndoPoint ------------------------------}

constructor TRGroupUndoPoint.Create(AGroup: TRGroup; ASheet: TRSheet;
  ALayer: TRLayer; Aspects: TDataAspects);
var i: Integer;
    up: TRUndoPoint;
begin
  inherited Create(ASheet, ALayer);
  FGroup := AGroup;
  FUndoPoints := TObjectList.Create(True);
  for i := 0 to FGroup.Count-1 do
  begin
    up := GetUndoPoint(FGroup.Figures[i], nil{!}, nil{!}, Aspects);
    if Assigned(up) then FUndoPoints.Add(up);
  end;
end;

destructor TRGroupUndoPoint.Destroy;
begin
  FUndoPoints.Free;
  inherited;
end;

procedure TRGroupUndoPoint.Restore;
var i: Integer;
begin
  for i := 0 to FUndoPoints.Count-1 do
    TRUndoPoint(FUndoPoints[i]).Recover;
end;

{------------------------- TRGroupOrderDataImpl -------------------------------}

procedure CopyList(Src, Dest: TList);
var i: Integer;
begin
  //Dest.Assign(Src, laCopy);
  {D5}
  Dest.Count := 0;
  if Dest.Capacity < Src.Count then Dest.Capacity := Src.Count;
  for i := 0 to Src.Count-1 do Dest.Add(Src[i]);
end;

constructor TRGroupOrderDataImpl.Create(Group: TRGroup);
begin
  inherited Create;
  FGroup := Group;
  FList := TList.Create;
  CopyList(FGroup.FFigures, FList);
end;

destructor TRGroupOrderDataImpl.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TRGroupOrderDataImpl.RestoreOrder;
var i: Integer;
begin
  Assert(FGroup.FFigures.Count = FList.Count);
  for i := 0 to FList.Count-1 do Assert(FGroup.FFigures.IndexOf(FList[i]) > -1);

  CopyList(FList, FGroup.FFigures);
end;

{--------------------------- TRGroupOrderUndoPoint ----------------------------}

constructor TRGroupOrderUndoPoint.Create(ALayer: TRLayer; Group: TRGroup);
begin
  inherited Create(ALayer.Sheet, ALayer);
  FOrderData := TRGroupOrderDataImpl.Create(Group);
end;

destructor TRGroupOrderUndoPoint.Destroy;
begin
  FOrderData.Free;
  inherited;
end;

procedure TRGroupOrderUndoPoint.Restore;
begin
  FOrderData.RestoreOrder;
end;

end.
