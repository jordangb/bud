# -*- coding: utf-8 -*-
require 'rubygems'
require 'backports'
require 'bud'
require 'json'

module JSON
  def self.maybe_parse(string)
    begin
      retval = self.parse(string)
    rescue
      retval = {"type" => ["NO DATA"], "features" => ["NO DATA"]}
    end
    return retval
  end
end

class TwitterQuake
  include Bud

  state do
    httpresp :quake_response
    httpreq :quake_request, quake_response

    table :quakes, [:latitude, :longitude, :magnitude]
    table :seen_quakes, quakes.schema
    scratch :show_quake, quakes.schema
    scratch :dummy

    periodic :timer, 1.0
  end

  bloom do
    quake_request <~ [["http://earthquake.usgs.gov/earthquakes/feed/v0.1/summary/all_hour.json",
                       'GET', 1, []]]

    dummy <= quake_response do |r|
      data = JSON.maybe_parse(r[3])
      quakes <= data.map do |q|
        [q['latitude'], q['longitude'], q['magnitude']]
      end
      [[]] #kind of hackey, but it allows the quakes through without blowing up
    end
    show_quake <= quakes.notin(seen_quakes)
    seen_quakes <+ show_quake
    stdio <~ show_quake.inspected
    #stdio <~ [["#{JSON.maybe_parse(quake_response.to_a[0].to_a[3].to_s)['features'][0]['geometry']}"]]

  end

end

tq = TwitterQuake.new

tq.run_fg