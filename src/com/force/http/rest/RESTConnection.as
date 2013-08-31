package com.force.http.rest
{
	import com.force.http.HTTPStayFresh;
	import com.force.http.rest.RESTResponse;
	import com.force.oauth.OAuthConnection;
	
	import flash.net.URLRequestMethod;
	
	import mx.rpc.IResponder;
	
	public class RESTConnection
	{
		private var oauthConnection:OAuthConnection;
		public var api:String = "21.0";
		
		private var client_callback:IResponder;
		private var oauth_refresh_callback:IResponder;
		
		public function RESTConnection(conn:OAuthConnection) {
			this.oauthConnection = conn;
		}
		
		public function get oauth():OAuthConnection{
			return this.oauthConnection
		}

		public function query(soql:String, _callback:IResponder):void {
			var headers:Object = new Object();
			this.setOAuthHeaders(headers);
			var method:String = "GET";
			var url:String = this.oauthConnection.instanceUrl + "/services/data/v"+api+"/query?q="+soql;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url,httpCallback);
			trace("Query sent:"+soql);
		}
		
		//SDW to Support Chatter Posts
		public function sendChatterObject(url:String,created:Object, type:String, _callback:IResponder):void {
			var headers:Object = new Object();
			setOAuthHeaders(headers);
			var method:String = "POST";
			var url:String = this.oauthConnection.instanceUrl + url;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url,httpCallback,false,JSON.stringify(created),false);
			trace("Chatter Create sent:" + JSON.stringify(created));
		}
		
		public function create(created:Object, type:String, _callback:IResponder):void {
			var headers:Object = new Object();
			setOAuthHeaders(headers);
			var method:String = "POST";
			var url:String = oauthConnection.instanceUrl + "/services/data/v"+api+"/sobjects/"+type+"/";
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url,httpCallback,false, JSON.stringify(created),false);
			trace("Create sent:"+ JSON.stringify(created));
		}
		
		public function update(updated:Object, id:String, type:String, _callback:IResponder):void {
			var headers:Object = new Object();
			setOAuthHeaders(headers);
			var method:String = "POST";
			var url:String = this.oauthConnection.instanceUrl + "/services/data/v"+api+"/sobjects/"+type+"/"+id;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url+"?_HttpMethod=PATCH",httpCallback,false, JSON.stringify(updated),false);
			trace("Updated sent:"+ JSON.stringify(updated));
		}
		
		public function getObjectById(type:String, id:String, _callback:IResponder):void {
			var headers:Object = new Object();
			var method:String = "GET";
			setOAuthHeaders(headers);
			var url:String = this.oauthConnection.instanceUrl + "/services/data/v"+api+"/sobjects/"+type+"/"+id;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url,httpCallback);
			trace("Get Object By ID sent");
		}
		
		public function deleteObjectById(type:String, id:String, _callback:IResponder):void {
			var headers:Object = new Object();
			var method:String = "GET";
			setOAuthHeaders(headers);
			headers["X-HTTP-Method-Override"] = URLRequestMethod.DELETE;
			var url:String = oauthConnection.instanceUrl + "/services/data/v"+api+"/sobjects/"+type+"/"+id;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url	,httpCallback);
			trace("Delete sent");
		}
		
		public function getObjectByURI(uri:String, _callback:IResponder):void {
			var headers:Object = new Object();
			var method:String = "GET";
			setOAuthHeaders(headers);
			var url:String = this.oauthConnection.instanceUrl + uri;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection,headers,method,url,httpCallback);
			trace("Get Object By URI sent");
		}
		
		public function getFileByURI(uri:String, _callback:IResponder):void {
			var headers:Object = new Object();
			var method:String = "GET";
			setOAuthHeaders(headers);
			var url:String = this.oauthConnection.instanceUrl + uri;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url,httpCallback,true);
			trace("Get File By URI Sent");
		}
		
		//SDW
		public function getFileByRawURI(uri:String, _callback:IResponder):void {
			var headers:Object = new Object();
			var method:String = "GET";
			setOAuthHeaders(headers, false);
			var url:String = uri;
			var response:RESTResponse = new RESTResponse(_callback);
			var httpCallback:IResponder = new mx.rpc.Responder(response.resultHandler,response.faultHandler);
			HTTPStayFresh.send(oauthConnection, headers,method,url,httpCallback,true);
			trace("Get File By Raw URI Sent");
		}
		
		private function setOAuthHeaders(headers:Object, json:Boolean=true):void {
			if ( json) { headers["Authorization"] = "OAuth "+this.oauthConnection.token; }
			headers["Accept"] = "application/json";
		}
		
	}
}