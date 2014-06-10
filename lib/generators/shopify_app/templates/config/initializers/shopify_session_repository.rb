# You should replace InMemorySessionStore with what you will be using
# in Production
#
# Interface to implement are self.retrieve(id) and self.store(ShopifyAPI::Session)
#
# Here is how you would add these functions to an ActiveRecord:
#
# class Shop < ActiveRecord::Base
#   def self.store(session)
#     shop = Shop.new(domain: session.url, token: session.token)
#     shop.save!
#     shop.id
#   end
#
#   def self.retrieve(id)
#     shop = Shop.find(id)
#     ShopifyAPI::Session.new(shop.domain, shop.token)
#   end
# end

ShopifySessionRepository.storage = InMemorySessionStore
