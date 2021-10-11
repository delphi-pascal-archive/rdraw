unit _myCrv;

interface

uses
  RCore, RTypes, RCurve, RIntf, _attr;

type
  TMyCurve = class(TRCurve, IResizeable, IDrawingAttributes)
  private
    FAttributes: TRDrawingAttributes;
    FPoints: array of TPointF;
  protected
    function  GetX(I: Integer): Double; override;
    procedure SetX(I: Integer; const Value: Double); override;
    function  GetY(I: Integer): Double; override;
    procedure SetY(I: Integer; const Value: Double); override;
  public
    constructor CreateEx(PointCount: Integer);
    constructor Create; override;
    destructor Destroy; override;

    procedure PrepareDraw(Layer: TRLayer; Element: TRCurveElement); override;

    function  Length: Integer; override;
    procedure Resize(Count: Integer); virtual;
    procedure MoveBlock(SourcePos, DestPos, Count: Integer); virtual;

    function Attributes: TRDrawingAttributes;

    procedure Add(const Pt: TPointF);
    procedure AddXY(X, Y: Double);

    procedure Insert(const Pt: TPointF; Position: Integer);

    procedure Clear; 
  end;

implementation

uses
  RCrvHlp;

{ TMyCurve }

constructor TMyCurve.CreateEx(PointCount: Integer);
var i: Integer;
begin
  inherited Create;
  SetLength(FPoints, PointCount);

  for i := 0 to PointCount-1 do
    FPoints[i] := PointF(i, i);

  FAttributes := TRDrawingAttributes.Create;
end;


constructor TMyCurve.Create;
begin
  CreateEx(0);
end;

destructor TMyCurve.Destroy;
begin
  FAttributes.Free; 
  inherited;
end;

function TMyCurve.Length: Integer;
begin
  Result := System.Length(FPoints);
end;

function TMyCurve.GetX(I: Integer): Double;
begin
  Result := FPoints[i].X;
end;

function TMyCurve.GetY(I: Integer): Double;
begin
  Result := FPoints[i].Y;
end;

procedure TMyCurve.MoveBlock(SourcePos, DestPos, Count: Integer);
begin
  Move(FPoints[SourcePos], FPoints[DestPos], Count*SizeOf(FPoints[0]));
end;

procedure TMyCurve.Resize(Count: Integer);
begin
  SetLength(FPoints, Count);
end;

procedure TMyCurve.SetX(I: Integer; const Value: Double);
begin
  FPoints[i].X := Value;
end;

procedure TMyCurve.SetY(I: Integer; const Value: Double);
begin
  FPoints[i].Y := Value;
end;

procedure TMyCurve.Add(const Pt: TPointF);
var L: Integer;
begin
  L := Length;
  Resize(L+1);
  FPoints[L] := Pt;
end;

procedure TMyCurve.AddXY(X, Y: Double);
begin
  Add( PointF(X, Y) );
end;

procedure TMyCurve.PrepareDraw(Layer: TRLayer; Element: TRCurveElement);
begin
  inherited;
  case Element of
    ceSegment:
    begin
      FAttributes.Apply(Layer);
    end;
    ceArea:
    begin
      FAttributes.Apply(Layer);
    end;
  end;
end;

function TMyCurve.Attributes: TRDrawingAttributes;
begin
  Result := FAttributes;
end;

procedure TMyCurve.Insert(const Pt: TPointF; Position: Integer);
var i: Integer;
begin
  i := TRCurveHelper(Self).InsertBlock(Position, 1);
  FPoints[i] := Pt;
end;

procedure TMyCurve.Clear;
begin
  SetLength(FPoints, 0);
end;

end.
