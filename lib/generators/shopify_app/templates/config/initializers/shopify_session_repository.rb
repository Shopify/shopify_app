# You should replace InMemorySessionStore with what you will be using
# in Production

# Interface to implement are find(id) and store(ShopifyAPI::Session)
ShopifySessionRepository.store = InMemorySessionStore
