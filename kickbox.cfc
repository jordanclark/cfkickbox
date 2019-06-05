component {

	function init(
		required string apiKey
	,	string apiUrl= "https://api.kickbox.com/v2"
	,	numeric httpTimeOut= 5
	,	boolean debug= ( request.debug ?: false )
	) {
		this.apiKey= arguments.apiKey;
		this.apiUrl= arguments.apiUrl;
		this.httpTimeOut= arguments.httpTimeOut;
		this.debug= arguments.debug;
		this.validate= this.verify;
		return this;
	}

	function debugLog(required input) {
		if ( structKeyExists( request, "log" ) && isCustomFunction( request.log ) ) {
			if ( isSimpleValue( arguments.input ) ) {
				request.log( "kickbox: " & arguments.input );
			} else {
				request.log( "kickbox: (complex type)" );
				request.log( arguments.input );
			}
		} else if( this.debug ) {
			cftrace( text=( isSimpleValue( arguments.input ) ? arguments.input : "" ), var=arguments.input, category="kickbox", type="information" );
		}
		return;
	}

	struct function verify( required string email ) {
		this.debugLog( "verify from Kickbox" );
		var req= this.apiRequest( uri= "GET /verify", email= arguments.email );
		return req;
	}

	struct function apiRequest( required string uri ) {
		var http= {};
		var item= "";
		var x= 0;
		var out= {
			success= false
		,	url= this.apiUrl & listRest( arguments.uri, " " )
		,	verb= listFirst( arguments.uri, " " )
		,	error= ""
		,	status= ""
		,	statusCode= 0
		,	response= ""
		};
		var paramVerb= ( out.verb == "GET" ? "url" : "formfield" );
		arguments.apikey= this.apikey;
		structDelete( arguments, "uri" );
		this.debugLog( "#out.verb# #out.url#" );
		if ( this.debug ) {
			this.debugLog( duplicate( arguments ) );
			this.debugLog( out );
		}
		cfhttp( result="http", method=out.verb, url=out.url, charset="utf-8", throwOnError=false, timeOut=this.httpTimeOut ) {
			for ( param in arguments ) {
				if ( isArray( arguments[ param ] ) ) {
					for ( x in arguments[ param ] ) {
						cfhttpparam( name=lCase( param ), type=paramVerb, value=x );
					}
				} else if ( isSimpleValue( arguments[ param ] ) ) {
					cfhttpparam( name=lCase( param ), type=paramVerb, value=arguments[ param ] );
				}
			}
		}
		// debugLog( http );
		out.response= toString( http.fileContent );
		// this.debugLog( out.response );
		out.statusCode = http.responseHeader.Status_Code ?: 500;
		this.debugLog( out.statusCode );
		if ( out.statusCode == "401" ) {
			//  unauthorized 
			out.success= false;
		} else if ( out.statusCode == "422" ) {
			//  unprocessable 
			out.success= false;
		} else if ( out.statusCode == "500" ) {
			//  server error 
			out.success= false;
		} else if ( listFind( "4,5", left( out.statusCode, 1 ) ) ) {
			//  unknown error 
			out.success= false;
		} else if ( out.statusCode == "" ) {
			//  donno 
			out.success= false;
		} else if ( out.statusCode == "200" ) {
			//  out.success 
			out.success= true;
		}
		//  parse response 
		try {
			if ( left( http.responseHeader[ "Content-Type" ], 16 ) == "application/json" ) {
				out.response= deserializeJSON( out.response );
			} else {
				out.error= "Invalid response type: " & http.responseHeader[ "Content-Type" ];
			}
		} catch (any cfcatch) {
			out.error= "JSON Error: " & cfcatch.message;
		}
		if ( len( out.error ) ) {
			out.success= false;
		}
		return out;
	}

}
