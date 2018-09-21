with AWS.Client;
with AWS.Response;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNATCOLL.JSON; use GNATCOLL.JSON;
with Dict;

package body Connection is
   function Create (Config : JSON_Value) return Matrix is
   begin
      return Matrix'(Base_Url => + (Config.Get ("address")),
		     Username => + (Config.Get ("username")),
		     Password => + (Config.Get ("password")),
		     Room     => + (Config.Get ("room")),
		     Access_Token => +""
		    );
   end Create;

   function Build_Url (Self : Matrix;
		       Endpoint : String;
		       Parameters : Params.Map;
		       Version : String)
		      return String is
      Url : String := To_String (Self.Base_Url) & "/_matrix/client/" &
	Version & "/" & Endpoint;
      -- need to copy in case it's an empty map
      P : Params.Map := Parameters.Copy;
   begin
      if Length (Self.Access_Token) > 0 then
	 P.Include ("access_token", To_String (Self.Access_Token));
      end if;

      if not P.Is_Empty then
	 Url := Url & "?";
	 -- final trailing & on the url might be ok to leave in
	 for K in Parameters.Iterate loop
	    Url := Url & Params.Key (K) & "=" & P (K) & "&";
	 end loop;
      end if;

      return Url;
   end Build_Url;

   function POST (Self : Matrix;
		  Endpoint : String;
		  Data : Dict.Items;
		  Parameters : Params.Map := Params.Empty_Map;
		  Version : String := "unstable")
		 return JSON_Value is
      Url : String := Self.Build_Url (Endpoint, Parameters, Version);
      Response : AWS.Response.Data := AWS.Client.Post (Url,
						       Dict.To_Json (Data),
						       "application/json");
   begin
      return GNATCOLL.JSON.Read (String'(AWS.Response.Message_Body (Response)));
   end POST;

   function GET (Self : Matrix;
		 Endpoint : String;
		 Parameters : Params.Map := Params.Empty_Map;
		 Version : String := "unstable")
		return JSON_Value is
      Result : JSON_Value := Create_Object;
   begin
      return Result;
   end GET;

   function Login (Self : Matrix) return JSON_Value is
      Data : Dict.Items :=
	((+"user", Create (To_String (Self.Username))),
	 (+"password", Create (To_String (Self.Password))),
	 (+"type", Create ("m.login.password")));
      Result : JSON_Value := Self.POST("login", Data);
   begin
      return Result;
   end Login;
end Connection;