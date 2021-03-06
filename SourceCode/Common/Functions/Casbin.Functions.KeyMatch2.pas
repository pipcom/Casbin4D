/// <summary>
///   Determines whether key1 matches the pattern of key2
///   (as in REST paths)
///   key2 can contain '*'
///   eg. '/foo/bar' matches '/foo/*'
///       '/resource1' matches '/:resource'
/// </summary>
function KeyMatch2 (const aArgs: array of string): Boolean;
var
  key1: string;
  key2: string;
  regExp : TRegEx;
  match : TMatch;
begin
  if Length(aArgs)<>2 then
    raise Exception.Create('Wrong number of arguments in KeyMatch2');
  key1:=aArgs[0];
  key2:=aArgs[1];

  key2:=StringReplace(key2, '/*', '/.*', [rfReplaceAll]);

  while Pos('/:', key2, low(string))<>0 do
  begin
    key2:=TRegEx.Replace(key2, '(.*):[^/]+(.*)', '$1[^/]+$2');
    key2:='^'+key2+'$';
  end;

  regExp:=TRegEx.Create(key2);
  match := regExp.Match(key1);
  Result:= match.Success;

end;
