require 'rubygems'
require 'bud'

class Stocks
  include Bud

state do
  httpresp :http_response
  httpreq :http_request, http_response

  table :stockList, [:id] => [:stock] # :stock is the ticker symbol, i.e. GOOG for Google
  table :convert, http_request.schema

  table :formatted, [:id] => [:stock,:price]
  scratch :currentPrice, formatted.schema

end

  bloom do

    convert <= stockList do |e|
    	["http://dev.markitondemand.com/Api/quote?symbol=#{e.stock}", 'post', e.id, []]
    end

    http_request <~ convert

    formatted <= http_response do |e|
    	# Id of the request
    	id = e[2]
    	# Extracts the Stock Symbol
    	sym = e[3].scan(/<Symbol>(.*)<\/Symbol>/im).flatten.first
    	# Extracts the Stock Price
    	price = e[3].scan(/<LastPrice>(.*)<\/LastPrice>/im).flatten.first
    	
    	[id, sym, price]
    end

    # Only show the most recent ticker price. This assumes monotonically increasing ids.
    currentPrice <= formatted.argmax([:stock], :id) do |e|
    	[e.id, e.stock, e.price]
    end

    stdio <~ currentPrice.inspected

  end
end

showStocks = Stocks.new
time_between_ticks = 5 # this may need to be larger depending on the time it takes to get a response from the REST API
# otherwise it may refuse the connection
i = 0
while i < 7
	puts "-----UPDATING TICKER INFO------" if i > 2
	# Pass into the stockList Collection a format of [id, stock]
	showStocks.sync_do { showStocks.stockList <+ [[i, 'AAPL'], [i+10, 'GOOG']] }
	sleep(time_between_ticks) # We sleep as fetching data from the REST stock api takes time. 
  # may need to sleep longer depending on connection speed
	i+=1
end