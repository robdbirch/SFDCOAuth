package com.force.oauth
{
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;

	public class OAuthRemoteServices
	{
		// Which SFDC organiztion to use
		static public var sfdcServer:String = null;
		
		//--------------------------------------------------------------------------------
		// OAuth Types: 
		//              agent - this is where the agent after login captures the redirect 
		//                      with the access code and directly gets the access token 
		//                      from the salesforce auth server
		//             mobile - Used for mobile browsers, **NOT TESTED*** 
		//              web   - this is where the agent lets the web handle both the
		//                      token on login and refresh, this is very close to how a
		//                      web based client works. **NOT YET IMPLEMENTED**
		//--------------------------------------------------------------------------------
		static public var oAuthType:String = "agent";
		
		//--------------------------------------------------------------------------------
		// Remote Service - only used when auth type is "agent"
		// The remote service is used when the client/agent performs login
		// and then registers the token with the collaborative server and 
		// then when a refresh is needed it makes a request to the collaborative 
		// server for the refresh token
		//--------------------------------------------------------------------------------
		static  public var remoteService:Boolean = false;
		
		private var tokenInfo:Object;
		private var apiToken:String = '"d"';
		private var regUrlDev:String = "https://a.com/sfdc_register_token_info";
		private var regUrlProd:String = "https://a.com/sfdc_register_token_info";
		private var refreshUrlDev:String = "https://a.com/sfdc_refresh_token_request";
		private var refreshUrlProd:String = "https://a.com/sfdc_refresh_token_request";
		private var registerUrl:String = regUrlProd;
		private var refreshUrl:String = refreshUrlProd;
		private var oauth:OAuthConnection;
		
		public function OAuthRemoteServices(pOauth:OAuthConnection)
		{
			this.oauth = pOauth;
		}
		
		public function registerOAuth(pTokenInfo:Object):void {
			this.tokenInfo = pTokenInfo;
			var service:HTTPService = new HTTPService(); 
			service.contentType = "application/json";
			service.headers["Authorization"] = "Token token=" + this.apiToken;
			service.method = "POST"; 
			service.url = this.registerUrl;
			var msg:String = JSON.stringify(this.tokenInfo);
			trace("Registering User with service:" + msg);
			service.addEventListener("result", httpRegisterResult); 
			service.addEventListener("fault", httpRegisterFault); 
			service.send(msg); 
		}
		
		public function httpRegisterResult(event:ResultEvent):void { 
			var result:Object = JSON.parse(event.result as String);
			trace("Successfully Registered: " + event.result.toString());
			var json:Object = JSON.parse(event.result.toString());
			this.oauth.loginClientCallback.result(json);
		}
		
		public function httpRegisterFault(event:FaultEvent):void {
			var faultstring:String = event.fault.faultString; 
			this.traceNetworkError(event);
			this.oauth.loginClientCallback.fault(event.fault.faultDetail);
		}
		
		public function refreshOAuth():void {
			var service:HTTPService = new HTTPService(); 
			service.contentType = "application/json";
			service.headers["Authorization"] = "Token token=" + this.apiToken;
			service.method = "GET"; 
			service.url = this.refreshUrl + "?sfdc_user_id=" + this.oauth.sfdcId;
			trace("Refresh Request with Service with SFDC user: " +  this.oauth.sfdcId);
			service.addEventListener("result", this.oauth.refreshResultHandler); 
			service.addEventListener("fault", this.oauth.refreshFaultHandler); 
			service.send();
		}

		private function traceNetworkError(event:FaultEvent):void {
			var faultstring:String = event.fault.faultString; 
			trace ("Register failed status code: " + event.statusCode.toString());
			trace ("Register failed message: " + event.message);
			trace("Failed to  register OAuth::Token Info: " + faultstring); 
		}
	}
}