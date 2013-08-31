package com.force.oauth
{
	public class OAuthConfigParam
	{
		private var key_name:String;
		private var client_key:String;
		private var client_secret:String;
		private var call_back_url:String;
		private var call_back_state:String;
		
		public function get name():String {
			return this.key_name;
		}
		
		public function set name(v:String):void {
			this.key_name = v;
		}
		
		public function get clientKey():String {
			return this.client_key;
		}
		
		public function set clientKey(v:String):void {
			this.client_key = v;
		}
		
		public function get clientSecret():String {
			return this.client_secret;
		}
		
		public function set clientSecret(v:String):void {
			this.client_secret = v;
		}
		
		public function get callbackUrl():String {
			return this.call_back_url;
		}
		
		public function set callbackUrl(v:String):void {
			this.call_back_url = v;
		}
		
		public function get state():String {
			return this.call_back_state
		}
		
		public function set state(v:String):void {
			this.call_back_state = v;
		}
		
		public function OAuthConfigParam()
		{
		}
		
		public function keys():Object {
			var keys:Object = new Object();
			keys['name'] = this.name;
			keys['client_key'] = this.client_key;
			keys['client_secret'] = this.client_secret;
			keys['call_back_url'] = this.call_back_url;
			keys['state'] = this.state;
			return keys;
		}
	}
}