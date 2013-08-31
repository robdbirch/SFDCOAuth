package com.force.http
{
	import com.force.oauth.OAuthConnection;
	
	import mx.messaging.ChannelSet;
	import mx.rpc.IResponder;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	//-----------------------------------------------------------------------------
	// This class will attempt a REST network request to salesforce. If the request
	// fails due to OAuth token expiration it will then get a new access token
	// and retry the call with the new token. 
	//-----------------------------------------------------------------------------
	public class HTTPStayFresh
	{
		private var oauthConnection:OAuthConnection;
		private var headers:Object;
		private var method:String;
		private var uri:String; 
		private var clientCallback:IResponder; 
		private var isBinary:Boolean = false;
		private var postObject:Object = null;
		
		public function HTTPStayFresh(pOauthConnection:OAuthConnection,
									  pHeaders:Object,
									  pMethod:String, 
									  pUri:String, 
									  pCallback:IResponder, 
									  pIsBinary:Boolean = false, 
									  pPostObject:Object = null
		                              )
		{
			this.oauthConnection = pOauthConnection;
			this.headers =  pHeaders;
			this.method = pMethod;
			this.uri = pUri;
			this.clientCallback = pCallback;
			this.isBinary = pIsBinary;
			this.postObject = pPostObject;
		}
		
		//-----------------------------------------------------------------------------
		//  Handle initial network request callbacks
		//-----------------------------------------------------------------------------
		// If the call succeedes with current token we will call the client(calling) callback
		//-----------------------------------------------------------------------------
		public function originalCallResultHandler(event:ResultEvent):void {
			this.clientCallback.result(event);
		}
		
		//-----------------------------------------------------------------------------
		// If the call fails due to the oauth access token being stale:
		//           401 HTTP status code and a JSON-encoded body of:
		//           [{ message: 'Session expired or invalid', errorCode: 'INVALID_SESSION_ID'}]
		//
		// then we will attempt one call for a refreshed token
		// if it's any other error we will call the client fault callback
		//-----------------------------------------------------------------------------
		
		private function isRefresh(event:FaultEvent):Boolean {
			var retCd:Boolean = false;
			if ( event.statusCode == 401 ) {					
				if ( typeof(event.fault.content) == "string") {
					if(event.fault.toString() != "") {
						var body:Object = JSON.parse(event.fault.content.toString());
						if ( body[0].errorCode == 'INVALID_SESSION_ID' ) {
							var refreshCallback:IResponder = new mx.rpc.Responder(this.refreshCallResultHandler, this.refreshCallFaultHandler);
							this.oauthConnection.refreshRequest(refreshCallback);
							retCd = true;
						}
					}
				}
			}
			return retCd;
		}
		
		public function originalCallFaultHandler(event:FaultEvent):void {
			if (! isRefresh(event) ) {
				this.clientCallback.fault(event);
			}
		}
		
		//-----------------------------------------------------------------------------
		// On a successful refresh we will resubmit the request with the 
		// the new token and the clients orginal callbacks and keep fresh false
		//-----------------------------------------------------------------------------
		public function refreshCallResultHandler(event:ResultEvent):void {
			this.headers["Authorization"] = "OAuth "+this.oauthConnection.token;
			HTTPStayFresh.send(this.oauthConnection,
						this.headers,
						this.method,
						this.uri,
						this.clientCallback,
						this.isBinary,
						this.postObject,
						false);
		}
		
		//-----------------------------------------------------------------------------
		// On a refresh failure we will call the calling client error callback
		//-----------------------------------------------------------------------------
		public function refreshCallFaultHandler(event:FaultEvent):void {
			this.clientCallback.fault(event.fault);
		}
		
		public static function send(oauthConnection:OAuthConnection, 
									headers:Object, 
									method:String, 
									uri:String, 
									callback:IResponder, 
									isBinary:Boolean = false, 
									postObject:Object = null,
									keepFresh:Boolean = true				
									):void 
		{
				var http:HTTPService = new HTTPService();
				http.requestTimeout = 120; // For debugging purposes
				var stayFresh:HTTPStayFresh = null;
				trace ("HTTP request with auto refresh enable as: " + keepFresh);
				if (keepFresh) {
					stayFresh = new HTTPStayFresh(oauthConnection, headers, method, uri, callback, isBinary, postObject);
					var sfCallback:IResponder = new mx.rpc.Responder(stayFresh.originalCallResultHandler, stayFresh.originalCallFaultHandler);
					http.addEventListener(ResultEvent.RESULT, sfCallback.result);
					http.addEventListener(FaultEvent.FAULT,  sfCallback.fault);
				} else {
					http.addEventListener(ResultEvent.RESULT, callback.result );
					http.addEventListener(FaultEvent.FAULT, callback.fault );
				}
				
				http.method = method;
				trace("HTTP request method: " + http.method);
				http.headers = headers;
				http.url = uri;
				trace("HTTP request uri: " + http.url);
				
				if(isBinary) {
					http.resultFormat = "e4x";
					var dcs:ChannelSet = new ChannelSet();
					var binaryChannel:DirectHTTPBinaryChannel = new DirectHTTPBinaryChannel("direct_http_binary_channel");
					dcs.addChannel(binaryChannel);            
					http.channelSet = dcs;
				}
				
				if(postObject != null) { 
					if(typeof(postObject) == "string") { http.contentType = "application/json; charset=UTF-8"; }
					http.send(postObject); 
					trace("Sent post object: "+ postObject); 
				} else {
					http.send();
				}
				trace("HTTP Rest Request Sent");
		}
	}
}