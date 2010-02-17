puts
puts "Shopify App Generator"
puts "---------------------"
puts
puts "To get started, first register your app as a Shopify Partner:"
puts
puts " * Go to http://www.shopify.com/partners and create or login to your Partner account."
puts " * Jump over to the Apps tab and hit the 'Create a new app' button"
puts "   (Make sure to set the Return URL to http://localhost:3000/login/finalize during development)"
puts " * Install the Shopify API gem. Run gem install shopify_api"
puts " * Run ./script/generate shopify_app <api_key> <secret>"
puts " * Set up a test shop to install your app in (do this on the Partner site)"
puts " * Run ./script/server"
puts " * Visit http://localhost:3000 and use the test shop's URL to install this app"
puts