# Salesforce OAuth 2.0 authentication
This is a based on [joshbirk/Flex-RESTKit](https://github.com/joshbirk/Flex-RESTKit). 

FlexBuilder 4.7 was used

* AIR SDK 3.4
* FLEX SDK 4.6.0

This version supports standard _agent_ based OAuth.
There are configuration facilities for working with multipled orgs during development and testing.

## Usage  OAuth
    
    private function login():void {
        // Identify which sfdc org to use in the configuration
        OAuthRemoteServices.sfdc  = "orgDemo12";
	    this.oauth = OAuthConnection.login(win.stage,
						   new mx.rpc.AsyncResponder(loginSuccess, logingError));
    }

    private function loginSuccess(loginResult:Object, token:Object):void {
        // Do Stuff
    }
     
## Quick REST Examples

There is a REST helper method to return a *new* rest object that holds a reference to the oauth.

	 rest = this.oauth.rest();
     
### Query
     rest.query("SELECT ID, Name from Contact LIMIT 5",
                 new mx.rpc.AsyncResponder(querySuccess, queryError));
			
     private function querySuccess(queryResult:Array, token:Object):void {
         // Do stuff with queryResult
     	}

### Get Object By Id
     rest.getObjectById(“Account”,
                        ”{ACCOUNTID}”,
                         new mx.rpc.Responder(handleSuccess, handleError));

     private function handleSuccess(result:Object,token:Object):void {
     	trace(result.Name);
     }

### Creating data

     var newContact:Object = new Object();
     newContact.FirstName = "Jane";
     newContact.LastName = "Jones";
     rest.create(newContact,
                 "Contact",
                 new AsyncResponder(handleSuccess, handleError));

### Updating data
     oldContact.FirstName = "Jane";
     oldContact.LastName = "Smith";
     rest.create(oldContact,
                 "Contact",
                 new AsyncResponder(handleSuccess, handleError));
        
__Check com.force.http.rest.RESTConnection for more delete/files/Chatter Posts request interfaces__
     
There are property methods on the `OAuthConnection` in order to get Salesforce.com specific information

        public function get sfdcId():String 
        public function get sfdcOrg():String
        public function get token():String 
        public function get instanceUrl():String 
        public function usingRemoteService():Boolean
        public function get idUrl():String
        public function get authIssuedAt():int
        public function get authSignature():String
        public function get authScope():String

## OAuth Configuration
[joshbirk/Flex-RESTKit](https://github.com/joshbirk/Flex-RESTKit) Had a nice constructor where you passed in the 
client key, client secret, and callback. For now that's gone. Configuration parmater objects (`OAuthConfigParam `) representing Salesforce Orgs OAuth paramaters are registed them with a `OAuthConfig` object. Some example stubb code is provided below
 
1. Create a config builder and place your SFDC Orgs. You may wish to __add that class to your .gitignore__ file so it doesn't get checked into the git repository.

            package com.force.oauth
            {
            	import com.force.oauth.OAuthConfig;
            	import com.force.oauth.OAuthConfigParam;
	
            	public class OAuthConfigBuilder
            	{
            		public static function build():void {
                        
            			var param:OAuthConfigParam = new OAuthConfigParam();
                        
            			param.name = 'orgDemo12';
            			param.clientKey = '3M...';
            			param.clientSecret = '9...';
            			param.callbackUrl = 'https://a.com/sfdc_oauth_callback';
            			param.state = 'eid-12demo';
            			OAuthConfig.registerConfig(param);
                        
                        param = new OAuthConfigParam();
            			param.name = 'orgDemo22';
            			param.clientKey = '3M...';
            			param.clientSecret = '9...';
            			param.callbackUrl = 'https://a.com/sfdc_oauth_callback';
            			param.state = 'eid-12demo';
            			OAuthConfig.registerConfig(param);
                        .
                        .
                        .
            		}
            	}
            }
            
2.  Be sure in your initialization code to invoke the builder

    OAuthConfigBuilder.build();
    

3. Also you can utilize onInvoke to create different run profiles in the FlashBuilder IDE for each of the orgs

            //--------------------------------------------------------------------------------
            // Command line arguments
            // -s serverName - the server name identifies which client key and secret to use
            //--------------------------------------------------------------------------------
            private function onInvoke(e:InvokeEvent):void {
            	var i:int = 0;
            	for (i=0; i < e.arguments.length; i++) {
            		trace("Command line arg: " + i + " value: " + e.arguments[i]);  
            		if (e.arguments[i] == "-s") { 
            			OAuthRemoteServices.sfdcServer = e.arguments[i+1];
            		}
            	}

Add 
invoke="onInvoke(event)"
or
NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);

For more info: [AIR Tip 7 – Using Command Line Arguments](http://archive.davidtucker.net/2008/01/23/air-tip-7-using-command-line-arguments/#)

Also see the contained example test application for details.

## Changes from [joshbirk/Flex-RESTKit](https://github.com/joshbirk/Flex-RESTKit)
* Native `actionscirpt 3.0 JSON` support
* Removal of Utils


#### OAuth Token Refresh 
OAuth tokens expire. The OAuth specification *recommends* using an `expires_in` parameter to indicate when to refresh an authentication token. Salesforce.com **does not** use an `expires_in` parameter. When a Salesforce.com token expires an HTTP status of `401  Unauthorized` is returned with the body containing the following:

         [{ message: 'Session expired or invalid', errorCode: 'INVALID_SESSION_ID'}]

#####  Refresh  [joshbirk/Flex-RESTKit](https://github.com/joshbirk/Flex-RESTKit) 
The *joshbirk* implementation attempted to avoid this response by asking for a new refresh token every *10 minutes*. I wanted to cut down  on this network chatter a bit.  It seems the Salesforce.com OAuth token may last for many hours depending on time of day, day of the week and possibliy other parameters determined by SFDC. 

##### New Refresh Implementation
This will only ask for a fresh token when the token has expired. When the token expires it will automatically call for a refreshed token. 

## Miscellaneous

### Not Tested
* Mobile OAuth




