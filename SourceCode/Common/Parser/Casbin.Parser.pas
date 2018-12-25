unit Casbin.Parser;

interface

uses
  Casbin.Core.Base.Types, Casbin.Parser.Types, Casbin.Core.Logger.Types, Casbin.Parser.AST.Types;

type
  TParser = class (TBaseInterfacedObject, IParser)
  private
    fLogger: ILogger;
    fErrorMessage: string;
    fParseString: string;
    fParseType: TParseType;
    fStatus: TParserStatus;
    fNodes: TNodeCollection;
    procedure cleanWhiteSpace;
    procedure checkSyntaxErrors;
  private
{$REGION 'Interface'}
    function getErrorMessage: string;
    function getLogger: ILogger;
    function getParseType: TParseType;
    procedure parse;
    procedure setLogger(const aValue: ILogger);
    function getStatus: TParserStatus;
    function getNodes: TNodeCollection;
{$ENDREGION}
  public
    constructor Create(const aParseString: string; const aParseType: TParseType);
    destructor Destroy; override;
  end;
implementation

uses
  Casbin.Core.Logger.Default, System.IniFiles, System.Classes,
  Casbin.Core.Defaults, Casbin.Core.Strings, System.StrUtils, System.AnsiStrings;

constructor TParser.Create(const aParseString: string; const aParseType:
    TParseType);
begin
  inherited Create;
  fParseString:=aParseString;
  fParseType:=aParseType;
  fLogger:=TDefaultLogger.Create;
  fStatus:=psIdle;
  fNodes:=TNodeCollection.Create;
end;

destructor TParser.Destroy;
begin
  fNodes.Free;
  inherited;
end;

procedure TParser.checkSyntaxErrors;
var
  insideHeader: Boolean;
  ch: Char;
  fileString: string;
  numLSquare: integer;
  posX: Integer;
  posY: Integer;
  strList: TStringList;
begin
  case fParseType of
    ptModel: fileString:=modelFileString;
    ptPolicy: fileString:=policyFileString;
    ptConfig: fileString:=configFileString;
  end;

  insideHeader:=False;
  numLSquare:=0;
  posX:=Low(string);
  posY:=1;
  for ch in fParseString do
  begin
    case ch of
      '[': if insideHeader then
           begin
             fErrorMessage:=format(errorWrongHeaderFormat, [PosX, PosY, fileString]);
             fStatus:=psError;
             Exit;
           end
           else
           begin
            insideHeader:=True;
            Inc(numLSquare);
           end;
      ']': begin
             insideHeader:=False;
             if numLSquare = 0 then
             begin
               fErrorMessage:=format(errorWrongHeaderFormat, [PosX, PosY, fileString]);
               fStatus:=psError;
               Exit;
             end;
           end;
    end;
    if SameText(Copy(fParseString, posX, Length(EOL)), EOL) then
    begin
      posX:=Low(string);
      Inc(posY);
    end
    else
      Inc(posX);
  end;

  // If there is no section in the beginning add the default
  // to keep the parser happy
  strList:=TStringList.Create;
  try
    strList.Text:=fParseString;
    if (strList.Count>0) and (strList.Strings[0][Low(string)]<>'[') then
      fParseString:='['+DefaultSection+']'+EOL+fParseString;
  finally
    strList.Free;
  end;
end;

procedure TParser.cleanWhiteSpace;
var
  index: integer;
  assignmentIndex: integer;
  testStr: string;
begin
  // Clean multiline chars
  index:= Pos(DefaultMultilineCharacters, fParseString, Low(string));
  while index<>0 do
  begin
    testStr:=Copy(fParseString, index+Length(DefaultMultilineCharacters),
                                                                  Length(EOL));
    if testStr=EOL then
      Delete(fParseString, index+Length(DefaultMultilineCharacters),
                                                                  Length(EOL));
    Delete(fParseString, index, Length(DefaultMultilineCharacters));
    index:= Pos(DefaultMultilineCharacters, fParseString, Low(string));
  end;

  // Clean tabs
  index:= Pos(#9, fParseString, Low(string));
  while index<>0 do
  begin
    Delete(fParseString, index, 1);
    index:= Pos(#9, fParseString, Low(string));
  end;

  // Clean spaces (not in Config file if spaces are in values
  index:= Pos(#32, fParseString, Low(string));
  while index<>0 do
  begin
    if fParseType=ptConfig then
    begin
      assignmentIndex:=Pos(AssignmentCharForConfig, fParseString, Low(string));
      if (assignmentIndex<>0) and (assignmentIndex>index) then
        Delete(fParseString, index, 1)
      else
        Break;
    end
    else
      Delete(fParseString, index, 1);
    index:= Pos(#32, fParseString, Low(string));
  end;
end;

{ TParser }

function TParser.getErrorMessage: string;
begin
  Result:=fErrorMessage;
end;

function TParser.getLogger: ILogger;
begin
  Result:=fLogger;
end;

function TParser.getNodes: TNodeCollection;
begin
  Result:=fNodes;
end;

function TParser.getParseType: TParseType;
begin
  Result:=fParseType;
end;

function TParser.getStatus: TParserStatus;
begin
  Result:=fStatus;
end;

procedure TParser.parse;
begin
  fErrorMessage:='';
  fNodes.Headers.Clear;
  fStatus:=psRunning;
  fLogger.log('Parser started');


  fLogger.log('Cleaning whitespace...');
  cleanWhiteSpace;
  fLogger.log('Cleaning of whitespace finished');

  if fStatus<>psError then
  begin
    fLogger.log('Checking for Syntax Errors...');
    checkSyntaxErrors;
    fLogger.log('Syntax error check completed');

    if fStatus<>psError then
    begin
      fLogger.log('????');

    end;
  end;
  if fStatus=psError then
  begin
    fLogger.log('Error while parsing: '+fErrorMessage+EOL+'Parsing faield');
  end
  else
    fStatus:=psIdle;

  fLogger.log('Parser finished');
end;

procedure TParser.setLogger(const aValue: ILogger);
begin
  fLogger:=aValue;
end;

end.
