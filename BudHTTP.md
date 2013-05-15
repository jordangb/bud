# Bud HTTP Documentation

### Overview:
We introduced two new Bud Collections, BudHTTPRequest and BudHTTPResponse. These collections work in tandem in that http requests are sent to an instance of BudHTTPRequest and then the HTTP response is sent to the associated BudHTTPResponse. Note that the BudHTTPResponse must be created first so that the BudHTTPRequest instance can be associated with it upon instantiation. We also created the methods httpresp(name) and httpreq(name, http_response_interface) for creating BudHTTPResponse and BudHTTPRequest instances respectively in the state table. These methods are located in state.rb and the collections are located in collections.rb.

### Code Example:
    state do
      httpresp :http_response
      httpreq :http_request, http_response
    end

    bloom do
      http_request <~ [[‘http://www.google.com’, ‘GET’, 1, []]]
      stdio <~ http_response.inspected
      # stdio would print out something like [“http://www.google.com”, “GET”, 1, “a bunch of html...”]
    end

### Protocol:
* httpreq has a pre-defined schema that cannot be altered. It is:
    **[to_address, http_type, id, params, parsing_function]**
    * **to_address** is the address for the HTTP request to be sent to.
    * **http_type** is the type of HTTP request to be made. This can be one of the following: ‘GET’, ‘PUT’, ‘POST’, ‘DEL’
    * **id** is the user-defined id to track the http_request
    * **params** is a hash of the query parameters to be passed with the request i.e.:
	{‘query_variable1’ => ‘value1’, ‘query_variable2’ => ‘value2’}
    * **parsing_function** is an optional user-created parsing function that can be passed into the request that will automatically parse the response. This needs to be done via a lambda function i.e.: lambda{|resp| return ‘~~~’+resp}.
        * If the parsing_function is left empty, the response will be returned in its original form.
* httpresp has a pre-defined schema that cannot be altered. It is:
		**[from_address, http_type, id, response]**
    * **from_address** is the address that the HTTP request was sent to.
    * **http_type** is the type of HTTP request that was made. This can be one of the following: ‘GET’, ‘PUT’, ‘POST’, ‘DEL’
    * **id** is the user-defined id to track the http_request
    * **response** is the response received from the HTTP request
        * if a parsing_function was specified in the request, this will be parsed according to the function. Otherwise it will be in its original form.

All HTTP requests made through this code are asynchronous and most likely will not finish execution by the next tick. Once the response is received, it is passed immediately to the httpresp instance associated with the httpreq instance that sent the request. Because of this asynchronous behavior, for tests that do not run indefinitely, the script may need to sleep after the request is sent and then begin ticking again after the response is received for it to propagate through the pipeline.