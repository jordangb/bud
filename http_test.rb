require_relative 'lib/bud'

class Test
  include Bud

  state do
  	httpresp :hresp
  	httpreq :hreq, hresp

  end

  bloom do
    hreq <~ [['http://qmaker.zxq.net/qmakerfx/', 'get', 0, {'qid' => 3}]]
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











