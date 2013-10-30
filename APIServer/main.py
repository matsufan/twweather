#!/usr/bin/env python
# encoding: utf-8

"""

Copyright (c) 2009-2010 Weizhong Yang (http://zonble.net)

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
"""

import os
import wsgiref.handlers
import datetime
import weather
import plistlib
import json
import urllib

from google.appengine.ext import webapp
from google.appengine.api import memcache
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app

import device

def add_record(request):
	device_id = request.get("device_id")
	if len(device_id) == 0:
		return
	device_name = request.get("device_name")
	device_model = request.get("device_model")
	app_name = request.get("app_name")
	app_version = request.get("app_version")
	os_name = request.get("os_name")
	os_version = request.get("os_version")
	note = request.get("note")

	access_date = datetime.datetime.now()

	current_device = device.Device.get_or_insert(device_id, device_id=device_id)
	current_device.device_name = device_name
	current_device.device_model = device_model
	current_device.app_name = app_name
	current_device.app_version = app_version
	current_device.os_name = os_name
	current_device.os_version = os_version
	current_device.access_date = access_date
	current_device.note = note
	current_device.put()
	pass

class WarningController(webapp.RequestHandler):
	def __init__(self):
		self.model = weather.WeatherWarning()
	def get(self):
		outputtype = self.request.get("output")
		warnings = memcache.get("warnings")
		if warnings is None:
			warnings = self.model.fetch()
			if warnings != None:
				memcache.add("warnings", warnings, 30 * 60)
		if warnings is None:
			return
		if outputtype == "json":
			self.response.headers['Content-Type'] = 'text/plain; charset=utf-8'
			jsonText = json.write({"result":warnings})
			self.response.out.write(jsonText)
		else:
			pl = dict(result=warnings)
			output = plistlib.writePlistToString(pl)
			self.response.headers['Content-Type'] = 'text/plist; charset=utf-8'
			self.response.out.write(output)
		add_record(self.request)

class OverviewController(webapp.RequestHandler):
	def __init__(self):
		self.overview = weather.WeatherOverview()
	def get(self):
		outputtype = self.request.get("output")
		text = memcache.get("overview_plain_201108122")
		if text is None:
			self.overview.fetch()
			text = self.overview.plain
		if text != None:
			memcache.add("overview_plain_201108122", text, 30 * 60)
		self.response.headers['Content-Type'] = 'text/plain; charset=utf-8'
		self.response.out.write(text)
		add_record(self.request)

class ForecastController(webapp.RequestHandler):
	def __init__(self):
		self.model = weather.WeatherForecast()
		self.key_prefix = "forecast_"
	def getAll(self):
		key = self.key_prefix + "all"
		allItems = memcache.get(key)
		if allItems is None:
			allItems = []
			for location in self.model.locations():
				id = location['id']
				key2 = self.key_prefix + str(id)
				result = memcache.get(key2)
				if result is None:
					result = self.model.fetchWithID(id)
					if result is None:
						return
				allItems.append(result)
				memcache.add(key2, result, 30 * 60)
			memcache.add(key, allItems, 30 * 60)
		outputtype = self.request.get("output")
		if outputtype == "json":
			self.response.headers['Content-Type'] = 'text/plain; charset=utf-8'
			jsonText = json.write({"result":allItems})
			callback = self.request.get("callback")
			if len(callback) > 0:
				self.response.out.write(callback + '(' + jsonText + ')')
			else:
				self.response.out.write(jsonText)
		else:
			pl = dict(result=allItems)
			output = plistlib.writePlistToString(pl)
			self.response.headers['Content-Type'] = 'text/plist; charset=utf-8'
			self.response.out.write(output)
		add_record(self.request)
	def get(self):
		location = self.request.get("location")
		outputtype = self.request.get("output")
		
		if location == "all":
			self.getAll()
			return
		
		if len(location) == 0:
			locations = self.model.locations()
			items = []
			for location in locations:
				locationName = location['location']
				plistURL = self.request.url + "?location=" + str(location['id'])
				jsonURL = self.request.url + "?location=" + str(location['id']) + "&output=json"
				item = {"locationName":locationName, "plistURL":plistURL, "jsonURL":jsonURL}
				items.append(item)
			if outputtype == "json":
				self.response.headers['Content-Type'] = 'text/plain; charset=utf-8'
				jsonText = json.write({"result":items})
				self.response.out.write(jsonText)
			else:
				pl = dict(result=items)
				output = plistlib.writePlistToString(pl)
				self.response.headers['Content-Type'] = 'text/xml; charset=utf-8'
				self.response.out.write(output)
			return
			
		key = self.key_prefix + str(location)
		result = memcache.get(key)
		if result is None:
			result = self.model.fetchWithID(location)
			if result is None:
				return
		else:
			memcache.add(key, result, 30 * 60)

		if outputtype == "json":
			self.response.headers['Content-Type'] = 'text/plain; charset=utf-8'
			jsonText = json.write({"result":result})
			self.response.out.write(jsonText)
		else:
			pl = dict(result=result)
			output = plistlib.writePlistToString(pl)
			self.response.headers['Content-Type'] = 'text/plist; charset=utf-8'
			self.response.out.write(output)
		add_record(self.request)

