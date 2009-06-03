require 'ostruct'
require 'digest/md5'

module ShopifyAPI
  # 
  #  The Shopify API authenticates each call via HTTP Authentication, using
  #    * the application's API key as the username, and
  #    * a hex digest of the application's shared secret and an 
  #      authentication token as the password.
  #  
  #  Generation & acquisition of the beforementioned looks like this (assuming the ):
  # 
  #    0. Developer (that's you) registers Application (and provides a
  #       callback url) and receives an API key and a shared secret
  # 
  #    1. User visits Application and are told they need to authenticate the
  #       application first for read/write permission to their data (needs to
  #       happen only once). User is asked for their shop url.
  # 
  #    2. Application redirects to Shopify : GET <user's shop url>/admin/api/auth?app=<API key>
  #       (See Session#create_permission_url)
  # 
  #    3. User logs-in to Shopify, approves application permission request
  # 
  #    4. Shopify redirects to the Application's callback url (provided during
  #       registration), including the shop's name, and an authentication token in the parameters:
  #         GET client.com/customers?shop=snake-oil.myshopify.com&t=a94a110d86d2452eb3e2af4cfb8a3828
  # 
  #    5. Authentication password computed using the shared secret and the
  #       authentication token (see Session#computed_password)
  # 
  #    6. Profit!
  #       (API calls can now authenticate through HTTP using the API key, and
  #       computed password)
  # 
  #  LoginController and ShopifyLoginProtection use the Session class to set ActiveResource::Base.site
  #  so that all API calls are authorized transparently and end up just looking like this:
  # 
  #    # get 3 products
  #    @products = ShopifyAPI::Product.find(:all, :params => {:limit => 3})
  #    
  #    # get latest 3 orders
  #    @orders = ShopifyAPI::Order.find(:all, :params => {:limit => 3, :order => "created_at DESC" })
  # 
  #  As an example of what your LoginController should look like, take a look
  #  at the following:
  # 
  #    class LoginController < ApplicationController
  #      def index
  #        # Ask user for their #{shop}.myshopify.com address
  #      end
  #    
  #      def authenticate
  #        redirect_to ShopifyAPI::Session.new(params[:shop]).create_permission_url
  #      end
  #    
  #      # Shopify redirects the logged-in user back to this action along with
  #      # the authorization token t.
  #      # 
  #      # This token is later combined with the developer's shared secret to form
  #      # the password used to call API methods.
  #      def finalize
  #        shopify_session = ShopifyAPI::Session.new(params[:shop], params[:t])
  #        if shopify_session.valid?
  #          session[:shopify] = shopify_session
  #          flash[:notice] = "Logged in to shopify store."
  #    
  #          return_address = session[:return_to] || '/home'
  #          session[:return_to] = nil
  #          redirect_to return_address
  #        else
  #          flash[:error] = "Could not log in to Shopify store."
  #          redirect_to :action => 'index'
  #        end
  #      end
  #    
  #      def logout
  #        session[:shopify] = nil
  #        flash[:notice] = "Successfully logged out."
  #    
  #        redirect_to :action => 'index'
  #      end
  #    end
  # 
  class Session
    cattr_accessor :api_key
    cattr_accessor :secret
    cattr_accessor :protocol 
    self.protocol = 'https'

    attr_accessor :url, :token, :name
    
    def self.setup(params)
      params.each { |k,value| send("#{k}=", value) }
    end

    def initialize(url, token = nil, params = nil)
      self.url, self.token = url, token

      if params && params[:signature]
        raise "Invalid Signature: Possible malicious login" unless valid_signature?(params)
      end

      self.class.prepare_url(self.url)
    end
    
    def shop
      Shop.current
    end
    
    def create_permission_url
      "http://#{url}/admin/api/auth?api_key=#{api_key}"
    end

    # Used by ActiveResource::Base to make all non-authentication API calls
    # 
    # (ActiveResource::Base.site set in ShopifyLoginProtection#shopify_session)
    def site
      "#{protocol}://#{api_key}:#{computed_password}@#{url}/admin"
    end

    def valid?
      [url, token].all?
    end

    private

    # The secret is computed by taking the shared_secret which we got when 
    # registring this third party application and concating the request_to it, 
    # and then calculating a MD5 hexdigest. 
    def computed_password
      Digest::MD5.hexdigest(secret + token.to_s)
    end
    
    def self.prepare_url(url)
      url.gsub!(/https?:\/\//, '')                            # remove http:// or https://
      url.concat(".myshopify.com") unless url.include?('.')   # extend url to myshopify.com if no host is given
    end
    
    def valid_signature?(params)
      signature = params[:signature]
      sorted_params = params.except(:signature, :action, :controller).collect{|k,v|"#{k}=#{v}"}.sort.join

      Digest::MD5.hexdigest(secret + sorted_params) == signature
    end
  end

  # Shop object. Use Shop.current to receive 
  # the shop. Since you can only ever reference your own
  # shop this model does not have a .find method.
  #
  class Shop
    def self.current
      ActiveResource::Base.find(:one, :from => "/admin/shop.xml")
    end
  end               

  # Custom collection
  #
  class CustomCollection < ActiveResource::Base
    def products
      Product.find(:all, :params => {:collection_id => self.id})
    end
    
    def add_product(product)
      Collect.create(:collection_id => self.id, :product_id => product.id)
    end
    
    def remove_product(product)
      collect = Collect.find(:first, :params => {:collection_id => self.id, :product_id => product.id})
      collect.destroy if collect
    end
  end                                                                 

  # For adding/removing products from custom collections
  class Collect < ActiveResource::Base
  end

  class ShippingAddress < ActiveResource::Base
  end

  class BillingAddress < ActiveResource::Base
  end         

  class LineItem < ActiveResource::Base 
  end       

  class ShippingLine < ActiveResource::Base
  end  

  class Order < ActiveResource::Base  

    def close; load_attributes_from_response(post(:close)); end

    def open; load_attributes_from_response(post(:open)); end

    def transactions
      Transaction.find(:all, :params => { :order_id => id })
    end
    
    def capture(amount = "")
      Transaction.create(:amount => amount, :kind => "capture", :order_id => id)
    end
  end
  
  class Product < ActiveResource::Base

    # Share all items of this store with the 
    # shopify marketplace
    def self.share; post :share;  end    
    def self.unshare; delete :share; end

    # compute the price range
    def price_range
      prices = variants.collect(&:price)
      format =  "%0.2f"
      if prices.min != prices.max
        "#{format % prices.min} - #{format % prices.max}"
      else
        format % prices.min
      end
    end
    
    def collections
      CustomCollection.find(:all, :params => {:product_id => self.id})
    end
    
    def add_to_collection(collection)
      collection.add_product(self)
    end
    
    def remove_from_collection(collection)
      collection.remove_product(self)
    end
  end
  
  class Variant < ActiveResource::Base
    self.prefix = "/admin/products/:product_id/"
  end
  
  class Image < ActiveResource::Base
    self.prefix = "/admin/products/:product_id/"
    
    # generate a method for each possible image variant
    [:pico, :icon, :thumb, :small, :medium, :large, :original].each do |m|
      reg_exp_match = "/\\1_#{m}.\\2"
      define_method(m) { src.gsub(/\/(.*)\.(\w{2,4})/, reg_exp_match) }
    end
    
    def attach_image(data, filename = nil)
      attributes[:attachment] = Base64.encode64(data)
      attributes[:filename] = filename unless filename.nil?
    end
  end

  class Transaction < ActiveResource::Base
    self.prefix = "/admin/orders/:order_id/"
  end
  
  class Fulfillment < ActiveResource::Base
    self.prefix = "/admin/orders/:order_id/"
  end

  class Country < ActiveResource::Base
  end

  class Page < ActiveResource::Base
  end
  
  class Blog < ActiveResource::Base
    def articles
      Article.find(:all, :params => { :blog_id => id })
    end
  end
  
  class Article < ActiveResource::Base
    self.prefix = "/admin/blogs/:blog_id/"
  end

  class Comment < ActiveResource::Base 
    def remove; load_attributes_from_response(post(:remove)); end
    def ham; load_attributes_from_response(post(:ham)); end
    def spam; load_attributes_from_response(post(:spam)); end
    def approve; load_attributes_from_response(post(:approve)); end        
  end
  
  class Province < ActiveResource::Base
    self.prefix = "/admin/countries/:country_id/"
  end
  
  class Redirect < ActiveResource::Base
  end
end