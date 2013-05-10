require_relative 'lib/bud'

class Test
  include Bud

  state do
  	httpresp :hresp
  	httpreq :hreq, hresp

  end

  bloom do
  	http_request <~ [['http://qmaker.zxq.net/qmakerfx/?qid=3', 'get', 99, []]]
  	stdio <~ http_response.inspected
    hreq <~ [['http://qmaker.zxq.net/qmakerfx/?qid=3', 'get', 0, []]]
    stdio <~ hresp.inspected
  end

end

def test()
	t = Test.new
	t.tick
	t.tick
	sleep(3.0)
	t.tick
	t.tick
	t.tick
end

test()









