package com.force.http.rest
{
	public class RESTRequest
	{
		public var type:String;
		public var params:Array;
		
		public function RESTRequest(_type:String,_params:Array)
		{
			this.type = _type;
			this.params = _params;
		}
		
		
	}
}