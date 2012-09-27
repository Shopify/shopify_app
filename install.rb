puts
puts "Shopify App Generator"
puts "---------------------"
puts
puts "To get started, first register your app as a Shopify Partner:"
puts
puts " * Go to http://www.shopify.com/partners and create or login to your Partner account."
puts
puts " * Jump over to the Apps tab and hit the 'Create a new app' button"
puts "   (Make sure to set the Application URL to http://localhost:3000/login during development)"
puts
puts " * Install the Shopify API gem:

           $ gem install shopify_api"
puts
puts " * Run 

           $ rails generate shopify_app your_app_api_key your_app_secret"
puts
puts " * Set up a test shop to install your app in (do this on the Partner site)"
puts
puts " * Run $ rails server"
puts
puts " * Visit http://localhost:3000 and use the test shop's URL to install this app"
puts