{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: other                                        *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit IdxList;

interface

uses
  Classes{, IntFn};

type

  TIndexList = class(TList)
  private
    function GetI(Index: Integer): Integer;
    procedure SetI(Index: Integer; const AValue: Integer);
    function GetFirstI: Integer;
    function GetLastI: Integer;
    function GetSingleI: Integer;
    procedure SetSingleI(AValue: Integer);
  protected
    property Items[Index: Integer]: Integer read GetI write SetI;
  public
    //function GetArray: TIntArrayAdapter;
    procedure Sort;

    procedure Add(AIndex: Integer);
    procedure Remove(AIndex: Integer);
    procedure Insert(I: Integer; AIndex: Integer);
    function FindIndex(AIndex: Integer): Integer;

    property Indexes[Index: Integer]: Integer read GetI write SetI; default;
    property Singular: Integer read GetSingleI write SetSingleI;
    {$WARNINGS OFF}
    property First: Integer read GetFirstI;
    property Last: Integer read GetLastI;
    {$WARNINGS ON}
    function Init(AIndex: Integer): TIndexList; overload;
    function Init(AIndexes: array of Integer): TIndexList; overload;
    //function Init(AIndexes: TIntArrayAdapter): TIndexList; overload;
  end;

implementation

{uses
  StdAlgs;}

{----------- TIndexList ---------}

function TIndexList.GetI(Index: Integer): Integer;
begin
  Result := Integer(inherited Items[Index]);
end;

procedure TIndexList.SetI(Index: Integer; const AValue: Integer);
begin
  inherited Items[Index] := Pointer(AValue);
end;

procedure TIndexList.Add(AIndex: Integer);
begin
  inherited Add( Pointer(AIndex) );
end;

procedure TIndexList.Remove(AIndex: Integer);
begin
  inherited Remove( Pointer(AIndex) );
end;

procedure TIndexList.Insert(I, AIndex: Integer);
begin
  inherited Insert( I, Pointer(AIndex) );
end;

function TIndexList.FindIndex(AIndex: Integer): Integer;
begin
  Result := inherited IndexOf( Pointer(AIndex) );
end;

function TIndexList.GetFirstI: Integer;
begin
  try
    Result := Integer(inherited First);
  except
    Result := -1;
  end;
end;

function TIndexList.GetLastI: Integer;
begin
  try
    Result := Integer(inherited Last);
  except
    Result := -1;
  end;
end;

function TIndexList.GetSingleI: Integer;
begin
  if Count = 1
    then Result := Indexes[0]
    else Result := -1;
end;

procedure TIndexList.SetSingleI(AValue: Integer);
begin
  Clear;
  Add(AValue);
end;

function TIndexList.Init(AIndex: Integer): TIndexList;
begin
  SetSingleI(AIndex);
  Result := Self;
end;

function TIndexList.Init(AIndexes: array of Integer): TIndexList;
var i: Integer;
begin
  Result := Self;
  SetCount(Length(AIndexes));
  for i := Low(AIndexes) to High(AIndexes) do SetI(i, AIndexes[i]);
end;

{
function TIndexList.Init(AIndexes: TIntArrayAdapter): TIndexList;
var i: Integer;
begin
  Result := Self;
  SetCount(AIndexes.Length);
  for i := 0 to AIndexes.Length-1 do SetI(i, AIndexes.Get(i));
end;

function TIndexList.GetArray: TIntArrayAdapter;
begin
  Result := IntArrayAdapter(Count, GetI, SetI);
end;
}

function _Cmp(Item1, Item2: Pointer): Integer;
begin
  Result := Integer(Item1) - Integer(Item2);
end;

procedure TIndexList.Sort;
begin
  //SortArray(GetArray);
  {$IFDEF FPC}
  inherited Sort(@_Cmp);
  {$ELSE}
  inherited Sort(_Cmp);
  {$ENDIF}
end;

end.
