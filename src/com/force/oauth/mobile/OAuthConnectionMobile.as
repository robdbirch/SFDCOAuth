package com.force.oauth.mobile
{
	import com.force.oauth.OAuthConnection;

	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.LocationChangeEvent;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	
	public class OAuthConnectionMobile extends OAuthConnection
	{
		private var oauthView:StageWebView;
		
		public function OAuthConnectionMobile(_publicKey:String, _privateKey:String, _redirectURI:String) {
			super(_publicKey, _privateKey, _redirectURI);
		}
		
		protected override function showLogin(Stage:flash.display.Stage = null):void {
			if(Stage == null) { return; }
			mobileBrowserShow(Stage);
			StageWebView(this.oauthView).loadURL(oauthURI
											    + this.salesforceAuthService
												+ "?display=touch"
												+ "&response_type=code"
												+ "&client_id="
												+ this.publicKey
												+ "&redirect_uri="
												+ redirectURI
			);
		}
		
		private function mobileBrowserShow(Stage:flash.display.Stage):void {
			var rect:Rectangle = new Rectangle(Stage.width/2 - 240,Stage.height/2 - 240,480,480);
			if(this.oauthView == null) {
				this.oauthView = new StageWebView();
				this.oauthView.addEventListener(LocationChangeEvent.LOCATION_CHANGE,getCode);
				this.oauthView.addEventListener(ErrorEvent.ERROR,getCode);
				StageWebView(this.oauthView).stage = Stage;
				StageWebView(this.oauthView).viewPort = rect;
			}
		}
		
		protected override function removeBrowser():void {
			if(this.oauthView != null && this.oauthView.stage != null) {
				this.oauthView.stage = null;
			}
		}
		
		protected override function getCode(event:LocationChangeEvent):void {
			trace(StageWebView(this.oauthView).location);
			if (! this.hasCode() ) { return; }
			var authCode:String = unescape(StageWebView(oauthView).location.substring(StageWebView(this.oauthView).location.indexOf("code=")+5, StageWebView(oauthView).location.length));
			removeBrowser();			
			requestAccessToken(authCode);
		}
	}
}