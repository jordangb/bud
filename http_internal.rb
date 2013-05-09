require 'net/http'

def test()
	puts http_handle('http://posttestserver.com/post.php', 'Post', 4, {:handle => 'pull'})[0]
end

def http_handle(address, http_type, id, params)

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
		raise 'http_type:'+http_type+' is not supported'
	end
	if response == nil
		raise 'http request unsuccessful'
	end
	return address, http_type, id, response
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

test()









