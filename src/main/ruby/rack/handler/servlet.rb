#--
# Copyright (c) 2010-2012 Engine Yard, Inc.
# Copyright (c) 2007-2009 Sun Microsystems, Inc.
# This source code is available under the MIT license.
# See the file LICENSE.txt for details.
#++

require 'jruby/rack'
require 'jruby/rack/version'

module Rack
  module Handler
    class Servlet
      
      def initialize(rack_app)
        unless @rack_app = rack_app
          raise "rack application not found. Make sure the rackup file path is correct."
        end
      end

      def call(servlet_env)
        @env = create_env(servlet_env)

        async_block = nil
        catch_return = catch(:async) do
          response = @rack_app.call(@env) # [ -1, {}, async_block ]
          if ! response || ( response[0] >= 0 && response[0] != :async )
            return JRuby::Rack::Response.new(response)
          end
          async_block = response.last
        end
        async_block = catch_return if catch_return
        
        # if we get here it's an async request to be handled :
        async_context = @env['java.async_context'] = 
          servlet_env.startAsync(
            @env['java.servlet_request'], @env['java.servlet_response']
          )
          
        async_response = JRuby::Rack::AsyncResponse.new(async_context)
        
        @env['async.callback'] = Proc.new do |response|
          if response && ( response[0] == 0 || response[0] == :done )
            log "async_callback response[0] done !"
            throw :done # async_context.complete
          end
          log "async_callback handling response: #{response.inspect}"
          async_response.handle(response)
        end
        
        # start executing the block the async block returned :
        async_context.start do
          while async_response.responded?
            async_response.wait rescue java.lang.InterruptedException
          end
          catch(:done) { async_block.call }
          log "async_context.complete"
          async_context.complete
        end
      end

      def create_env(servlet_env)
        self.class.env.create(servlet_env).to_hash
      end
      
      # #deprecated please use #create_env instead
      def create_lazy_env(servlet_env)
        DefaultEnv.new(servlet_env).to_hash
      end
      
      @@env = nil
      
      def self.env
        @@env ||= DefaultEnv
      end
      
      def self.env=(klass)
        if klass && ! klass.is_a?(Module)
          # accepting a String or Symbol:
          unless (const_defined?(klass) rescue nil)
            klass = "#{klass.to_s.capitalize}Env" # :default => 'DefaultEnv'
          end
          klass = const_get(klass)
        end
        @@env = klass
      end
      
      autoload :DefaultEnv, "rack/handler/servlet/default_env"
      autoload :ServletEnv, "rack/handler/servlet/servlet_env"
      
      private
      
      def log(msg)
        puts msg
      end
      
    end
    # #deprecated backwards compatibility
    LazyEnv = Env = Servlet::DefaultEnv
  end
end
