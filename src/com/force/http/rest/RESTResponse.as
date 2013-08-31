package com.force.http.rest
{
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	public class RESTResponse
	{
		public var callback:IResponder;
		
		public function RESTResponse(_callback:IResponder)
		{
			this.callback = _callback;
		}
		
		public function resultHandler(event:ResultEvent):void {
			var result:Object;
			trace("Network Result handler event type: " + typeof(event.result));
			trace("Network Result handler event result: " + ObjectUtil.toString(event.result));
			trace("Network Result handler status code: " + event.statusCode.toString());
			
			try {
				switch(typeof(event.result)) {
					case "object": 
						trace("RESTResponse: Calling client callback event result type object");
						this.callback.result(event.result); //probably a file, let's just send it back
						return;
					case "string": 
						if(event.result.toString() == "") {
							trace("RESTResponse: Calling client callback event result type *empty* string");
							this.callback.result(new Object());
							return;
						}
						result = JSON.parse(event.result.toString()); //probably JSON, let's pull the records into a JSON object and send bac
						if(result.records != null) {result = result.records;}
						trace("RESTResponse: Calling client callback event result type string");
						this.callback.result(result);
				}
			} catch(e:Error) {
				trace("HTTP Rest Response Success had an error in processing the message: "+ e.message);
				this.callback.fault("HTTP Rest Response Success had an error in processing the message: "+ e.message);
			}	
		}
		
		public function faultHandler(event:FaultEvent):void {
			trace('Rest Response Error Handler!');
			trace("Fault string: " + event.fault.faultString);
			trace("Fault event: " + ObjectUtil.toString(event));
			this.callback.fault(event);
		}
	}
}