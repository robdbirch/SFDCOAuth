package com.force.oauth
{
	public class OAuthConfig
	{
		private static var config:Object = new Object();
		
		public function OAuthConfig()
		{
		}
		
		public static function registerConfig(param:OAuthConfigParam):void {
			OAuthConfig.config[param.name] = param;
		}
		
		public static function getServerKeys(sfdcServer:String):Object {
			var c:Object = null;
			for (var key:Object in OAuthConfig.config) {
				if (key == sfdcServer ) {
					c = OAuthConfig.config[key];
					break;
				}
			}
			return c;
		}
	}
}