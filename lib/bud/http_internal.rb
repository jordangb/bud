require 'net/http'

# This is the method that the httpreq calls to handle the http requests passed to it.
# It determines the type of HTTP request made and issues that request. It then passes
# back the HTTP response. If parse_function is not specified, the response message
# will be unaltered otherwise the response message will be parsed according to the
# specified lambda function. If there is not a successful HTTP response, an error is
# raised that specifies that the request is not successful.
def http_handle(address, http_type, id, params, parse_function=nil)

	case http_type
	when 'GET', 'Get', 'get'
		response = http_req(Net::HTTP::Get, address, params)
	when 'PUT', 'Put', 'put'
		response = http_req(Net::HTTP::Put, address, params)
	when 'DEL', 'Del', 'del', 'DELETE', 'Delete', 'delete'
		response = http_req(Net::HTTP::Delete, address, params)
	when 'POST', 'Post', 'post'
		response = http_post(address, params)
	else
		raise 'ERROR: http_type: '+http_type+' is not supported. Accepted HTTP types are: GET, PUT, DEL, POST.'
	end

	if response == nil
		raise 'ERROR: HTTP '+ http_type+' request to '+address+' was unsuccessful.'
	end

	if parse_function == nil
		return address, http_type, id, default_parse(response)
	else
		return address, http_type, id, parse_function.call(response)
	end
end

#Post requires a different method for some reason
def http_post(url, params)
	uri = URI(url)
	res = Net::HTTP.post_form(uri, params)
	if res.is_a?(Net::HTTPSuccess)
		return res.body
	else
		return nil
	end
end

#Makes the get, put, or delete http requests and returns the response if the
#request is successful. Otherwise it returns nil.
def http_req(type, url, params)
	uri = URI(url)
	http = Net::HTTP.new(uri.host, uri.port)
	uri.query = URI.encode_www_form(params)
	response = http.request(type.new(uri.request_uri))
	if response.is_a?(Net::HTTPSuccess)
		return response.body
	else
		return nil
	end
end

def default_parse(string_response)
	#todo
	#Doesn't do anything right now.
	#Here in case default parsing wants to be implemented in the future
	return string_response
end