class WeekController(ForecastController):
	def __init__(self):
		self.model = weather.WeatherWeek()
		self.key_prefix = "week201108122_"

class WeekTravelController(ForecastController):
	def __init__(self):
		self.model = weather.WeatherWeekTravel()
		self.key_prefix = "weekTravel201108122_"

class ThreeDaySeaController(ForecastController):
	def __init__(self):
		self.model = weather.Weather3DaySea()
		self.key_prefix = "3sea201108122_"

class NearSeaController(ForecastController):
	def __init__(self):
		self.model = weather.WeatherNearSea()
		self.key_prefix = "nearsea201108122_"

class TideController(ForecastController):
	def __init__(self):
		self.model = weather.WeatherTide()
		self.key_prefix = "tide201108122_"

class OBSController(ForecastController):
	def __init__(self):
		self.model = weather.WeatherOBS()
		self.key_prefix = "obs201108122_"

class GlobalController(ForecastController):
	def __init__(self):
		self.model = weather.WeatherGlobal()
		self.key_prefix = "global201108122_"

class ImageHandler(webapp.RequestHandler):
	def __init__(self):
		self.imageURL = weather.WeatherImageURL
		self.key_prefix = "image_"
	def get(self):
		imageID = self.request.get("id")
		
		if len(imageID) == 0:
			self.response.headers["Content-Type"] = "text/html"
			self.response.out.write("<h1>Images:</h1>")
			for item in self.imageURL:
				line = "<p><img src=\"" + item['URL']  + "\" /></p>"
				self.response.out.write(line)
			return
		
		URL = None
		for item in self.imageURL:
			if str(imageID) == str(item['id']):
				URL = item["URL"]
				break
		if URL is None:
			self.error(404)
			return

		redirect = self.request.get("redirect")
		if redirect:
			self.redirect(URL)
			pass

		key = self.key_prefix + str(imageID)
		imageData = memcache.get(key)
		if imageData is None:
			url = urllib.urlopen(URL, proxies={})
			imageData = url.read()
			if imageData is None:
				self.error(404)
				return
		else:
			memcache.add(key, imageData, 30 * 60)

		self.response.headers["Content-Type"] = "image/jpg"
		self.response.out.write(imageData)
		add_record(self.request)

class RedirectController(webapp.RequestHandler):
	def get(self, args):
		self.redirect("/warning")
		pass

class MainHandler(webapp.RequestHandler):
	def get(self):
		path = os.path.join(os.path.dirname(__file__), 'html', 'main.html')
		self.response.out.write(template.render(path, {}))

def main():
	application = webapp.WSGIApplication(
		[
			('/', MainHandler),
			('/overview', OverviewController),
			('/forecast', ForecastController),
			('/week', WeekController),
			('/week_travel', WeekTravelController),
			('/3sea', ThreeDaySeaController),
			('/nearsea', NearSeaController),
			('/tide', TideController),
			('/image', ImageHandler),
			('/obs', OBSController),
			('/warning', WarningController),
			('/warning(.*)', RedirectController),
			('/global', GlobalController),
			],
 			debug=True)
 	# wsgiref.handlers.CGIHandler().run(application)
	run_wsgi_app(application)

if __name__ is '__main__':
	main()
