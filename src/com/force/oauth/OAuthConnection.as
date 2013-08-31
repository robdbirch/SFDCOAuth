package com.force.oauth
{
	import com.force.http.HTTPConnection;
	import com.force.http.rest.RESTConnection;
	import com.force.oauth.mobile.OAuthConnectionMobile;
	import com.force.oauth.OAuthRemoteServices;
	import com.force.oauth.OAuthConfig;
	
	import flash.data.EncryptedLocalStore;
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.LocationChangeEvent;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	public class OAuthConnection
	{
		protected var publicKey:String; 
		protected var privateKey:String;
		protected var redirectURI:String; 
		protected var oauthURI:String = "https://login.salesforce.com";
		protected var salesforceAuthService:String = "/services/oauth2/authorize";
		protected var display:String ="touch";
		protected var authCodeResponseType:String = "code";
		
		private var oauthView:DisplayObject;
		private var oauthToken:String;
		private var oauthRefreshToken:String;
		private var instance_url:String;
		private var id_url:String;
		private var issued_at:int;
		private var scope:String;
		private var signature:String;
		private var sfdc_id:String;
		private var sfdc_org:String;
		private var remoteServices:Boolean = true;
		private var oauthType:String;
		private var state:String;

		private var credStoreKey:String = 'sfdc-login';
		private var loggedIn:Boolean = false;
		
		internal var loginClientCallback:IResponder;
		internal var refreshClientCallback:IResponder;
		
		public static function set sfdcOrgConfigParam(configParamName:String):void {
			OAuthRemoteServices.sfdcServer = configParamName
		}
		
		public static function get sfdcOrgConfigParam():String {
			return OAuthRemoteServices.sfdcServer
		}
		
		public function OAuthConnection(_publicKey:String, _privateKey:String, _redirectURI:String) {
			this.publicKey = _publicKey;
			this.privateKey = _privateKey;
			this.redirectURI = _redirectURI;
		}

		// Convience function to get a rest connection with this OAuth
		public function rest():com.force.http.rest.RESTConnection {
			var rest:RESTConnection = new RESTConnection(this);
			return rest; 
		}

		public function get token():String {
			return this.oauthToken	
		}

		public function get instanceUrl():String {
			return this.instance_url 
		}
		
		public function get idUrl():String {
			return this.id_url;	
		}
		
		public function get authIssuedAt():int {
			return this.issued_at;	
		}
		
		public function get authSignature():String {
			return this.signature;
		}
		
		public function get authScope():String {
			return this.scope;
		}
		
		public function get authState():String {
			return this.state;
		}

		public function get sfdcId():String {
			return this.sfdc_id;
		}
		
		public function get sfdcOrg():String {
			return this.sfdc_org;
		}
		
		public function isLoggedIn():Boolean {
			return this.loggedIn;	
		}
		
		public function usingRemoteService():Boolean {
			return this.remoteServices;
		}
		
		public function enableRemoteServices():void {
			this.remoteServices = true;
		}
		
		public function disableRemoteServices():void {
			this.remoteServices = false;
		}
		
		public function deleteCredentials():void {
			EncryptedLocalStore.removeItem(this.credStoreKey);
		}
		
		protected function set loginCallback(cb:IResponder):void {
			this.loginClientCallback = cb;
		}
		
		protected function set refreshCallback(cb:IResponder):void {
			this.refreshClientCallback = cb;
		}
		
		//-------------------------------------------------------------------------------------------------------
		// Login Process
		// This might be moved outside into a Login object
		//-------------------------------------------------------------------------------------------------------
		static public function login(Stage:flash.display.Stage = null, loginHandler:IResponder = null):OAuthConnection {
			var oauth:OAuthConnection = null;
			var c:Object = null;
			trace("Login OAuth Type: " + OAuthRemoteServices.oAuthType);
			trace("Login into Salesforce server: " + OAuthRemoteServices.sfdcServer);
			if ( OAuthRemoteServices.oAuthType == "agent" ) {
				oauth = OAuthConnection.agentOAuth();
			} else if ( OAuthRemoteServices.oAuthType == "mobile" ) {
				oauth = OAuthConnection.mobileOAuth();
			} else {
				oauth = OAuthConnection.webOAuth();
			}
			oauth.loginClientCallback = loginHandler;
			oauth.remoteServices = OAuthRemoteServices.remoteService;
			oauth.selectCredentials(Stage);
			trace("OAuth type: " + oauth.oauthType);
			trace("OAuth state: " + oauth.state);
			trace("OAuth remote services: " + oauth.remoteServices);
			return oauth;
		}

		static private function agentOAuth():OAuthConnection {
			var keys:Object = OAuthConfig.getServerKeys(OAuthRemoteServices.sfdcServer);
			var oauth:OAuthConnection = new OAuthConnection(keys.clientKey, keys.clientSecret, keys.callbackUrl);
			oauth.oauthType = "agent";
			oauth.state = keys['state'];
			return oauth;
		}
		
		static private function mobileOAuth():OAuthConnection {
			var keys:Object = OAuthConfig.getServerKeys(OAuthRemoteServices.sfdcServer);
			var oauth:OAuthConnection  = new OAuthConnectionMobile(keys.clientKey, keys.clientSecret, keys.callbackUrl);
			oauth.oauthType = "mobile";
			oauth.state = keys['state'];
			return oauth;
		}
		
		static private function webOAuth():OAuthConnection {
			var oauth:OAuthConnection;
			throw new ArgumentError("Web OAuth not implemented yet!");
			//oauth.oauthType = "web";
			return oauth
		}
		
		private function selectCredentials(Stage:flash.display.Stage = null):void {
			var c:Object = this.readCredentials();
			if ( c == null ) {
				this.showLogin(Stage);
			} else {
				this.restoreCredentialsObject(c);
				this.loggedIn = true;
			}
		}

		// This function is used by login and refresh
		internal function setTokenInfoMembers(tokenInfoJson:Object):void {
			this.oauthToken = tokenInfoJson.access_token;
			this.instance_url = tokenInfoJson.instance_url;
			this.issued_at = tokenInfoJson.issued_at;
			this.scope = tokenInfoJson.scope;
			this.signature = tokenInfoJson.signature;
			this.id_url = tokenInfoJson.id;
		}
		
		private function build_login_uri():URLRequest {
			var uri:String = this.oauthURI 
								+ this.salesforceAuthService
			                    + "?display="
			                    + this.display
								+ "&response_type="
			                    + this.authCodeResponseType
								+ "&client_id="
								+ this.publicKey
								+ "&state=" 
								+ this.state
								+ "&redirect_uri="
								+ this.redirectURI;
			return new URLRequest(uri);
		}
		
		protected function showLogin(Stage:flash.display.Stage = null):void {
			if(Stage == null) { return; }
			showBrowser(Stage);
			trace("Sending Salesforce login request");
			var url:URLRequest = this.build_login_uri();
			trace("Loading Salesforce login view");
			HTMLLoader(this.oauthView).load(url);
		}

		protected function removeBrowser():void {
			if(this.oauthView != null && this.oauthView.parent != null) {
				this.oauthView.parent.removeChild(this.oauthView);
			}
		}
		
		protected function showBrowser(Stage:flash.display.Stage = null):void {
			trace("Creating browser");
			var rect:Rectangle = new Rectangle(0,0,400,600);
			if(this.oauthView == null) {
				this.oauthView = new HTMLLoader();
				this.oauthView.addEventListener(LocationChangeEvent.LOCATION_CHANGE, getCode);
				this.oauthView.height = rect.height;
				this.oauthView.width = rect.width;
				this.oauthView.x = rect.x;
				this.oauthView.y = rect.y;
				Stage.addChild(this.oauthView);
			}
		}
		
		protected function hasCode():Boolean {
			trace("Location Change: " + HTMLLoader(oauthView).location);
			if(HTMLLoader(oauthView).location.indexOf("code=") < 0) {
				return false;
			} else {
				return true;
			}
		}

		protected function getCode(event:LocationChangeEvent):void {
			if (! this.hasCode() ) { return; }
			var authCode:String = unescape(HTMLLoader(oauthView).location.substring(HTMLLoader(oauthView).location.indexOf("code=")+5, HTMLLoader(oauthView).location.length));
			// remove end parameters!!!
			var sa:Array = authCode.split(/&/);
			authCode = sa[0]
			removeBrowser();			
			requestAccessToken(authCode);
		}
		
		protected function requestAccessToken(authCode:String):void {		
			var headers:Object = new Object();
			var method:String  = "POST";
			headers["code"] = authCode;
			headers["grant_type"] = "authorization_code";
			headers["client_id"] = this.publicKey;
			headers["client_secret"] = this.privateKey;
			headers["redirect_uri"] = this.redirectURI;
			headers["Accept"] = "application/json";
			var url:String = oauthURI + "/services/oauth2/token";
			var callback:IResponder = new mx.rpc.Responder(loginResultHandler,loginFaultHandler);
			HTTPConnection.send(headers,"POST",url,callback,false,headers,false);
		}
		
		private function checkNetworkAuthError(json:Object, event:ResultEvent, pCallback:IResponder):void {
			if (json == null) {
				pCallback.fault({message:'Please try again later and relogin'});
			}
		}
		
		private function setSfdcIdOrg(id:String):void {
			var pattern:RegExp = /^https:\/\/([^\/]+)\/id\/([^\/]+)\/(.*)/;
			var p:Array = pattern.exec(id);
			this.sfdc_id = p[3];
			this.sfdc_org = p[2];
		}
			
		private function loginResultHandler(event:ResultEvent):void {
			var tokenInfoJson:Object;
			trace("Login Result:"+ ObjectUtil.toString(event));
			tokenInfoJson = JSON.parse(event.result.toString());
			var regJson:Object = ObjectUtil.clone(tokenInfoJson);
			checkNetworkAuthError(tokenInfoJson, event, this.loginClientCallback);
			setSfdcIdOrg(tokenInfoJson.id);
			tokenInfoJson['sfdc_org']= this.sfdc_org;
			tokenInfoJson['sfdc_id'] = this.sfdc_id;
			this.oauthRefreshToken = tokenInfoJson.refresh_token;
			setTokenInfoMembers(tokenInfoJson);
			this.loggedIn = true;
			this.storeCredentials();
			if ( this.remoteServices ) {
				var ors:OAuthRemoteServices = new OAuthRemoteServices(this);
				ors.registerOAuth(regJson);
			} else {
				var json:Object = new Object();
				json["eid"] = null;
				json["uid"] = null;
				json["token_in_use"] = this.token;
				this.loginClientCallback.result(json);
			}
			removeBrowser();
		}
		
		private function loginFaultHandler(event:FaultEvent):void {
			traceNetworkError(event);
			if(event.fault.faultDetail != null) {this.loginClientCallback.fault(event.fault.faultDetail);}
			removeBrowser();
		}

		//-------------------------------------------------------------------------------------------------------
		// Refresh Process
		//-------------------------------------------------------------------------------------------------------
		public function refreshRequest(callback:IResponder = null):void {
			this.refreshClientCallback = callback;
			this.requestRefreshToken();
		}
		
		private function requestRefreshToken():void {
			if ( this.remoteServices ) {
				var ors:OAuthRemoteServices = new OAuthRemoteServices(this);
				ors.refreshOAuth();
			} else {
				this.directRefreshRequest();
			}
		}
		
		private function directRefreshRequest(): void {
			trace("getting new refresh token");
			var headers:Object = new Object();
			var method:String  = "POST";
			headers["refresh_token"] = oauthRefreshToken;
			headers["grant_type"] = "refresh_token";
			headers["client_id"] = publicKey;
			headers["client_secret"] = privateKey;
			headers["redirect_uri"] = redirectURI;
			headers["Accept"] = "application/json";
			headers["Cache-Control"] = "no-cache, no-store, must-revalidate";
			var url:String = oauthURI + "/services/oauth2/token";
			var callback:IResponder = new mx.rpc.Responder(refreshResultHandler, refreshFaultHandler);
			HTTPConnection.send(headers,"POST",url,callback,false,headers,false);
		}
		
		internal function refreshResultHandler(event:ResultEvent):void {
			var json:Object;
			trace("Refresh result:"+ObjectUtil.toString(event));
			json = JSON.parse(event.result.toString());
			checkNetworkAuthError(json, event, this.refreshClientCallback);
			setTokenInfoMembers(json);
			this.storeCredentials();
			var tokenStorage:Object;
			this.refreshClientCallback.result(event);
		}
		
		internal function refreshFaultHandler(event:FaultEvent):void {
			traceNetworkError(event);
			if(event.fault.faultDetail != null) {
				this.refreshClientCallback.fault(event.fault.faultDetail);
			}
		}
		
		
		//-------------------------------------------------------------------------------------------------------
		// Local Credential Store
		//-------------------------------------------------------------------------------------------------------
		private function storeCredentials():void {
			var c:Object = this.getCredentialsObject();
			trace ("Storing credentials: " + ObjectUtil.toString(c));
			var bc:ByteArray = new ByteArray();
			bc.writeObject(c);
			EncryptedLocalStore.setItem(this.credStoreKey, bc)
		}
		
		private function getCredentialsObject():Object {
			var c:Object = new Object;
			c['refresh_token'] = this.oauthRefreshToken;
			c['access_token'] = this.oauthToken;
			c['instance_url'] = this.instance_url;
			c['id'] = this.id_url;
			c['issued_at'] = this.issued_at;
			c['scope'] = this.scope;
			c['signature'] = this.signature;
			c['sfdc_id'] = this.sfdc_id;
			c['sfdc_org'] = this.sfdc_org;
			c['oauthType'] = this.oauthType;
			c['remoteServices'] = this.remoteServices;
			c['state'] = this.state;
			return c;
		}
		
		private function readCredentials():Object {
			var c:Object = null;
			var ba:ByteArray = EncryptedLocalStore.getItem(this.credStoreKey);
			if ( ba != null ) {	
				c = ba.readObject();	
			}
			trace ("Read credentials: " + ObjectUtil.toString(c));
			return c;
		}
		
		private function restoreCredentialsObject(c:Object):void {
			this.oauthRefreshToken = c['refresh_token']; 
			this.oauthToken = c['access_token']; 
			this.instance_url = c['instance_url'];
			this.id_url = c['id']; 
			this.issued_at = c['issued_at'];
			this.scope = c['scope']; 
			this.signature = c['signature'];
			this.sfdc_id = c['sfdc_id']; 
			this.sfdc_org = c['sfdc_org']; 
			this.oauthType = c['oauthType']; 
			this.remoteServices = c['remoteServices']; 
			this.state = c['state']; 
		}
		
		private function traceNetworkError(event:FaultEvent):void {
			var faultstring:String = event.fault.faultString; 
			trace ("Register failed status code: " + event.statusCode.toString());
			trace ("Register failed message: " + event.message);
			trace("Failed to register OAuth::Token Info: " + faultstring); 
		}
		
	}
}