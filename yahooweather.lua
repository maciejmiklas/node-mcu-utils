-- https://query.yahooapis.com/v1/public/yql?q=select%20item.forecast%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22munic%2C%20de%22)%20and%20u%3D%27c%27%20limit%203&format=json
yaw = {
	url1 = "https://query.yahooapis.com/v1/public/yql?q=select%20item.forecast%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22",
	url2 = "c%2C%20",
	url3 = "%22)%20and%20u%3D%27c%27%20limit%203&format=json"	
}