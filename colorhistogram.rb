# colorhistogram.rb
# encoding: UTF-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra/base'
require 'RMagick'
require 'open-uri'
require 'json'
require 'thin'

class ColorHistogram < Sinatra::Base
	include Magick

	configure do
		# maximum number of colors to fetch
		set :max_colors, 5
		set :protection, :except => :path_traversal
	end

	# 404 handler
  not_found do
    error 404
  end

	# default handler
	get '/image/*' do
		@h = {}
		@message = ""

		@url = params[:splat].first
		if !@url.nil? 
			@h = get_histogram(@url)
		else
			@message = "Please provide an image url to fetch!"
		end	
		erb :image
	end

	# json handler
	get '/image.json/*' do
		content_type :json

		url = params[:splat].first

		if !url.nil?
			h = get_histogram(url)
			h.to_json
		else
			"Please provide an image url to fetch!"
		end
	end

	# takes an image url and returns a new 1-row image that has a column for every
	# 	color (to the maximum number of colors needed)
	def get_histogram(url)
		begin 
			max_colors = settings.max_colors
			image = Magick::ImageList.new 
			h = {}

			uri = URI.parse(url)

			uri.open { |f|
				image.from_blob(f.read)

				total_pixels = image.columns * image.rows
				hist = image.quantize(256, Magick::RGBColorspace).color_histogram
				hist = Hash[hist.sort_by { |k,v| -v }[0..max_colors - 1]]

				pixels = hist.each {|pixel, value|
					h[pixel.to_color(Magick::AllCompliance, false, 8, true)] = (value/total_pixels.to_f * 100).round(2)
				}
			}		
			return h
		rescue
			raise 
		end
	end

	# start the server if this ruby file is run directly
	run! if app_file == $0
end

