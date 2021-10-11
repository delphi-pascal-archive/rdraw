{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RIntf;

interface

uses Classes, RTypes;

type

  IResizeable = interface
  ['{B8E122E8-84A4-4307-8ADC-A3A19586A211}']
    function Length: Integer;
    //function AllowResize: Boolean;
    procedure Resize(Count: Integer);
    procedure MoveBlock(SourcePos, DestPos, Count: Integer);
  end;

  TDataAspect = (daGeometry, daAttributes, daPicture, daText, daLinks, daOther);
  TDataAspects = set of TDataAspect;

  IStreamable = interface
  ['{CA32F12F-0CC0-4458-9811-9F36AD41DBCB}']
    procedure SaveDataToStream(Stream: TStream; Aspects: TDataAspects);
    procedure LoadDataFromStream(Stream: TStream; Aspects: TDataAspects);
  end;

  ISerializeable = interface
  ['{159E2C9D-2B78-4FB2-B8AA-A63DFD6861D5}']
    procedure Serialize(Stream: TStream);
    procedure Deserialize(Stream: TStream);
  end;

  ICloneable = interface
  ['{D6C02278-A1B1-42FA-8964-15A1D7ED6DD0}']
    function Clone: TObject;
  end;

  IPropertyPage = interface
  ['{827A805E-7504-4344-AC81-77D5A7E414AD}']
    function Show: Boolean;
  end;

  ILinkable = interface
    procedure Add(Obj: TObject);
    procedure Remove(Obj: TObject);
  end;

const
  CLASS_SIGNATURE: Integer = $200C1A55;
  GROUP_SIGNATURE: Integer = $200C2009;

  daAll = [daGeometry, daAttributes, daPicture, daText, daLinks, daOther];

implementation

end.

