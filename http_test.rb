require_relative 'lib/bud'

class Test
  include Bud

  state do
  	
  end

  bloom do
  	http_request <~ [['http://www.cnn.com', 'get', 2, []],['http://www.google.com', 'get', 3, []]]
  	stdio <~ http_response.inspected
  end

end

def test()
	t = Test.new
	t.tick
	t.tick
	sleep(7.0)
	t.tick
	t.tick
	t.tick
end

test()









